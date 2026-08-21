import 'dart:async';

import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_repository.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';

/// Le plan de synchronisation courant, tenu à disposition du cycle de pull
/// (ADR-015 F5/F9).
///
/// ## Pourquoi un porteur, et pas le coordinateur
///
/// Le plan n'est pas relu à chaque cycle. `pullSubset` part au montage de sept
/// écrans, et un aller-retour d'ouverture de la Facturation en lance trois d'un
/// coup : lire le plan par le réseau à chaque fois ferait une dizaine de
/// `GET /sync/plan` par minute en navigation normale — le plan n'ayant
/// délibérément pas d'ETag, ce sont autant de corps pleins. Il est donc résolu
/// une fois, mémorisé, et relu **sur signal**.
///
/// Le mémo, son verrou de simultanéité et son drapeau de péremption forment une
/// responsabilité à eux seuls, que le coordinateur n'a pas à porter — et c'est
/// la seule forme où « retente au cycle suivant » se teste sans simuler un
/// réseau.
///
/// ## Ce que ce porteur garantit
///
/// **Un seul appel en vol.** Trois cycles concurrents sur un mémo vide
/// déclencheraient trois lectures du plan ; ils partagent le même futur.
///
/// **Rien ne survit à une bascule de compte.** Le porteur vit aussi longtemps
/// que l'application, le plan appartient à un compte. Le repository refuse déjà
/// un plan dont le `subject` n'est pas le porteur de session — mais ce contrôle
/// a lieu au chargement, pas à l'usage. Sans [clear] au logout, le plan de A
/// gouvernerait ce que B tire, et sous F5 ce n'est plus un affichage : c'est le
/// périmètre de synchronisation.
///
/// **Un plan périmé se sait périmé.** Quand les permissions changent en séance,
/// le plan est marqué à relire ; si la relecture échoue, il **reste** marqué et
/// retente au cycle suivant. Sous F5, un plan périmé restreint le pull — il ne
/// se contente pas d'être en retard.
///
/// Et « échoue » ne veut pas dire « n'a rien reçu » : une réponse du serveur
/// qu'une nouvelle lecture démentirait — un refus, un uid pas encore posé —
/// laisse elle aussi le drapeau levé. Elle est reçue, elle n'est pas un
/// verdict.
class SyncPlanHolder {
  final SyncPlanRepository _repository;

  SyncPlanState? _memo;
  Future<SyncPlanState>? _inFlight;

  /// Le mémo doit être rafraîchi avant d'être servi.
  ///
  /// Vrai au départ (rien n'a jamais été lu) et remis à vrai par
  /// [markStale] — que le changement de permissions déclenche.
  bool _stale = true;

  /// Incrémentée par [markStale] et [clear].
  ///
  /// Une lecture dure : entre son départ et son retour, les droits peuvent
  /// changer ou la session se fermer. Sans ce jeton, la lecture qui revient
  /// écrase la décision prise pendant son vol — elle marquerait frais un plan
  /// obtenu AVANT l'élargissement des droits, ou ressusciterait le plan d'un
  /// compte déconnecté. Les deux ont été trouvés en revue, et le second est le
  /// plus grave : il ne se manifeste que si le compte suivant a exactement le
  /// même ensemble de droits — auquel cas rien ne notifie, et le plan de A
  /// gouverne le pull de B.
  int _generation = 0;

  void Function()? _unsubscribePermissions;

  SyncPlanHolder({
    required SyncPlanRepository repository,
    CurrentPermissions? permissions,
  }) : _repository = repository {
    // Le contrat annonce que le plan est relu « chaque fois qu'un refresh livre
    // un ensemble de permissions différent de celui en mémoire ». Le holder de
    // permissions ne notifie que sur un changement RÉEL, comparé en ensembles :
    // brancher ici suffit, et couvre du même coup les cinq autres chemins qui
    // alimentent cet ensemble — dont la bascule de compte.
    //
    // Deux réactions, pas une. Un ensemble qui CHANGE veut dire « ce plan est
    // peut-être périmé » : on le relit. Un ensemble qui devient INCONNU veut
    // dire « il n'y a plus de session » — logout, wipe, révocation — et là il
    // n'y a rien à relire : il faut oublier. Marquer périmé suffirait presque,
    // puisqu'un mémo périmé n'est jamais servi ; mais « presque » n'est pas la
    // bonne garantie quand ce qui est en jeu est le périmètre de synchronisation
    // du compte suivant sur une tablette partagée.
    _unsubscribePermissions = permissions?.addChangeListener(() {
      if (permissions.permissions == null) {
        clear();
      } else {
        markStale();
      }
    });
  }

  /// Le plan à appliquer à ce cycle.
  ///
  /// Sert le mémo tant qu'il est frais. Sinon relit — et **ne marque frais que
  /// ce qu'une relecture rendrait à l'identique** : un repli sur le cache laisse
  /// le drapeau levé, et un état transitoire obtenu du serveur (refus, uid pas
  /// encore posé, plan d'un autre sujet) aussi. Les deux retentent au cycle
  /// suivant.
  ///
  /// Ne lève jamais : tout échec devient un plan inconnu, c'est-à-dire le repli
  /// sur le registre en dur. Une lecture qui remonterait une exception couperait
  /// la synchronisation sans recours.
  ///
  /// ⚠️ **Un arrivant se coalesce sur la lecture en vol sans réexaminer la
  /// fraîcheur, et c'est délibéré.** Si [markStale] survient pendant le vol, le
  /// nouvel appelant reçoit un plan déjà connu comme périmé — sa question date
  /// pourtant d'APRÈS le changement, donc l'argument qui justifie [_commit] ne
  /// vaut pas pour lui. Ce qu'il perd est un cycle : le drapeau reste levé, le
  /// cycle suivant relit. Ce qu'on évite est un aller-retour réseau par
  /// changement de droits — et un refresh de jeton peut en produire plusieurs
  /// d'affilée.
  ///
  /// C'est aussi pourquoi [markStale] n'abandonne PAS la lecture en vol alors
  /// que [clear] le fait : un plan un cycle en retard reste le plan du bon
  /// compte, tandis qu'un plan servi après une bascule de compte serait celui de
  /// quelqu'un d'autre. L'asymétrie est le compromis, pas un oubli.
  Future<SyncPlanState> current() {
    final memo = _memo;
    if (!_stale && memo != null) return Future<SyncPlanState>.value(memo);
    final existing = _inFlight;
    if (existing != null) return existing;
    late final Future<SyncPlanState> started;
    started = _resolve().whenComplete(() {
      // Identité vérifiée : [clear] a pu abandonner cette lecture et en laisser
      // partir une autre. Effacer sans regarder annulerait la nouvelle.
      if (identical(_inFlight, started)) _inFlight = null;
    });
    _inFlight = started;
    return started;
  }

  Future<SyncPlanState> _resolve() async {
    final generation = _generation;
    try {
      final fresh = await _repository.refreshFromNetwork();
      if (fresh != null) {
        // ⚠️ Un état reçu n'est pas encore un verdict. `null` dit seulement que
        // la jambe réseau n'a pas abouti ; un état dit que le serveur a répondu,
        // et le refus (401/403) comme l'uid pas encore posé en produisent un.
        // Les mémoriser FRAIS éteignait le drapeau pour toute la session — plus
        // rien ne relit le plan hors d'un vrai changement de droits — et un seul
        // 403 transitoire suffisait à rendre la main à `requiredPermissions`
        // jusqu'au prochain login, derrière une pastille verte.
        //
        // Seul un verdict est mémorisable comme frais : ce que relire rendrait à
        // l'identique. Le retenter ajouterait un aller-retour par montage
        // d'écran sur un parc entier — c'est pourquoi la route absente en est
        // un.
        _commit(fresh, generation, fresh: _isVerdict(fresh));
        return fresh;
      }
      // La jambe réseau n'a pas abouti. Ce que la tablette a déjà vaut mieux
      // que rien — mais le drapeau RESTE levé : ce plan n'est pas frais, et le
      // prochain cycle doit réessayer.
      final cached = await _repository.loadCached();
      _commit(cached, generation, fresh: false);
      return cached;
    } catch (_) {
      // Le repository ne lève pas (contrat) ; garde-fou par prudence. Un plan
      // inconnu est le repli sûr : le registre en dur reprend la main.
      const fallback = SyncPlanState.unknown(SyncPlanUnknownCause.absent);
      _commit(fallback, generation, fresh: false);
      return fallback;
    }
  }

  /// Cet état peut-il être tenu pour **définitif**, c'est-à-dire mémorisé sans
  /// qu'un cycle ultérieur ait à le relire ?
  ///
  /// Un plan connu ou positivement vide, oui : le serveur a dit ce qu'il avait à
  /// dire, et `markStale()` le rappellera quand les droits bougeront. Un plan
  /// inconnu, seulement si sa cause est un verdict — et cette liste-là n'est pas
  /// écrite ici : elle vit sur [SyncPlanUnknownCause.isVerdict], à côté des
  /// causes qu'elle trie, pour qu'une huitième cause pose la question au lieu de
  /// tomber dans un `else` de porteur.
  ///
  /// Le `switch` est exhaustif sur les trois états, sans `_` : un quatrième doit
  /// casser la compilation plutôt que de tomber du côté « définitif ».
  static bool _isVerdict(SyncPlanState state) => switch (state) {
    SyncPlanKnown() => true,
    SyncPlanEmpty() => true,
    SyncPlanUnknown(:final cause) => cause.isVerdict,
  };

  /// Enregistre le résultat d'une lecture — **sauf si le monde a changé pendant
  /// son vol**.
  ///
  /// L'appelant reçoit tout de même ce qu'il a demandé : sa question datait
  /// d'avant le changement, et son cycle appartient à cet avant. Ce qu'on refuse
  /// est de le mémoriser pour les suivants.
  void _commit(SyncPlanState state, int generation, {required bool fresh}) {
    if (generation != _generation) return;
    _memo = state;
    if (fresh) _stale = false;
  }

  /// Le plan doit être relu au prochain cycle.
  void markStale() {
    _stale = true;
    _generation++;
  }

  /// Oublie tout — logout, wipe, bascule de compte.
  ///
  /// Remet à l'état initial plutôt que de marquer périmé : entre le wipe et la
  /// première relecture, une copie survivante gouvernerait le pull du compte
  /// suivant.
  ///
  /// Abandonne aussi la lecture en vol : elle appartient au compte qui part, et
  /// un arrivant qui s'y coalescerait recevrait le plan de quelqu'un d'autre.
  void clear() {
    _memo = null;
    _stale = true;
    _generation++;
    _inFlight = null;
  }

  /// Le mémo courant sans déclencher de lecture (diagnostic / tests).
  SyncPlanState? get memo => _memo;

  bool get isStale => _stale;

  void dispose() {
    _unsubscribePermissions?.call();
    _unsubscribePermissions = null;
  }
}

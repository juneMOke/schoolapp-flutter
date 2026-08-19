import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Corps d'une modale dont l'en-tête et le pied restent **ancrés** tant que la
/// hauteur offerte le permet, et rejoignent un **défilement unique** en dessous.
///
/// ## Le problème qu'il ferme
///
/// `Dialog` ajoute les `viewInsets` du clavier à son `insetPadding` : la boîte
/// offerte à son contenu rétrécit d'autant. Sur un téléphone en paysage il n'en
/// reste qu'une douzaine de dp — quand l'en-tête, la bande de total et le
/// bouton d'action, eux, en réclament plus de deux cents. La disposition
/// « en-tête figé · corps défilant · pied figé » n'a alors plus aucun moyen de
/// tenir : le corps a beau se réduire à zéro, les parties figées débordent, et
/// `RenderFlex` le signale (mesuré à 167 dp sur 731×411, 218 dp sur 640×360).
///
/// Aucune mise en page ne fait tenir 233 dp dans 12. La seule issue correcte
/// est de rendre l'ensemble défilable — mais uniquement dans ce cas, car sur un
/// écran normal l'ancrage du total et du bouton d'encaissement a de la valeur.
///
/// ## Pourquoi une identité stable
///
/// La bascule entre les deux dispositions **déplace** l'en-tête, le corps et le
/// pied ; elle ne doit pas les recréer. Sans clé, la réconciliation apparie les
/// enfants par position : le sous-arbre change de rang, il est démonté, et
/// chaque champ de saisie qui s'était fabriqué son propre `FocusNode` le
/// détruit avec lui. Le focus meurt, le clavier se referme, la hauteur revient,
/// la bascule repart en sens inverse — le champ devient intapable. C'est très
/// exactement la panne payée sur la recherche de parent (défaut H-1) ; les
/// [GlobalKey] ci-dessous existent pour qu'elle ne soit pas repayée ailleurs.
class EteeloDialogBody extends StatefulWidget {
  /// Bandeau de tête (titre, croix de fermeture…).
  final Widget header;

  /// Contenu principal — c'est lui qui défile quand la disposition est ancrée.
  ///
  /// ⚠️ Il ne doit **pas** défiler pour son compte : le socle lui fournit son
  /// défilement dans les deux dispositions. Une liste se pose donc ici en
  /// `shrinkWrap: true` **et** `physics: NeverScrollableScrollPhysics()`.
  ///
  /// Un drapeau « ce corps défile déjà » a existé ici, et il ne pouvait pas
  /// tenir : une liste laissée maîtresse de son défilement gagne l'arène des
  /// gestes en tant que `Scrollable` le plus intérieur alors qu'elle n'a plus
  /// rien à faire défiler (hauteur libre ⇒ `maxScrollExtent` nul). Le doigt de
  /// l'utilisateur ne déplaçait alors RIEN — mesuré à 0 px sur la liste de
  /// commentaires en paysage clavier ouvert, quand cette liste couvre presque
  /// toute la surface et que le champ de saisie est justement ce qu'il faut
  /// atteindre.
  ///
  /// Et on ne peut pas la museler d'ici : `ScrollView` fige son `physics` dans
  /// son **constructeur** (toute liste verticale sans contrôleur reçoit
  /// `AlwaysScrollableScrollPhysics`), hors de portée d'un `ScrollConfiguration`
  /// ou d'un `PrimaryScrollController.none`, qui n'agissent qu'au build. C'est
  /// donc à l'appelant de rendre sa liste inerte.
  final Widget body;

  /// Marge appliquée au [body] dans **les deux** dispositions.
  final EdgeInsetsGeometry bodyPadding;

  /// Bandeaux de pied (séparateur, total, bouton d'action). Rendus dans l'ordre,
  /// ancrés en bas tant que la place suffit.
  final List<Widget> footer;

  /// Ce qui sépare l'en-tête du corps (filet, liseré…).
  final List<Widget> headerDividers;

  /// Occupation de la hauteur en disposition **ancrée** :
  /// - [MainAxisSize.min] (défaut) : la modale reste compacte si le contenu est
  ///   court — c'est ce qu'attendent les modales à hauteur libre.
  /// - [MainAxisSize.max] : la modale occupe toute la hauteur offerte.
  ///
  /// Sans effet en disposition défilante, où la hauteur n'est plus bornée et où
  /// [MainAxisSize.max] serait de toute façon une erreur de layout.
  final MainAxisSize pinnedMainAxisSize;

  /// Hauteur offerte en dessous de laquelle **tout** rejoint le défilement.
  ///
  /// À régler au-dessus de la hauteur incompressible réelle de l'en-tête et du
  /// pied : c'est elle qui déborderait. Une modale dont le pied s'épaissit doit
  /// relever ce seuil — et le test clavier de la modale le prouve.
  final double minPinnedHeight;

  const EteeloDialogBody({
    super.key,
    required this.header,
    required this.body,
    required this.footer,
    this.headerDividers = const [],
    this.bodyPadding = EdgeInsets.zero,
    this.minPinnedHeight = 360,
    this.pinnedMainAxisSize = MainAxisSize.min,
  });

  @override
  State<EteeloDialogBody> createState() => _EteeloDialogBodyState();
}

class _EteeloDialogBodyState extends State<EteeloDialogBody> {
  // Une clé par zone, créée une seule fois pour la vie de l'état : c'est elle
  // qui fait de la bascule un déplacement (l'élément est reparenté, son `State`
  // et ses `FocusNode` survivent) au lieu d'une destruction. Les deux
  // dispositions s'excluent, donc jamais deux porteurs d'une même clé.
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _bodyKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();

  /// Dernière hauteur offerte, pour reconnaître le rétrécissement dû au
  /// clavier.
  double? _lastMaxHeight;

  /// Ramène le champ qui a le focus dans la fenêtre visible quand la hauteur
  /// offerte diminue.
  ///
  /// Le défilement automatique de Flutter se joue au moment du focus — donc
  /// AVANT que le clavier ne soit monté, sur une géométrie qui n'existe déjà
  /// plus. Ensuite, plus rien ne bouge : la modale rétrécit sous le champ,
  /// qui sort de la fenêtre sans que le focus soit perdu. L'utilisateur voit
  /// le clavier recouvrir la modale et tape à l'aveugle (mesuré sur téléphone
  /// en paysage : modale confinée à 24..148 dp, champ focalisé à 232 dp).
  void _keepFocusedFieldVisible(double maxHeight) {
    final previous = _lastMaxHeight;
    _lastMaxHeight = maxHeight;
    if (previous == null || maxHeight >= previous) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused == null || !focused.mounted) return;
      // Un focus vivant AILLEURS (une autre modale, la page dessous) ne doit
      // pas faire défiler celle-ci.
      if (focused.findAncestorStateOfType<_EteeloDialogBodyState>() != this) {
        return;
      }
      Scrollable.ensureVisible(
        focused,
        alignment: 0.5,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final header = KeyedSubtree(key: _headerKey, child: widget.header);
    final body = KeyedSubtree(
      key: _bodyKey,
      child: Padding(padding: widget.bodyPadding, child: widget.body),
    );
    final footer = KeyedSubtree(
      key: _footerKey,
      child: Column(mainAxisSize: MainAxisSize.min, children: widget.footer),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // `constraints.maxHeight` est la hauteur RÉELLEMENT offerte : `Dialog`
        // en a déjà retranché le clavier. Ne pas la recalculer depuis
        // `MediaQuery` — à l'intérieur d'un `Dialog`, les `viewInsets` sont
        // remis à zéro (`MediaQuery.removeViewInsets`), donc la hauteur d'écran
        // qu'on y lit ignore le clavier.
        final ancre =
            constraints.hasBoundedHeight &&
            constraints.maxHeight >= widget.minPinnedHeight;

        if (constraints.hasBoundedHeight) {
          _keepFocusedFieldVisible(constraints.maxHeight);
        }

        if (!ancre) {
          // Hauteur non bornée ou trop courte : un défilement unique porte
          // tout. `Flexible` serait de toute façon interdit sans borne.
          //
          // Un `body` qui défile pour son compte doit rendre les armes ici :
          // resté actif, il gagne l'arène des gestes en tant que `Scrollable`
          // le plus intérieur, alors qu'il n'a plus rien à faire défiler (sa
          // hauteur est libre, donc son `maxScrollExtent` est nul). Le doigt de
          // l'utilisateur ne déplaçait alors RIEN — mesuré à 0 px sur la liste
          // de commentaires en paysage clavier ouvert, quand cette liste occupe
          // presque toute la surface visible et que le champ de saisie et le
          // bouton de fermeture sont justement ce qu'il faut atteindre.
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, ...widget.headerDividers, body, footer],
            ),
          );
        }

        return Column(
          mainAxisSize: widget.pinnedMainAxisSize,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            ...widget.headerDividers,
            Flexible(child: SingleChildScrollView(child: body)),
            footer,
          ],
        );
      },
    );
  }
}

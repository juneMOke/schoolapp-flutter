import 'package:school_app_flutter/features/finance/offline/data/sync/finance_ledger_refresher.dart';

/// Attente **bornée** du grand-livre devant l'encaissement — la seule que le
/// plan ait jamais demandée (`FACTURATION_OFFLINE_PLAN.md` §13 : « avant
/// encaissement si réseau »).
///
/// Les lectures, elles, ne l'attendent plus : elles servent le local et relisent
/// sur `FinanceLedgerRefresher.revalidated`. Ici, non — le « reste » composé qui
/// s'affiche dans la modale **borne la saisie** et décide s'il faut encaisser.
/// Sous-estimé parce qu'un versement du poste voisin n'est pas encore descendu,
/// il fait **réencaisser**. C'est le sens de panne asymétrique déjà décrit dans
/// `SyncFinancePullsUseCase`.
///
/// Deux bornes, et il faut les deux :
///  - [defaultMaxAge] — on ne rejoue pas un cycle qui vient d'aboutir. Ouvrir la
///    fiche lance déjà une revalidation ; taper « Encaisser » dans la foulée ne
///    doit pas repayer l'aller-retour. Une rafale d'encaissements ne paie donc
///    qu'un seul cycle.
///  - [defaultDeadline] — plafond de l'attente VISIBLE. Au-delà, la modale
///    s'ouvre sur le local : le cycle n'est pas annulé, il poursuit en fond. On
///    ne remplace pas un blocage de 22 s par un blocage indéfini.
class RefreshLedgerBeforeCollectionUseCase {
  /// Fraîcheur exigée avant d'ouvrir la modale d'encaissement.
  static const Duration defaultMaxAge = Duration(seconds: 15);

  /// Plafond de l'attente visible au tap « Encaisser ».
  static const Duration defaultDeadline = Duration(seconds: 4);

  final FinanceLedgerRefresher _refresher;
  final Duration _maxAge;
  final Duration _deadline;

  const RefreshLedgerBeforeCollectionUseCase(
    this._refresher, {
    Duration maxAge = defaultMaxAge,
    Duration deadline = defaultDeadline,
  }) : _maxAge = maxAge,
       _deadline = deadline;

  Future<void> call({
    required String studentId,
    required String academicYearId,
  }) => _refresher.refresh(
    studentId,
    academicYearId,
    maxAge: _maxAge,
    deadline: _deadline,
  );
}

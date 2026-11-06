import 'package:school_app_flutter/core/offline/id_change_bus.dart';

/// Annonce les inscriptions dont la correction de niveau vient de changer sur
/// ce poste : geste local, accusé, refus. La fiche d'inscription et la garde du
/// guichet s'y abonnent.
class LevelCorrectionChangeBus extends IdChangeBus {}

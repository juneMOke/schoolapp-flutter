import 'package:school_app_flutter/core/offline/id_change_bus.dart';

/// Annonce les inscriptions dont la désactivation vient de changer sur ce
/// poste : geste local, accusé, refus, descente du flux. Les quatre écrans qui
/// montrent l'état (liste, fiche, classes, tableau de bord) s'y abonnent.
class EnrollmentSuspensionChangeBus extends IdChangeBus {}

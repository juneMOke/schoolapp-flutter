import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_printer_settings.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';

/// Combien d'exemplaires sortent d'office : le réglage de **cette tablette**
/// (Finances ▸ Imprimante de tickets), sinon celui de l'école, borné, sinon
/// [TicketCopies.fallback].
///
/// **Ne rend jamais d'échec.** Un défaut illisible ne doit pas empêcher un
/// ticket de sortir : identité indisponible, autre école sur la tablette,
/// réglage absent ou lecture en panne — le caissier part d'un exemplaire, comme
/// avant l'existence du réglage, et ajuste au compteur.
///
/// Borné ici et pas seulement au serveur : la valeur descend d'un cache local
/// que rien n'empêche d'être plus vieux que les règles actuelles.
class ResolveTicketCopiesUseCase {
  final SchoolRepository _schools;
  final TicketPrinterSettingsStore? _device;

  const ResolveTicketCopiesUseCase(
    this._schools, {
    TicketPrinterSettingsStore? device,
  }) : _device = device;

  Future<int> call() async {
    final local = (await _device?.read())?.copies;
    if (local != null) return TicketCopies.clamp(local);
    final loaded = await _schools.loadCurrentSchool();
    final configured = loaded.fold(
      (_) => null,
      (school) => school?.ticketCopies,
    );
    return configured == null
        ? TicketCopies.fallback
        : TicketCopies.clamp(configured);
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';

/// Une écriture vient d'entrer dans la file : la pastille de synchronisation
/// pousse tout de suite, comme après un geste des Dépenses, au lieu
/// d'attendre le battement.
void notifyPayrollLocalWrite(BuildContext context) {
  if (!context.mounted) return;
  try {
    context.read<SyncStatusCubit>().notifyLocalWrite();
  } on ProviderNotFoundException {
    // Aucune pastille montée : le battement poussera.
  }
}

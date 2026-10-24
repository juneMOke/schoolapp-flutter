import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/profiles/hr_presence_profiles_cubit.dart';

/// La portée de la fiche individuelle tenue dans l'adresse : `?vue=an`, ou
/// `?mois=2026-09` pour un mois passé. Le mois en cours, le défaut, laisse
/// l'adresse nue ; recherche, catégorie et profil n'y vont pas.
class HrFicheLocation extends StatelessWidget {
  static const viewParam = 'vue';
  static const yearValue = 'an';
  static const monthParam = 'mois';

  final HrPresenceProfilesState state;
  final HrPresenceProfilesCubit cubit;
  final Widget child;

  const HrFicheLocation({
    super.key,
    required this.state,
    required this.cubit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => LocationParamsSync(
    current: {
      viewParam: state.yearly ? yearValue : null,
      monthParam: state.yearly || state.isCurrentMonth ? null : state.month,
    },
    onLocation: (values) => unawaited(
      cubit.applyLocation(
        yearly: values[viewParam] == yearValue,
        month: values[monthParam],
      ),
    ),
    child: child,
  );
}

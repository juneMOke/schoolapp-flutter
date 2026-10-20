import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/web/app_update/app_update_banner.dart';
import 'package:school_app_flutter/core/web/app_update/app_update_cubit.dart';

/// Sur le web, surveille les déploiements et propose de recharger
/// ([AppUpdateBanner]). Transparent ailleurs : une application installée se
/// met à jour par son magasin ou son installeur.
class AppUpdateScope extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const AppUpdateScope({super.key, required this.child, this.enabled = kIsWeb});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return BlocProvider<AppUpdateCubit>(
      create: (_) {
        final cubit = GetIt.instance<AppUpdateCubit>();
        unawaited(cubit.start());
        return cubit;
      },
      child: AppUpdateBanner(child: child),
    );
  }
}

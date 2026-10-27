import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/network_status_cubit.dart';

/// Un geste qui n'existe qu'en ligne : [builder] reçoit l'état du réseau, en
/// direct, pour se désactiver avec son message plutôt qu'échouer au toucher.
/// Sans service de connectivité monté (tests), il se croit en ligne — l'appel
/// garde de toute façon son traitement d'échec.
class PayrollOnlineOnly extends StatelessWidget {
  final Widget Function(BuildContext context, bool online) builder;

  const PayrollOnlineOnly({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<NetworkStatusCubit>()) {
      return builder(context, true);
    }
    return BlocProvider<NetworkStatusCubit>(
      create: (_) => GetIt.instance<NetworkStatusCubit>()..start(),
      child: BlocBuilder<NetworkStatusCubit, bool>(
        builder: (context, online) => builder(context, online),
      ),
    );
  }
}

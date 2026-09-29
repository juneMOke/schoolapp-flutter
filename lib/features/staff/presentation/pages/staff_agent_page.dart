import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/geo/address_geo_catalog.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_member_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_view.dart';

/// La page d'un agent, plein écran par-dessus la liste : créer, consulter,
/// modifier — une seule structure en quatre étapes.
///
/// Poussée par le `Navigator` et non par le routeur : la liste reste montée
/// dessous, filtres, recherche et affichage intacts au retour.
class StaffAgentPage extends StatelessWidget {
  final StaffMember? member;
  final StaffContractKind? kind;
  final List<StaffMember> others;
  final String today;

  /// Mots d'une recherche restée vide, pour préremplir une création.
  final String prefill;

  const StaffAgentPage({
    super.key,
    required this.others,
    required this.today,
    this.member,
    this.kind,
    this.prefill = '',
  });

  /// Ouvre la page ; se termine quand elle se referme.
  static Future<void> open(
    BuildContext context, {
    required List<StaffMember> others,
    required String today,
    StaffMember? member,
    StaffContractKind? kind,
    String prefill = '',
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => StaffAgentPage(
        member: member,
        kind: kind,
        others: others,
        today: today,
        prefill: prefill,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final existing = member;
    return MultiBlocProvider(
      providers: [
        BlocProvider<StaffAgentCubit>(
          create: (_) => StaffAgentCubit(
            save: getIt<SaveStaffMemberUseCase>(),
            load: getIt<LoadStaffMemberUseCase>(),
            others: others,
            today: today,
            member: existing,
            draft: existing == null
                ? StaffMemberDraft.fromSearch(
                    getIt<IdGenerator>().newId(),
                    prefill,
                    city: AddressGeoCatalog.defaultCity,
                  )
                : StaffMemberDraft.of(existing),
          ),
        ),
        BlocProvider<StaffContractsCubit>(
          create: (_) {
            final cubit = getIt<StaffContractsCubit>();
            if (existing != null) unawaited(cubit.load(existing.id));
            return cubit;
          },
        ),
      ],
      child: StaffAgentView(kind: kind, today: today),
    );
  }
}

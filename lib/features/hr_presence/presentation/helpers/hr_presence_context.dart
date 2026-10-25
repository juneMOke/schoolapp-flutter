import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Ce que les écrans de RH · Présences lisent du contexte de l'app.
abstract final class HrPresenceContext {
  /// L'ouverture de l'année scolaire, si le contexte la connaît déjà ;
  /// `null` sans contexte (tests, écran ouvert avant sa lecture).
  static DateTime? yearStart(BuildContext context) {
    try {
      return context
          .read<AcademicYearContextBloc>()
          .state
          .context
          ?.academicYear
          .startDate;
    } on Object {
      return null;
    }
  }
}

/// L'adresse d'une page d'agent poussée par-dessus un écran du module :
/// ses clés sont **les siennes** — l'écran du dessous, rebâti sur la même
/// adresse après F5, ne doit pas les lire comme ses propres filtres.
abstract final class HrAgentAddress {
  static const monthParam = 'mois-agent';
  static const viewParam = 'vue-agent';
  static const yearValue = 'an';

  /// La flèche d'une page d'agent : dépiler, ou rejoindre [subMenuId] dans
  /// la coquille — puis retirer de l'adresse les clés de l'agent, que
  /// go_router garde sur l'écran du dessous après un F5.
  static void leave(BuildContext context, {required String subMenuId}) {
    final router = GoRouter.of(context);
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        AppRoutesNames.home,
        queryParameters: {'subMenuId': subMenuId},
      );
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => LocationQuery.write(router, {monthParam: null, viewParam: null}),
    );
  }
}

/// Appelle [onClosed] quand la page disparaît, quelle que soit la sortie —
/// la flèche, Précédent du navigateur, une adresse tapée.
class HrClosingNotifier extends StatefulWidget {
  final VoidCallback? onClosed;
  final Widget child;

  const HrClosingNotifier({
    super.key,
    required this.onClosed,
    required this.child,
  });

  @override
  State<HrClosingNotifier> createState() => _HrClosingNotifierState();
}

class _HrClosingNotifierState extends State<HrClosingNotifier> {
  @override
  void dispose() {
    widget.onClosed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

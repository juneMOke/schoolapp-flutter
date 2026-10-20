import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/web/app_update/app_update_banner.dart';
import 'package:school_app_flutter/core/web/app_update/app_update_cubit.dart';
import 'package:school_app_flutter/core/web/app_update/deployed_build_source.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _NoSource implements DeployedBuildSource {
  @override
  Future<String?> read() async => null;
}

class _ShownCubit extends AppUpdateCubit {
  _ShownCubit() : super(source: _NoSource(), ticks: const Stream.empty());

  void show() => emit(true);
}

void main() {
  testWidgets('le bandeau n\'apparaît qu\'après un nouveau déploiement, et '
      'recharge à la demande', (tester) async {
    final cubit = _ShownCubit();
    addTearDown(cubit.close);
    var reloads = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: BlocProvider<AppUpdateCubit>.value(
          value: cubit,
          child: AppUpdateBanner(
            onReload: () => reloads++,
            child: const Text('application'),
          ),
        ),
      ),
    );
    expect(find.text('Recharger'), findsNothing);
    cubit.show();
    await tester.pump();
    expect(
      find.text('Une nouvelle version de l\'application est disponible.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Recharger'));
    expect(reloads, 1);
    expect(find.text('application'), findsOneWidget);
  });
}

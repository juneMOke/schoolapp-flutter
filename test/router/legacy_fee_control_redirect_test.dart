import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/router/legacy_fee_control_redirect.dart';

/// L'ancienne adresse du contrôle des frais (`fee`, `classroom`, `level`,
/// `cycle`, cf. main) renvoie au sous-menu de la coquille dans le vocabulaire
/// v2 (`frais`, `classe`) : un favori d'avant la v2 rouvre la même question.
void main() {
  final shell = AppRoutesNames.homeSubMenuPath(
    MenuConstants.recouvrementControlId,
  );

  test('fee → frais, classroom → classe ; level et cycle tombent', () {
    final target = Uri.parse(
      legacyFeeControlRedirect(const {
        'cycle': 'g1',
        'level': 'lvl-1',
        'classroom': 'c-a',
        'fee': 'TUITION',
      }),
    );

    expect(target.path, shell);
    expect(target.queryParameters, {'frais': 'TUITION', 'classe': 'c-a'});
    final intent = FeeControlIntent.fromRoute(null, target.queryParameters);
    expect(intent?.feeCodes, ['TUITION']);
    expect(intent?.classroomId, 'c-a');
  });

  test('sans classe (ligne de niveau) : seuls les frais passent', () {
    final target = Uri.parse(
      legacyFeeControlRedirect(const {
        'cycle': 'g1',
        'level': 'lvl-1',
        'fee': 'TUITION',
      }),
    );

    expect(target.queryParameters, {'frais': 'TUITION'});
  });

  test('une adresse déjà v2 passe telle quelle', () {
    final target = Uri.parse(
      legacyFeeControlRedirect(const {
        'frais': 'TUITION,TRANSPORT',
        'classe': 'c-a',
        'situation': 'rien',
      }),
    );

    expect(target.queryParameters, {
      'frais': 'TUITION,TRANSPORT',
      'classe': 'c-a',
      'situation': 'rien',
    });
  });

  test('sans paramètre : le sous-menu nu', () {
    expect(legacyFeeControlRedirect(const {}), shell);
  });

  testWidgets('la route de l\'ancienne adresse redirige, question traduite', (
    tester,
  ) async {
    Uri? landed;
    final router = GoRouter(
      initialLocation:
          '${AppRoutesNames.recouvrementControl}'
          '?cycle=g1&level=lvl-1&classroom=c-a&fee=TUITION',
      routes: [
        GoRoute(
          path: AppRoutesNames.recouvrementControl,
          redirect: (context, state) =>
              legacyFeeControlRedirect(state.uri.queryParameters),
        ),
        GoRoute(
          path: shell,
          builder: (_, state) {
            landed = state.uri;
            return const SizedBox();
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(landed?.path, shell);
    expect(landed?.queryParameters, {'frais': 'TUITION', 'classe': 'c-a'});
  });
}

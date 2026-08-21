import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockForgotBloc extends MockBloc<ForgotPasswordEvent, ForgotPasswordState>
    implements ForgotPasswordBloc {}

/// La coquille d'auth (connexion + réinitialisation) débordait dès que le
/// clavier montait : 41 dp, et 79 quand le bandeau d'erreur s'affichait.
///
/// Le mécanisme mérite d'être retenu, car il ne saute pas aux yeux. Le palier
/// empilé mesurait le formulaire par sa hauteur INTRINSÈQUE, et cette mesure
/// était fausse : `RenderConstrainedBox.computeMaxIntrinsicHeight` transmet à
/// son enfant la largeur reçue du parent **sans lui appliquer son propre
/// `maxWidth`**. Le formulaire était donc mesuré sur toute la largeur du
/// viewport — où ses textes ne reviennent pas à la ligne — et ressortait trop
/// court. La hauteur retenue retombait alors sur le plancher (la hauteur
/// offerte, que le clavier venait de raboter) et l'`Expanded` imposait cette
/// hauteur trop courte au formulaire.
///
/// Le bandeau d'erreur en donnait la preuve : il ajoutait ses ~38 dp au
/// débordement **sans** agrandir la boîte, puisqu'un plancher ne dépend pas du
/// contenu. D'où les deux variantes de chaque cas ci-dessous.
void main() {
  late _MockAuthBloc auth;
  late _MockForgotBloc forgot;

  setUp(() {
    auth = _MockAuthBloc();
    forgot = _MockForgotBloc();
  });

  Future<void> monter(WidgetTester tester, Size surface, AuthState etat) async {
    when(() => auth.state).thenReturn(etat);
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<ForgotPasswordBloc>.value(value: forgot),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Le clavier tel que le framework le voit : des `viewInsets`, en pixels
  /// **physiques** (`MediaQuery` les divise par le `devicePixelRatio`).
  void ouvrirLeClavier(WidgetTester tester, {double dp = 300}) {
    tester.view.viewInsets = FakeViewPadding(
      bottom: dp * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
  }

  const surfaces = <Size>[
    Size(360, 640), // petit téléphone portrait — palier slim
    Size(411, 731), // téléphone portrait — palier slim
    Size(640, 360), // petit téléphone paysage — palier band
    Size(731, 411), // téléphone paysage — 41 dp, 79 avec l'erreur
    Size(600, 800), // tablette portrait — palier band
    Size(800, 600), // petite tablette — 41 dp, 79 avec l'erreur
    Size(1024, 768), // tablette — palier split
    Size(1280, 800), // tablette paysage (cible du projet) — palier split
  ];

  for (final surface in surfaces) {
    testWidgets('$surface, clavier ouvert : rien ne déborde', (tester) async {
      ouvrirLeClavier(tester);
      await monter(
        tester,
        surface,
        const AuthState(status: AuthStatus.unauthenticated),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$surface, clavier ouvert + bandeau d\'erreur : rien ne '
        'déborde', (tester) async {
      ouvrirLeClavier(tester);
      await monter(
        tester,
        surface,
        const AuthState(
          status: AuthStatus.failure,
          errorKind: AuthErrorKind.invalidCredentials,
        ),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'le bandeau doit AGRANDIR la boîte, pas le débordement',
      );
    });
  }

  // La largeur du formulaire est désormais obtenue par une marge symétrique et
  // non par un plafond : le rendu doit rester au dp près celui d'avant, sans
  // quoi la correction de mesure aurait déplacé la mise en page.
  for (final cas in const [
    (Size(360, 640), 308.0), // palier slim : 360 − 2×26
    (Size(411, 731), 348.0), // palier slim : plafond 400 − 2×26
    (Size(600, 800), 352.0), // palier band : plafond 400 − 2×24
    (Size(800, 600), 352.0), // palier band : plafond 400 − 2×24
  ]) {
    testWidgets('${cas.$1} : le formulaire garde sa largeur de ${cas.$2} dp', (
      tester,
    ) async {
      await monter(
        tester,
        cas.$1,
        const AuthState(status: AuthStatus.unauthenticated),
      );

      final rendu = tester.renderObject<RenderBox>(find.byType(LoginForm));
      expect(rendu.size.width, moreOrLessEquals(cas.$2, epsilon: 0.5));
    });
  }
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_validator.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_initial_contract_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  const contract = StaffContractDraft(
    kind: StaffContractKind.permanent,
    effectiveFrom: '2026-09-01',
    amount: '250',
  );

  /// Monte la carte ; rend le contrat tel que les gestes l'ont changé, et le
  /// nombre de « sans contrat ».
  Future<({StaffContractDraft Function() draft, int Function() clears})> pump(
    WidgetTester tester, {
    StaffContractDraft? value,
    Map<StaffContractField, StaffContractError> errors = const {},
    List<String> permissions = const ['hr.pay.write'],
  }) async {
    var draft = value ?? const StaffContractDraft();
    var clears = 0;
    final auth = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(state);
    whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: auth,
          child: Scaffold(
            body: SingleChildScrollView(
              child: StaffInitialContractCard(
                contract: value,
                errors: errors,
                onChanged: (change) => draft = change(draft),
                onClear: () => clears++,
              ),
            ),
          ),
        ),
      ),
    );
    return (draft: () => draft, clears: () => clears);
  }

  testWidgets('le formulaire est dans l étape : aucun bouton à toucher', (
    tester,
  ) async {
    final card = await pump(tester);

    expect(find.textContaining('Facultatif'), findsOneWidget);
    expect(find.text('Statut'), findsOneWidget);
    expect(find.text('Rémunération'), findsOneWidget);
    expect(find.text('Période'), findsOneWidget);
    // Sans statut, rien n'est posé : pas de « sans contrat » à proposer.
    expect(find.text('Enregistrer sans contrat'), findsNothing);

    await tester.tap(find.text('Vacataire'));
    expect(card.draft().kind, StaffContractKind.vacataire);
  });

  testWidgets('un statut choisi : sa rémunération, le récapitulatif, et '
      '« sans contrat »', (tester) async {
    final card = await pump(tester, value: contract);

    expect(
      find.textContaining('Salaire mensuel', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Sera posé : Permanent'), findsOneWidget);

    await tester.tap(find.text('Enregistrer sans contrat'));
    expect(card.clears(), 1);
  });

  testWidgets('les refus se lisent sous leurs champs', (tester) async {
    await pump(
      tester,
      value: const StaffContractDraft(
        kind: StaffContractKind.permanent,
        effectiveFrom: '2026-09-01',
      ),
      errors: const {StaffContractField.amount: StaffContractError.required},
    );

    expect(
      find.text('Le montant est obligatoire pour ce contrat.'),
      findsOneWidget,
    );
  });

  testWidgets('sans hr.pay.write : aucune saisie, la raison dite', (
    tester,
  ) async {
    await pump(tester, permissions: const ['hr.staff.write']);

    expect(find.text('Statut'), findsNothing);
    expect(find.textContaining('qui gère la paie'), findsOneWidget);
  });
}

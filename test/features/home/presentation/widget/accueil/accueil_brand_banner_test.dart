import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_brand_banner.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSchoolRepository extends Mock implements SchoolRepository {}

void main() {
  Widget buildBanner({SchoolIdentityCubit? schoolIdentityCubit}) {
    const banner = SingleChildScrollView(child: AccueilBrandBanner());
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: schoolIdentityCubit == null
            ? banner
            : BlocProvider<SchoolIdentityCubit>.value(
                value: schoolIdentityCubit,
                child: banner,
              ),
      ),
    );
  }

  SchoolIdentityCubit cubitWith(School? school) {
    final repository = _MockSchoolRepository();
    final cubit = SchoolIdentityCubit(repository: repository);
    cubit.emit(SchoolIdentityState(school: school));
    return cubit;
  }

  testWidgets('l\'eyebrow porte le nom de l\'école et sa ville', (
    tester,
  ) async {
    final cubit = cubitWith(
      const School(
        id: 'school-1',
        name: 'Complexe Scolaire La Colombe',
        city: 'Kinshasa',
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(buildBanner(schoolIdentityCubit: cubit));
    await tester.pumpAndSettle();

    expect(
      find.text('COMPLEXE SCOLAIRE LA COLOMBE · KINSHASA'),
      findsOneWidget,
    );
  });

  testWidgets('sans localité connue, seul le nom de l\'école est affiché', (
    tester,
  ) async {
    final cubit = cubitWith(
      const School(id: 'school-1', name: 'Institut Kalembelembe'),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(buildBanner(schoolIdentityCubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('INSTITUT KALEMBELEMBE'), findsOneWidget);
  });

  testWidgets('identité inconnue → repli sur le nom de marque', (tester) async {
    final cubit = cubitWith(null);
    addTearDown(cubit.close);

    await tester.pumpWidget(buildBanner(schoolIdentityCubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('ETEELO CONNECT'), findsOneWidget);
  });

  testWidgets('cubit absent de l\'arbre : le bandeau tient quand même', (
    tester,
  ) async {
    // Lecture défensive : un montage isolé (test de layout) ne fournit aucun
    // des blocs de session.
    await tester.pumpWidget(buildBanner());
    await tester.pumpAndSettle();

    expect(find.text('ETEELO CONNECT'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_email_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_field_grid.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address/address_geo_catalog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 1 — l'identité de l'établissement.
///
/// **L'école existe déjà** : cette étape la corrige, elle ne la crée pas. Le
/// formulaire est donc pré-rempli par lecture, jamais vide.
///
/// Huit champs, tous obligatoires. Pays et ville sont en lecture — l'application
/// est déployée à Kinshasa — mais partent quand même : les omettre rend 400.
class SchoolIdentityStep extends StatefulWidget {
  const SchoolIdentityStep({super.key});

  @override
  State<SchoolIdentityStep> createState() => _SchoolIdentityStepState();
}

class _SchoolIdentityStepState extends State<SchoolIdentityStep> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  AddressGeoCatalog? _geo;

  /// Ce que les contrôleurs portent déjà, pour ne les réécrire que sur un
  /// changement venu d'ailleurs que de la frappe — réassigner `text` déplace le
  /// curseur en fin de champ, ce qui rend la saisie inutilisable.
  String? _syncedFor;

  @override
  void initState() {
    super.initState();
    _loadGeo();
  }

  Future<void> _loadGeo() async {
    final catalog = await AddressGeoCatalog.load();
    if (!mounted) return;
    setState(() => _geo = catalog);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _syncControllers(SchoolIdentityFormState state) {
    final identity = state.identity;
    if (identity == null) return;

    // Une seule synchronisation par identité rechargée : sans cette garde, tout
    // rebuild du bloc réécrirait les quatre champs et renverrait le curseur au
    // bout à chaque frappe.
    final signature = '${identity.id}#${state.saved.hashCode}';
    if (_syncedFor == signature) return;
    _syncedFor = signature;

    _name.text = identity.name;
    _address.text = identity.address;
    _phone.text = identity.phone;
    _email.text = identity.email;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<SchoolIdentityFormCubit, SchoolIdentityFormState>(
      builder: (context, state) {
        _syncControllers(state);
        final identity = state.identity;
        if (identity == null) return const SizedBox.shrink();

        final cubit = context.read<SchoolIdentityFormCubit>();
        final geo = _geo;
        final districts =
            geo?.districtsForCity(
              identity.city,
              include: identity.district.isEmpty ? null : identity.district,
            ) ??
            const <String>[];
        final municipalities = identity.district.isEmpty
            ? const <String>[]
            : geo?.municipalitiesForDistrict(
                    identity.city,
                    identity.district,
                    include: identity.municipality.isEmpty
                        ? null
                        : identity.municipality,
                  ) ??
                  const <String>[];

        return BiToneSectionCard(
          title: l10n.configurationSchoolSectionTitle,
          subtitle: l10n.configurationSchoolSectionSubtitle,
          icon: Icons.apartment_rounded,
          accentColor: AppColors.terreCuite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EteeloTextInput(
                controller: _name,
                label: l10n.configurationSchoolName,
                required: true,
                onChanged: (value) =>
                    cubit.edit(identity.copyWith(name: value)),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: AppSpacing.lg, color: AppColors.border),

              // Bloc géographique : quatre colonnes au large, deux puis une en
              // dessous des bascules.
              ConfigurationFieldGrid(
                wideColumns: 4,
                children: [
                  EteeloTextInput(
                    controller: TextEditingController(text: identity.country),
                    label: l10n.configurationSchoolCountry,
                    // `readOnly` et non `enabled: false` : le champ garde sa
                    // pleine couleur. Grisé, il se lirait comme désactivé par
                    // une condition qu'on chercherait à lever — alors qu'il est
                    // simplement fixe.
                    readOnly: true,
                  ),
                  EteeloTextInput(
                    controller: TextEditingController(text: identity.city),
                    label: l10n.configurationSchoolCity,
                    readOnly: true,
                  ),
                  EteeloSelectInput<String>(
                    label: l10n.configurationSchoolDistrict,
                    required: true,
                    value: identity.district.isEmpty ? null : identity.district,
                    items: [
                      for (final district in districts)
                        EteeloSelectItem<String>(
                          value: district,
                          label: district,
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) cubit.selectDistrict(value);
                    },
                  ),
                  EteeloSelectInput<String>(
                    label: l10n.configurationSchoolMunicipality,
                    required: true,
                    // Sans district, la commune n'a rien à proposer : la
                    // désactiver et le dire vaut mieux qu'une liste vide, qui
                    // se lit comme une panne.
                    enabled: identity.district.isNotEmpty,
                    placeholder: identity.district.isEmpty
                        ? l10n.configurationSchoolMunicipalityPlaceholder
                        : null,
                    value: identity.municipality.isEmpty
                        ? null
                        : identity.municipality,
                    items: [
                      for (final municipality in municipalities)
                        EteeloSelectItem<String>(
                          value: municipality,
                          label: municipality,
                        ),
                    ],
                    onChanged: (value) => cubit.edit(
                      identity.copyWith(municipality: value ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.configurationSchoolReadOnlyNote,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              EteeloTextInput(
                controller: _address,
                label: l10n.configurationSchoolAddress,
                required: true,
                onChanged: (value) =>
                    cubit.edit(identity.copyWith(address: value)),
              ),
              const SizedBox(height: AppSpacing.md),
              ConfigurationFieldGrid(
                wideColumns: 2,
                children: [
                  EteeloPhoneInput(
                    controller: _phone,
                    label: l10n.configurationSchoolPhone,
                    required: true,
                    onChanged: (value) =>
                        cubit.edit(identity.copyWith(phone: value)),
                  ),
                  EteeloEmailInput(
                    controller: _email,
                    label: l10n.configurationSchoolEmail,
                    onChanged: (value) =>
                        cubit.edit(identity.copyWith(email: value)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Le nom d'un champ requis, pour le message « À compléter : … ».
String schoolIdentityFieldLabel(
  AppLocalizations l10n,
  SchoolIdentityField field,
) {
  return switch (field) {
    SchoolIdentityField.name => l10n.configurationSchoolName,
    SchoolIdentityField.country => l10n.configurationSchoolCountry,
    SchoolIdentityField.city => l10n.configurationSchoolCity,
    SchoolIdentityField.district => l10n.configurationSchoolDistrict,
    SchoolIdentityField.municipality => l10n.configurationSchoolMunicipality,
    SchoolIdentityField.address => l10n.configurationSchoolAddress,
    SchoolIdentityField.phone => l10n.configurationSchoolPhone,
    SchoolIdentityField.email => l10n.configurationSchoolEmail,
  };
}

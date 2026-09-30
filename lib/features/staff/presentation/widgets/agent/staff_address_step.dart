import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/geo/address_geo_catalog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_field_messages.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_step_style.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_synced_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 2 · Adresse — la cascade Ville → District → Commune → Quartier, sur
/// le référentiel partagé avec l'inscription.
///
/// Changer un niveau vide les niveaux inférieurs ; un niveau reste fermé tant
/// que son parent est vide. Le code postal se déduit du quartier : il se lit,
/// il ne se stocke pas.
class StaffAddressStep extends StatelessWidget {
  final StaffAgentState state;

  /// `null` tant que le référentiel se charge.
  final AddressGeoCatalog? catalog;
  final ValueChanged<StaffMemberDraft Function(StaffMemberDraft)> onChanged;

  const StaffAddressStep({
    super.key,
    required this.state,
    required this.catalog,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;
    final readOnly = !state.isEditable;
    final geo = catalog;
    String? error(StaffField field) =>
        StaffFieldMessages.forField(l10n, state.visibleErrors, field);
    final city = draft.city.isEmpty
        ? AddressGeoCatalog.defaultCity
        : draft.city;

    List<EteeloSelectItem<String>> items(List<String> values) => [
      for (final value in values) EteeloSelectItem(value: value, label: value),
    ];
    final districts =
        geo?.districtsForCity(city, include: draft.district) ??
        const <String>[];
    final municipalities = draft.district.isEmpty || geo == null
        ? const <String>[]
        : geo.municipalitiesForDistrict(
            city,
            draft.district,
            include: draft.municipality,
          );
    final neighborhoods = draft.municipality.isEmpty || geo == null
        ? const <String>[]
        : geo.neighborhoodsForMunicipality(
            city,
            draft.district,
            draft.municipality,
          );
    final neighborhoodDisplay = draft.neighborhood.isEmpty || geo == null
        ? null
        : geo.neighborhoodDisplayFromName(
            city,
            draft.district,
            draft.municipality,
            draft.neighborhood,
          );

    return StaffFormBlock(
      title: l10n.staffBlockAddress,
      subtitle: l10n.staffBlockAddressHint,
      icon: Icons.place_outlined,
      color: StaffStepStyle.of(1).color,
      children: [
        StaffFieldRow(
          children: [
            EteeloSelectInput<String>(
              label: l10n.staffFieldCity,
              readOnly: readOnly,
              value: city,
              items: items(geo?.cityOptions(include: city) ?? [city]),
              onChanged: (v) => onChanged(
                (d) => d.copyWith(
                  city: v ?? '',
                  district: '',
                  municipality: '',
                  neighborhood: '',
                ),
              ),
            ),
            EteeloSelectInput<String>(
              label: l10n.staffFieldDistrict,
              required: !readOnly,
              readOnly: readOnly,
              value: draft.district.isEmpty ? null : draft.district,
              errorText: error(StaffField.district),
              items: items(districts),
              onChanged: (v) => onChanged(
                (d) => d.copyWith(
                  city: city,
                  district: v ?? '',
                  municipality: '',
                  neighborhood: '',
                ),
              ),
            ),
          ],
        ),
        StaffFieldRow(
          children: [
            EteeloSelectInput<String>(
              label: l10n.staffFieldMunicipality,
              required: !readOnly,
              readOnly: readOnly,
              enabled: draft.district.isNotEmpty,
              placeholder: draft.district.isEmpty
                  ? l10n.staffPickDistrictFirst
                  : null,
              value: draft.municipality.isEmpty ? null : draft.municipality,
              errorText: error(StaffField.municipality),
              items: items(municipalities),
              onChanged: (v) => onChanged(
                (d) => d.copyWith(municipality: v ?? '', neighborhood: ''),
              ),
            ),
            EteeloSelectInput<String>(
              label: l10n.staffFieldNeighborhood,
              required: !readOnly,
              readOnly: readOnly,
              enabled: draft.municipality.isNotEmpty,
              placeholder: draft.municipality.isEmpty
                  ? l10n.staffPickMunicipalityFirst
                  : null,
              value: neighborhoodDisplay,
              errorText: error(StaffField.neighborhood),
              items: items(
                GeoOptions.withCurrent(neighborhoods, neighborhoodDisplay),
              ),
              onChanged: (display) => onChanged(
                (d) => d.copyWith(
                  neighborhood: display == null || geo == null
                      ? ''
                      : geo.neighborhoodNameFromDisplay(
                          city,
                          d.district,
                          d.municipality,
                          display,
                        ),
                ),
              ),
            ),
          ],
        ),
        StaffSyncedTextInput(
          value: draft.address,
          label: l10n.staffFieldAddress,
          placeholder: l10n.staffFieldAddressPlaceholder,
          readOnly: readOnly,
          onChanged: (v) => onChanged((d) => d.copyWith(address: v)),
        ),
        if (neighborhoodDisplay != null) ...[
          const SizedBox(height: AppSpacing.md),
          _AddressTrail(
            parts: [
              city,
              draft.district,
              draft.municipality,
              neighborhoodDisplay,
            ],
          ),
        ],
      ],
    );
  }
}

/// Une valeur stockée que le référentiel ne propose plus reste affichée.
abstract final class GeoOptions {
  static List<String> withCurrent(List<String> options, String? current) {
    if (current == null || options.contains(current)) return options;
    return [current, ...options];
  }
}

/// « Kinshasa › Funa › Kalamu › Matonge (1234) » — le chemin choisi, code
/// postal compris.
class _AddressTrail extends StatelessWidget {
  final List<String> parts;

  const _AddressTrail({required this.parts});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.place_outlined, size: 16, color: AppColors.bleuArdoise),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          parts.where((p) => p.isNotEmpty).join(' › '),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  );
}

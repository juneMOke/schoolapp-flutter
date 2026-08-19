import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Par quoi l'utilisateur cherche un tuteur déjà connu.
///
/// Les deux modes s'excluent : on cherche par le numéro OU par l'identité,
/// jamais par un mélange des deux. Une recherche qui combinerait un numéro et
/// un nom ne remonterait que les fiches où les deux concordent — c'est-à-dire
/// presque aucune, alors que chaque critère seul aurait suffi.
enum ParentSearchMode { phone, identity }

/// Critères émis à la validation : seuls ceux du mode actif sont renseignés.
class ParentSearchCriteria {
  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? phoneNumber;

  const ParentSearchCriteria({
    this.firstName,
    this.lastName,
    this.surname,
    this.phoneNumber,
  });
}

/// Formulaire de la popin « Rechercher un parent » : bascule de mode, champs
/// du mode actif, bouton de recherche.
///
/// Porte ses propres contrôleurs : la popin le **déplace** (critères figés
/// au-dessus des résultats, ou rendus au défilement) sans jamais le recréer,
/// donc la saisie en cours et le focus lui survivent.
class ParentSearchForm extends StatefulWidget {
  final ValueChanged<ParentSearchCriteria> onSearch;

  const ParentSearchForm({super.key, required this.onSearch});

  @override
  State<ParentSearchForm> createState() => _ParentSearchFormState();
}

class _ParentSearchFormState extends State<ParentSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();

  ParentSearchMode _mode = ParentSearchMode.phone;

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
    _firstNameController,
    _lastNameController,
    _surnameController,
    _phoneController,
  ];

  void _onFieldChanged() => setState(() {});

  /// Le numéro se cherche par bribe (`LIKE` sur les chiffres) : un seul
  /// chiffre arme déjà la recherche. L'identité, elle, demande nom ET prénom —
  /// un nom seul remonterait la moitié du carnet.
  bool get canSearch => switch (_mode) {
    ParentSearchMode.phone => _phoneController.text.trim().isNotEmpty,
    ParentSearchMode.identity =>
      _lastNameController.text.trim().isNotEmpty &&
          _firstNameController.text.trim().isNotEmpty,
  };

  static String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _submit() {
    if (!canSearch) return;
    // Les champs de l'autre mode restent saisis — on y revient sans tout
    // reprendre — mais ils ne partent pas dans la requête.
    widget.onSearch(switch (_mode) {
      ParentSearchMode.phone => ParentSearchCriteria(
        phoneNumber: _trimmedOrNull(_phoneController.text),
      ),
      ParentSearchMode.identity => ParentSearchCriteria(
        firstName: _trimmedOrNull(_firstNameController.text),
        lastName: _trimmedOrNull(_lastNameController.text),
        surname: _trimmedOrNull(_surnameController.text),
      ),
    });
  }

  void _onModeChanged(ParentSearchMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `expand` : dans une modale étroite, deux onglets à largeur
        // intrinsèque débordent (mesuré : 118 dp de trop sur 360 dp de large).
        SegmentedTabFilter<ParentSearchMode>(
          selected: _mode,
          onSelected: _onModeChanged,
          semanticsLabel: l10n.guardianSearchModeSemantics,
          expand: true,
          options: [
            SegmentedTabOption<ParentSearchMode>(
              label: l10n.guardianSearchModeByPhone,
              value: ParentSearchMode.phone,
              icon: Icons.phone_outlined,
            ),
            SegmentedTabOption<ParentSearchMode>(
              label: l10n.guardianSearchModeByIdentity,
              value: ParentSearchMode.identity,
              icon: Icons.person_search_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _ModeHint(
          text: _mode == ParentSearchMode.phone
              ? l10n.guardianSearchPhoneHint
              : l10n.guardianSearchIdentityHint,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildFields(l10n),
        const SizedBox(height: AppDimensions.spacingM),
        Align(
          alignment: Alignment.centerRight,
          child: EteeloButton.primary(
            label: l10n.search,
            icon: Icons.search_rounded,
            fullWidth: false,
            onPressed: canSearch ? _submit : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFields(AppLocalizations l10n) {
    if (_mode == ParentSearchMode.phone) {
      return SizedBox(
        width:
            AppDimensions.guardianSearchCriterionWidth +
            AppDimensions.spacingXL,
        child: EteeloPhoneInput(
          label: l10n.phoneNumberLabel,
          controller: _phoneController,
          required: true,
          dialCodeSemanticLabel: l10n.phoneNumberCountryCodeLabel,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
        ),
      );
    }

    const nameFormatters = <TextInputFormatter>[
      FirstLetterUppercaseTextInputFormatter(),
    ];

    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingM,
      children: [
        SizedBox(
          width: AppDimensions.guardianSearchCriterionWidth,
          child: EteeloTextInput(
            label: l10n.lastName,
            controller: _lastNameController,
            required: true,
            inputFormatters: nameFormatters,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _submit(),
          ),
        ),
        SizedBox(
          width: AppDimensions.guardianSearchCriterionWidth,
          child: EteeloTextInput(
            label: l10n.surname,
            controller: _surnameController,
            inputFormatters: nameFormatters,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _submit(),
          ),
        ),
        SizedBox(
          width: AppDimensions.guardianSearchCriterionWidth,
          child: EteeloTextInput(
            label: l10n.firstName,
            controller: _firstNameController,
            required: true,
            inputFormatters: nameFormatters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
          ),
        ),
      ],
    );
  }
}

/// Aide contextuelle du mode actif : dit ce que le mode accepte, pour éviter
/// que l'utilisateur ne renonce devant un bouton grisé.
class _ModeHint extends StatelessWidget {
  final String text;

  const _ModeHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.bleuArdoise.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.bleuArdoise.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.bleuArdoise,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

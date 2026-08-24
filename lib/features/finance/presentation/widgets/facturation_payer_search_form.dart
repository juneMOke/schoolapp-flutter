import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/search/search_hint_pill.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Par quoi le guichetier retrouve un payeur déjà venu.
///
/// Les deux modes s'excluent (règle non négociable #12) : on cherche par le
/// numéro OU par l'identité. Combiner les deux ne remonterait que les payeurs
/// où tout concorde — presque aucun, alors que chaque critère seul suffisait.
enum PayerSearchMode { phone, identity }

/// Critères émis à la validation : seuls ceux du mode actif sont renseignés.
class PayerSearchCriteria {
  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? phoneNumber;

  const PayerSearchCriteria({
    this.firstName,
    this.lastName,
    this.surname,
    this.phoneNumber,
  });
}

/// Formulaire de la popin « Choisir un payeur » : bascule de mode, champs du
/// mode actif, bouton de recherche.
///
/// Porte ses propres contrôleurs — la popin le déplace sans le recréer, donc
/// la saisie en cours et le focus lui survivent.
class FacturationPayerSearchForm extends StatefulWidget {
  final ValueChanged<PayerSearchCriteria> onSearch;

  /// Vrai pendant qu'une recherche est en vol : la bascule se grise, pour ne
  /// pas changer les champs sous l'utilisateur pendant que la requête court.
  final bool isSearching;

  const FacturationPayerSearchForm({
    super.key,
    required this.onSearch,
    this.isSearching = false,
  });

  @override
  State<FacturationPayerSearchForm> createState() =>
      _FacturationPayerSearchFormState();
}

class _FacturationPayerSearchFormState
    extends State<FacturationPayerSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();

  PayerSearchMode _mode = PayerSearchMode.phone;

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

  /// UN seul mot arme la recherche, dans les deux modes.
  ///
  /// C'est plus permissif que la recherche de tuteurs, et c'est voulu : le
  /// corpus n'est pas le même. On ne fouille pas un carnet d'adresses mais les
  /// payeurs DÉJÀ VENUS à cette caisse — quelques centaines au plus — et le
  /// filtrage exige que chaque mot saisi se retrouve dans le nom complet.
  /// Réclamer nom ET prénom ferait échouer le cas le plus courant : le
  /// guichetier n'a que le nom sous les yeux.
  bool get canSearch => switch (_mode) {
    PayerSearchMode.phone => _phoneController.text.trim().isNotEmpty,
    PayerSearchMode.identity => [
      _lastNameController,
      _surnameController,
      _firstNameController,
    ].any((c) => c.text.trim().isNotEmpty),
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
      PayerSearchMode.phone => PayerSearchCriteria(
        phoneNumber: _trimmedOrNull(_phoneController.text),
      ),
      PayerSearchMode.identity => PayerSearchCriteria(
        firstName: _trimmedOrNull(_firstNameController.text),
        lastName: _trimmedOrNull(_lastNameController.text),
        surname: _trimmedOrNull(_surnameController.text),
      ),
    });
  }

  void _onModeChanged(PayerSearchMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.searchModeSwitchLabel.toUpperCase(),
            style: AppTextStyles.badge.copyWith(
              color: AppColors.terreCuite,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        // `expand` : dans une modale étroite, deux onglets à largeur
        // intrinsèque débordent.
        SegmentedTabFilter<PayerSearchMode>(
          selected: _mode,
          onSelected: _onModeChanged,
          semanticsLabel: l10n.facturationPayerSearchModeSemantics,
          expand: true,
          enabled: !widget.isSearching,
          options: [
            SegmentedTabOption<PayerSearchMode>(
              label: l10n.facturationPayerSearchModeByPhone,
              value: PayerSearchMode.phone,
              icon: Icons.phone_outlined,
            ),
            SegmentedTabOption<PayerSearchMode>(
              label: l10n.facturationPayerSearchModeByIdentity,
              value: PayerSearchMode.identity,
              icon: Icons.person_search_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SearchHintPill(
          text: _mode == PayerSearchMode.phone
              ? l10n.facturationPayerSearchPhoneHint
              : l10n.facturationPayerSearchIdentityHint,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildFields(l10n),
        const SizedBox(height: AppDimensions.spacingM),
        Align(
          alignment: Alignment.centerRight,
          child: EteeloButton.primary(
            label: l10n.facturationPayerSearchAction,
            icon: Icons.search_rounded,
            fullWidth: false,
            onPressed: canSearch ? _submit : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFields(AppLocalizations l10n) {
    if (_mode == PayerSearchMode.phone) {
      return SizedBox(
        width:
            AppDimensions.facturationPayerSearchCriterionWidth +
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

    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingM,
      children: [
        for (final field in [
          (l10n.lastName, _lastNameController, TextInputAction.next),
          (l10n.surname, _surnameController, TextInputAction.next),
          (l10n.firstName, _firstNameController, TextInputAction.search),
        ])
          SizedBox(
            width: AppDimensions.facturationPayerSearchCriterionWidth,
            child: EteeloTextInput(
              label: field.$1,
              controller: field.$2,
              textInputAction: field.$3,
              onSubmitted: (_) => _submit(),
            ),
          ),
      ],
    );
  }
}

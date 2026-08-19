import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input_parts.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Saisie d'un numéro de téléphone au format E.164.
///
/// L'utilisateur ne tape que la partie NATIONALE (`816939060`), l'indicatif
/// étant affiché dans une case à gauche du champ. Le [controller] fourni par
/// l'appelant porte, lui, la valeur COMPLÈTE (`+243816939060`) : c'est elle
/// qui part en base et vers le backend, sans qu'aucun appelant n'ait à
/// recomposer quoi que ce soit.
///
/// V1 : l'indicatif n'est pas modifiable (RDC uniquement, cf.
/// [PhoneCountry.supported]).
///
/// Deux cas hérités sont pris en charge sans jamais réécrire le [controller]
/// tant que l'utilisateur ne touche à rien — une simple mise en forme ne doit
/// pas faire passer un formulaire pour modifié :
/// - un autre format du même plan (`0816939060`, `+243 81 693 90 60`) est
///   compris et affiché comme partie nationale ;
/// - un numéro d'un AUTRE pays (`+32470123456`) bascule le champ en saisie
///   libre, indicatif compris : le tronquer au plan congolais le détruirait.
class EteeloPhoneInput extends StatefulWidget {
  /// Porte la valeur E.164 (`+243816939060`), ou une chaîne vide.
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool readOnly;
  final bool enabled;
  final String? errorText;

  /// Reçoit la valeur E.164 recomposée, jamais la partie nationale seule.
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final PhoneCountry country;

  /// Libellé accessible de la case indicatif (non modifiable en v1).
  final String? dialCodeSemanticLabel;

  const EteeloPhoneInput({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.readOnly = false,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.country = PhoneCountry.congoDrc,
    this.dialCodeSemanticLabel,
  });

  @override
  State<EteeloPhoneInput> createState() => _EteeloPhoneInputState();
}

class _EteeloPhoneInputState extends State<EteeloPhoneInput> {
  /// Ce que voit l'utilisateur : la partie nationale seule, ou le numéro
  /// entier en mode étranger.
  late final TextEditingController _fieldController;

  /// Vrai pendant qu'on répercute une saisie vers le [controller] externe :
  /// empêche le listener de rejouer la conversion en sens inverse et de
  /// déplacer le curseur au milieu de la frappe.
  bool _pushingToExternal = false;

  /// La valeur porte un indicatif que la case ne peut pas représenter.
  late bool _foreign;

  @override
  void initState() {
    super.initState();
    _foreign = _isForeignExternal();
    _fieldController = TextEditingController(text: _displayFromExternal());
    widget.controller.addListener(_handleExternalChanged);
  }

  @override
  void didUpdateWidget(covariant EteeloPhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleExternalChanged);
      widget.controller.addListener(_handleExternalChanged);
      _handleExternalChanged();
    }
    if (oldWidget.country != widget.country) {
      _foreign = _isForeignExternal();
      _fieldController.text = _displayFromExternal();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleExternalChanged);
    _fieldController.dispose();
    super.dispose();
  }

  bool _isForeignExternal() => PhoneNumberFormat.isForeign(
    widget.controller.text,
    country: widget.country,
  );

  String _displayFromExternal() => _foreign
      ? widget.controller.text.trim()
      : PhoneNumberFormat.nationalPartOf(
          widget.controller.text,
          country: widget.country,
        );

  /// Le controller externe a été réécrit par l'appelant (hydratation d'une
  /// fiche, réinitialisation d'un formulaire) : on réaligne l'affichage.
  void _handleExternalChanged() {
    if (_pushingToExternal) return;
    final foreign = _isForeignExternal();
    if (foreign != _foreign) {
      setState(() => _foreign = foreign);
    }
    final display = _displayFromExternal();
    if (_fieldController.text == display) return;
    _fieldController.text = display;
  }

  void _handleFieldChanged(String text) {
    // Un champ vidé rend la main au plan national : sans cela, l'utilisateur
    // resterait prisonnier du mode libre après avoir effacé un numéro
    // étranger.
    if (_foreign && PhoneNumberFormat.digitsOnly(text).isEmpty) {
      setState(() => _foreign = false);
    }
    final value = _foreign
        ? text.trim()
        : PhoneNumberFormat.toE164(text, country: widget.country);
    if (widget.controller.text != value) {
      _pushingToExternal = true;
      widget.controller.text = value;
      _pushingToExternal = false;
    }
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return EteeloTextInput(
      controller: _fieldController,
      label: widget.label,
      required: widget.required,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      errorText: widget.errorText,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      keyboardType: EteeloTextInputType.phone,
      placeholder: _foreign ? null : widget.country.exampleNationalNumber,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [
        if (_foreign)
          const ForeignNumberInputFormatter()
        else
          NationalNumberInputFormatter(widget.country),
      ],
      onChanged: _handleFieldChanged,
      onSubmitted: (_) => widget.onSubmitted?.call(widget.controller.text),
      prefix: PhoneDialCodeBox(
        country: widget.country,
        semanticLabel: widget.dialCodeSemanticLabel,
        foreign: _foreign,
      ),
    );
  }
}

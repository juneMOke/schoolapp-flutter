import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc « Informations du payeur » de l'encaissement : les quatre champs, la
/// règle qui décide si l'argent peut partir, et la tolérance au numéro hérité.
///
/// Sorti de la page parce que c'est la seule règle money-grade de cet écran :
/// mêlée au reste, elle se relisait entre deux appels de navigation.
///
/// **Les quatre champs sont FACULTATIFS** depuis que le serveur a relâché son
/// arête HTTP (V114) — ses colonnes, elles, étaient nullables depuis sa V10.
/// L'exigence se payait comptant au guichet : la file attend pendant qu'on
/// demande son état civil à qui tend les billets, et le guichetier finit par
/// taper « X » pour avancer. Le champ a alors l'air renseigné et ne désigne
/// personne — strictement pire qu'un champ vide, parce qu'on ne peut plus
/// distinguer les deux. Un payeur ABSENT vaut mieux qu'un payeur INVENTÉ : les
/// imputations nomment toujours l'élève et les créances soldées, et c'est là
/// qu'est l'imputabilité.
///
/// Ce qui reste exigé, c'est le **format du numéro quand un numéro est entamé**.
/// Une absence est une décision ; un numéro tronqué est une faute de frappe.
class FacturationPayerFormController extends ChangeNotifier {
  final lastName = TextEditingController();
  final firstName = TextEditingController();
  final middleName = TextEditingController();

  /// Porte l'E.164 complet (`+243816939060`) — c'est `EteeloPhoneInput` qui
  /// recompose, aucun appelant n'a à le faire.
  final phone = TextEditingController();

  /// Numéro tel qu'il est arrivé d'un payeur repris dans l'annuaire, avant
  /// toute retouche. Un numéro HÉRITÉ mal formé (`0816939060` d'une fiche
  /// ancienne) ne doit pas bloquer l'encaissement tant que le guichetier n'y a
  /// pas touché : il ne l'a pas saisi, et le reformater d'office ferait partir
  /// au serveur un numéro que personne n'a validé. Dès la première frappe, la
  /// règle normale reprend.
  String? _pickedPhone;

  FacturationPayerFormController() {
    for (final field in _fields) {
      field.addListener(_onFieldChanged);
    }
  }

  List<TextEditingController> get _fields => [
    lastName,
    firstName,
    middleName,
    phone,
  ];

  void _onFieldChanged() {
    // La tolérance ne couvre QUE la valeur reprise telle quelle : dès qu'elle
    // diverge, le guichetier a repris la main et le format redevient exigé.
    if (_pickedPhone != null && phone.text.trim() != _pickedPhone) {
      _pickedPhone = null;
    }
    notifyListeners();
  }

  /// Le versement peut-il partir au nom de ce payeur ?
  ///
  /// **Un formulaire entièrement vide est valide** : le versement part alors
  /// sans payeur nommé, et c'est un cas nominal, pas une négligence.
  bool get isValid => isPhoneAcceptable;

  /// Le téléphone n'est plus obligatoire, mais reste exigé **complet dès qu'il
  /// est entamé** : un numéro tronqué partirait en base et vers le serveur en
  /// E.164 invalide, sans moyen de rappeler le payeur — et il est recopié sur
  /// chaque versement, donc jamais corrigeable après coup. C'est aussi la clé
  /// de rapprochement de l'annuaire : à moitié tapé, il rend ce payeur
  /// introuvable demain.
  ///
  /// Vide = acceptable. Ne rien mettre est une décision ; mettre la moitié d'un
  /// numéro est une faute de frappe, et les deux ne se traitent pas pareil.
  ///
  /// Seule autre exception : la valeur héritée d'un payeur repris dans
  /// l'annuaire, tant qu'elle est INTACTE. Exiger un format qu'aucune saisie du
  /// guichetier n'a produit bloquerait un encaissement pour une donnée écrite
  /// ailleurs.
  bool get isPhoneAcceptable {
    final raw = phone.text.trim();
    if (raw.isEmpty) return true;
    if (PhoneNumberFormat.isValid(raw)) return true;
    return _pickedPhone != null && raw == _pickedPhone!.trim();
  }

  /// Erreur affichée sous le champ : jamais tant que le champ est vide — le
  /// formulaire s'ouvre vierge, et un champ facultatif laissé vide n'a rien à se
  /// reprocher. Seulement quand ce qui est saisi ne fait pas un numéro complet.
  String? phoneErrorText(AppLocalizations l10n) {
    if (isPhoneAcceptable) return null;
    return l10n.phoneNumberInvalidError(PhoneCountry.congoDrc.nationalLength);
  }

  /// Reprend un payeur de l'annuaire : les quatre champs sont remplis d'un
  /// coup, et restent modifiables — le nom d'un payeur peut avoir été mal
  /// orthographié au versement précédent.
  void applyPayer(LocalPayerIdentity payer) {
    lastName.text = payer.lastName;
    firstName.text = payer.firstName;
    middleName.text = payer.middleName ?? '';
    // La tolérance au numéro malformé appartient au payeur qui l'a apporté, pas
    // au champ. Sans cette remise à zéro elle survivait au changement de
    // payeur : reprendre A (numéro hérité invalide) puis B (aucun numéro connu,
    // donc champ inchangé) laissait passer un versement au nom de B portant le
    // numéro invalide de A — sans erreur affichée.
    _pickedPhone = null;
    // Un payeur sans numéro connu (versements antérieurs à la v28) ne doit pas
    // EFFACER un numéro déjà tapé : on ne remplace que ce qu'on sait.
    final number = payer.phoneNumber?.trim() ?? '';
    if (number.isNotEmpty) {
      phone.text = number;
      _pickedPhone = number;
    }
    notifyListeners();
  }

  /// Nom complet du payeur (Nom · Post-nom · Prénom), ou [fallback] si rien
  /// n'est encore saisi.
  String fullName(String fallback) => composedName ?? fallback;

  /// Nom complet, ou `null` si aucun des trois champs n'est renseigné.
  ///
  /// `null` et jamais `''` : c'est la distinction que le serveur s'est donnée
  /// en V114 — « pas de payeur » est un fait, pas un nom de longueur zéro — et
  /// c'est elle qui décide si l'écran de confirmation montre un bloc payeur.
  String? get composedName {
    final name = [
      lastName.text,
      middleName.text,
      firstName.text,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');
    return name.isEmpty ? null : name;
  }

  /// Le payeur a-t-il été nommé, d'une façon ou d'une autre ?
  ///
  /// Le numéro compte : il a été tapé, donc il désigne quelqu'un. Même règle que
  /// le reçu de vente scellé.
  bool get hasIdentity => composedName != null || phone.text.trim().isNotEmpty;

  /// Ce qui part au serveur : la valeur saisie, ou `null` si le champ est vide.
  String? valueOf(TextEditingController field) {
    final trimmed = field.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }
}

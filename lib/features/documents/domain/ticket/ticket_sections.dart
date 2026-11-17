import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_qr_band.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_sheet.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_primitives.dart';

/// L'école, telle que l'en-tête d'un ticket la nomme.
class TicketSchoolHeader extends Equatable {
  final String name;
  final String? address;

  /// La ville, la commune à défaut (`TicketSchoolRow.locality`).
  final String? locality;
  final String? email;

  /// Le téléphone de l'école, imprimé « Tél. Promoteur ».
  final String? phone;

  /// Le numéro de la caisse (v50), sur sa propre ligne nommée.
  final String? tillPhone;

  const TicketSchoolHeader({
    required this.name,
    this.address,
    this.locality,
    this.email,
    this.phone,
    this.tillPhone,
  });

  @override
  List<Object?> get props => [name, address, locality, email, phone, tillPhone];
}

/// Les blocs que **tous les tickets de caisse** partagent : l'en-tête de
/// l'école, la date et le caissier, le payeur, la signature, le QR et le pied.
/// L'argent reçu a les siens (`TicketMoneySections`).
///
/// La perception et la vente boutique sortent de la même imprimante et finissent
/// dans les mains du même parent : deux copies de ces blocs divergeraient au
/// premier ajustement, et deux pièces de la même caisse ne se ressembleraient
/// plus. Chaque gabarit garde ce qui lui est propre — l'élève et la répartition
/// d'un côté, le panier de l'autre — et appelle ces blocs pour le reste.
abstract final class TicketSections {
  /// L'en-tête complet : nom (gras), adresse, localité, e-mail, puis les deux
  /// téléphones. Le filet qui le clôt reste à l'appelant.
  ///
  /// Le logo n'est PAS ici : c'est une bande posée par chaque renderer en amont
  /// de ces lignes. Une image ne passe pas par le pivot textuel, et c'est ce
  /// pivot qui rend vérifiable « même contenu textuel entre les deux sorties ».
  ///
  /// Aucune garde sur les lignes optionnelles : `centered('')` rend une liste
  /// VIDE. Une école mal renseignée sort un en-tête plus COURT, jamais troué —
  /// sur une pièce, une ligne blanche se lirait comme une mention effacée.
  static void schoolHeader(
    TicketSheet sheet,
    TicketSchoolHeader school, {
    required String schoolPhoneLabel,
    required String tillPhoneLabel,
  }) {
    final width = sheet.width;
    final lines = sheet.lines;
    sheet.emphasised(
      () => lines.addAll(
        TicketTextPrimitives.centered(school.name.toUpperCase(), width),
      ),
    );
    lines.addAll(TicketTextPrimitives.centered(school.address ?? '', width));
    lines.addAll(TicketTextPrimitives.centered(school.locality ?? '', width));
    lines.addAll(TicketTextPrimitives.centered(school.email ?? '', width));

    // Les DEUX téléphones, chacun sur sa ligne et chacun NOMMÉ : deux numéros
    // nus laisseraient le parent deviner lequel appeler pour une question de
    // paiement — précisément la question que le numéro de caisse existe pour
    // clore. Nommés, mais escamotables : un libellé sans numéro se lirait comme
    // un numéro effacé.
    centeredOptional(sheet, schoolPhoneLabel, school.phone);
    centeredOptional(sheet, tillPhoneLabel, school.tillPhone);
  }

  /// Une ligne d'en-tête NOMMÉE, centrée, et **escamotée quand elle est vide**.
  ///
  /// ## Le repli : le libellé au-dessus, jamais le numéro coupé
  ///
  /// « Tél. Promoteur : +243 000 000 000 » fait 33 caractères. Il tient à 48
  /// et **déborde à 32** — le papier 58 mm —, où un repli sur les espaces
  /// rendrait `+243 000 000` puis `000` : un numéro que personne ne peut
  /// composer. Quand les deux ne tiennent pas ensemble, le libellé prend sa
  /// propre ligne et la valeur la suivante, entière : **on ne tronque jamais une
  /// valeur, on la reporte.**
  static void centeredOptional(TicketSheet sheet, String label, String? value) {
    final width = sheet.width;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return;
    // Mesure sur la forme TRANSLITTÉRÉE : c'est elle qui s'imprime, et « œ »
    // devient « oe ».
    final oneLine = TicketCharset.printable('$label $trimmed');
    if (oneLine.length <= width) {
      sheet.lines.addAll(TicketTextPrimitives.centered(oneLine, width));
      return;
    }
    sheet.lines.addAll(TicketTextPrimitives.centered(label, width));
    sheet.lines.addAll(TicketTextPrimitives.centered(trimmed, width));
  }

  /// La date, puis le caissier. Le filet qui suit reste à l'appelant.
  ///
  /// Un ticket dont on connaît le jour d'émission ([issuedOn]) prend CE jour en
  /// date principale, sans heure — c'est une date, pas l'instant du scellement.
  /// La saisie passe dessous, date et heure : « Saisi le ». Sans jour
  /// d'émission, la saisie occupe seule la ligne « Date : », l'heure calée à
  /// droite.
  static void dateAndCashier(
    TicketSheet sheet, {
    required String dateLabel,
    required String enteredAtLabel,
    required DateTime enteredAt,
    DateTime? issuedOn,
    required String cashierLabel,
    String? cashierFullName,
  }) {
    final width = sheet.width;
    final lines = sheet.lines;
    final enteredDay = TicketTextPrimitives.formatDate(enteredAt);
    final enteredTime = TicketTextPrimitives.formatTime(enteredAt);
    if (issuedOn == null) {
      TicketTextPrimitives.addPair(
        lines,
        '$dateLabel $enteredDay',
        enteredTime,
        width,
      );
    } else {
      lines.addAll(
        TicketTextPrimitives.wrapped(
          '$dateLabel ${TicketTextPrimitives.formatDate(issuedOn)}',
          width,
        ),
      );
      TicketTextPrimitives.addPair(
        lines,
        '$enteredAtLabel $enteredDay',
        enteredTime,
        width,
      );
    }
    // Sur une pièce, l'imputabilité HUMAINE complète la cryptographique : sans
    // caissier nommé, un écart de tiroir en fin de journée ne s'arbitre pas.
    TicketTextPrimitives.addOptional(
      lines,
      cashierLabel,
      cashierFullName,
      width,
    );
  }

  /// Le payeur, **quand il y en a un**, suivi de son filet.
  ///
  /// Le bloc ENTIER disparaît sinon — ni cadre vide, ni tiret : une mention
  /// laissée vide se lit comme une mention EFFACÉE. Un téléphone SEUL garde le
  /// bloc : il a été tapé, donc il désigne quelqu'un. Même règle que le reçu
  /// scellé du serveur : deux pièces du même acte qui divergent se paient au
  /// rapprochement de caisse.
  static void payer(
    TicketSheet sheet, {
    required String payerLabel,
    required String phoneLabel,
    String? fullName,
    String? phoneNumber,
  }) {
    final name = fullName?.trim() ?? '';
    final phone = phoneNumber?.trim() ?? '';
    if (name.isEmpty && phone.isEmpty) return;
    final width = sheet.width;
    if (name.isNotEmpty) {
      sheet.lines.addAll(
        TicketTextPrimitives.wrapped(
          '$payerLabel ${name.toUpperCase()}',
          width,
        ),
      );
    }
    TicketTextPrimitives.addOptional(sheet.lines, phoneLabel, phone, width);
    sheet.lines.add(TicketTextPrimitives.rule(width));
  }

  /// La zone à signer, le QR de vérification puis le pied.
  ///
  /// C'est le CAISSIER qui signe : sur un papier que le parent emporte, sa
  /// propre signature ne vaudrait que contre une souche. Trois temps, dans
  /// l'ordre d'une vraie zone de signature : le libellé dit qui signe, le blanc
  /// donne la hauteur du geste, le trait dit où il s'arrête. Conditionnée au
  /// libellé : une traduction incomplète escamote la zone plutôt que d'imprimer
  /// un trait orphelin.
  ///
  /// Le QR, scanné, dit si le reçu est en vigueur, annulé ou remplacé. Il n'est
  /// posé que si l'URL tient sur le papier ; [verificationUrl] `null` — reçu non
  /// scellé, ou serveur qui ne l'envoie pas encore — le retire, notice comprise.
  ///
  /// Le site de l'éditeur est sur sa PROPRE ligne, sans schéma : un `http://`
  /// imprimé sur un papier que des familles gardent annoncerait un transport
  /// non chiffré.
  static void closing(
    TicketSheet sheet, {
    required String signatureLabel,
    required String verificationNotice,
    String? verificationUrl,
    required String thanksNotice,
    required String editorNotice,
    required String editorSite,
  }) {
    final width = sheet.width;
    final lines = sheet.lines;
    final signature = TicketTextPrimitives.wrapped(signatureLabel, width);
    if (signature.isNotEmpty) {
      lines.add(TicketTextPrimitives.rule(width));
      sheet.emphasised(() => lines.addAll(signature));
      lines.add('');
      lines.add('');
      // À DROITE et sur la moitié de la laize, en pointillé : un trait plein
      // bave en thermique, et un pointillé se distingue d'un filet de section.
      lines.add(('.' * (width ~/ 2)).padLeft(width));
      lines.add(TicketTextPrimitives.rule(width));
    }

    if (verificationUrl != null &&
        TicketQrBand.fits(verificationUrl, columns: width)) {
      lines.addAll(
        TicketTextPrimitives.centeredWrapped(verificationNotice, width),
      );
      sheet.placeQr(verificationUrl);
    }

    lines.addAll(TicketTextPrimitives.centeredWrapped(thanksNotice, width));
    lines.addAll(TicketTextPrimitives.centered(editorNotice, width));
    lines.addAll(TicketTextPrimitives.centered(editorSite, width));
  }
}

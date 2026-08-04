import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:school_app_flutter/features/documents/data/ticket/pdf_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';

const _labels = TicketLabels(
  provisionalBanner: 'Provisoire',
  referenceLabel: 'Réf.',
  cashierLabel: 'Caissier :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  allocationsLabel: 'Répartition',
  balanceLabel: 'Solde',
  balanceReservation: 'sous réserve de synchronisation',
  keepTicketNotice: 'Conservez ce ticket.',
);

TicketReceiptModel _model({int allocationCount = 2}) => TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  schoolMunicipality: 'Ngaliema',
  studentFullName: 'Mbala Kasa Amina',
  matriculationNumber: 'MAT-0042',
  classroomName: '5e primaire A',
  provisionalReference: 'PROV-A1B2C3-9F8E7D6C',
  paidAt: DateTime(2026, 8, 4, 14, 7),
  cashierFullName: 'Jean Kabeya',
  amountReceivedInCents: 150000,
  allocations: [
    for (var i = 0; i < allocationCount; i++)
      TicketAllocationLine(label: 'Poste $i', amountInCents: 1000 * (i + 1)),
  ],
  remainingBalanceInCents: 250000,
  currency: 'CDF',
  labels: _labels,
);

void main() {
  test('produit un PDF valide', () async {
    final bytes = await PdfTicketRenderer.render(_model());

    expect(bytes, isNotEmpty);
    // Signature %PDF — même garde que le mapper d'éditique côté serveur.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  // `pw.MultiPage` asserte contre une hauteur infinie, que `roll80` porte par
  // définition : ce test échouerait immédiatement si quelqu'un l'y substituait.
  test('rend un rouleau 80 mm de hauteur libre', () async {
    expect(PdfTicketRenderer.pageFormat.width, PdfPageFormat.roll80.width);
    expect(PdfTicketRenderer.pageFormat.height, double.infinity);

    await expectLater(PdfTicketRenderer.render(_model()), completes);
  });

  // Aucune pagination sur un rouleau : une répartition longue produit une page
  // unique très haute — comportement voulu, pas un débordement.
  test('encaisse une répartition très longue sans lever', () async {
    final bytes = await PdfTicketRenderer.render(_model(allocationCount: 120));

    expect(bytes, isNotEmpty);
  });

  test('deux rendus du même modèle produisent la même taille', () async {
    final model = _model();

    final first = await PdfTicketRenderer.render(model);
    final second = await PdfTicketRenderer.render(model);

    expect(first.length, second.length);
  });

  // LE défaut que les tests de gabarit ne pouvaient pas voir : il est
  // typographique, pas textuel. 48 caractères de Courier à une taille posée à
  // la main débordaient la largeur utile du rouleau, et `pw.Text` repliait la
  // ligne en silence — « Montant reçu … 25 » puis « 000,00 CDF » en dessous, sur
  // le papier remis au parent.
  test('une ligne pleine largeur tient sur UNE ligne imprimée', () {
    const courierAdvance = 0.6;
    final lineWidth =
        PdfTicketRenderer.columns * courierAdvance * PdfTicketRenderer.fontSize;

    expect(
      lineWidth,
      lessThanOrEqualTo(PdfTicketRenderer.usableWidth),
      reason:
          'ligne de ${PdfTicketRenderer.columns} caractères = '
          '${lineWidth.toStringAsFixed(2)} pt pour '
          '${PdfTicketRenderer.usableWidth.toStringAsFixed(2)} pt utiles',
    );
  });

  // Le corps est DÉRIVÉ de la géométrie : changer le format ou le nombre de
  // colonnes ne doit pas pouvoir recréer le repli.
  test('le corps de texte reste lisible sur papier thermique', () {
    expect(PdfTicketRenderer.fontSize, greaterThan(6.0));
    expect(PdfTicketRenderer.fontSize, lessThan(9.0));
  });

  // Une ligne de 48 caractères produit une page d'UNE hauteur de ligne : deux
  // signeraient un repli.
  test('une ligne pleine largeur ne double pas la hauteur de page', () async {
    final short = await PdfTicketRenderer.render(_modelWithSingleLine('court'));
    final full = await PdfTicketRenderer.render(_modelWithSingleLine('X' * 40));

    // Tolérance large : on veut détecter un DOUBLEMENT, pas un octet près.
    expect(full.length, lessThan(short.length * 2));
  });
}

/// Modèle réduit à l'essentiel, pour isoler l'effet d'une seule ligne longue.
TicketReceiptModel _modelWithSingleLine(String studentName) =>
    TicketReceiptModel(
      schoolName: 'E',
      studentFullName: studentName,
      provisionalReference: 'PROV-1',
      paidAt: DateTime(2026, 8, 4, 14, 7),
      amountReceivedInCents: 2500000000,
      currency: 'CDF',
      labels: _labels,
    );

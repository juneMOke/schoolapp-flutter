import 'dart:typed_data';

/// Les octets de la photo d'un bon, prêts à montrer.
class ExpenseVoucherImage {
  final Uint8List bytes;

  /// `image/jpeg`, `image/png`, `image/webp` ou `application/pdf`.
  final String contentType;

  const ExpenseVoucherImage({required this.bytes, required this.contentType});

  bool get isPdf => contentType == 'application/pdf';
}

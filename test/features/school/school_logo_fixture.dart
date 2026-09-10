import 'dart:typed_data';

import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';

/// Un PNG **valide** de 1×1 pixel transparent, en octets littéraux.
///
/// Valide et non arbitraire : `Image.memory` appelle son `errorBuilder` sur des
/// octets qui ne sont pas une image, et une fixture bidon ferait donc passer
/// tous les tests de repli — y compris ceux qui prétendent vérifier qu'un sceau
/// s'affiche.
final Uint8List schoolLogoPngBytes = Uint8List.fromList(const [
  137, 80, 78, 71, 13, 10, 26, 10, //
  0, 0, 0, 13, 73, 72, 68, 82, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, //
  0, 0, 0, 11, 73, 68, 65, 84, 120, 218, 99, 96, 0, 2, 0, 0, 5, 0, 1, //
  233, 250, 220, 216, //
  0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
]);

/// Un sceau d'école utilisable en test de widget.
SchoolLogo fakeSchoolLogo({String sha256 = 'sceau-1'}) =>
    SchoolLogo(sha256: sha256, bytes: schoolLogoPngBytes);

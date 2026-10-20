import 'package:school_app_flutter/core/web/text_file_download_stub.dart'
    if (dart.library.js_interop) 'package:school_app_flutter/core/web/text_file_download_web.dart'
    as impl;

/// Vrai quand un fichier texte peut être téléchargé tel quel (le web). Ailleurs,
/// les exports passent par le presse-papiers.
const bool canDownloadTextFiles = impl.canDownloadTextFiles;

/// Fait télécharger [content] au navigateur sous [fileName]. Un CSV part en
/// UTF-8 avec sa marque d'ordre : sans elle, un tableur ouvre « Élève » en
/// « Ã‰lÃ¨ve ». No-op hors du web.
void downloadTextFile({
  required String fileName,
  required String content,
  String mimeType = 'text/csv;charset=utf-8',
}) => impl.downloadTextFile(
  fileName: fileName,
  content: '﻿$content',
  mimeType: mimeType,
);

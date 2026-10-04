import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:school_app_flutter/core/database/web_database_opener.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_files.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/web_blob_files.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Le support des octets scellés du magasin [store] sur cette plateforme :
/// IndexedDB dans le navigateur, `null` ailleurs — le magasin retombe alors
/// sur son répertoire disque.
BlobFiles? platformBlobFiles(String store) => kIsWeb
    ? WebBlobFiles(
        name: store,
        factory: databaseFactoryFfiWeb,
        path: '$webDatabasesDirectory/blobs.db',
      )
    : null;

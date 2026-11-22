import 'dart:io';

import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';

/// Fiche signée par `scripts/release/sign_desktop_payload.sh` (OpenSSL) avec
/// une clé de TEST jetable : la vérification Dart doit l'accepter à l'octet.
String fixture(String name) =>
    File('test/fixtures/desktop_update/$name').readAsStringSync();

String get testPublicKey => fixture('public_key.b64').trim();
String get signedPayload => fixture('signed_payload.json');
String get tamperedPayload => fixture('tampered_payload.json');
String get signature => fixture('signature.b64').trim();

DesktopRelease release({
  AppVersion version = const AppVersion(1, 9, 0),
  String sha256 =
      'caee4a147197d7055e634b62e0d95121f21e5d6b6113dfe6c53cb62387357b4d',
  int size = 61,
  String url =
      'https://github.com/juneMOke/schoolapp-flutter/releases/download/desktop-prod-v1.9.0/eteelo-connect-1.9.0-prod-windows-x64-setup.exe',
}) => DesktopRelease(
  version: version,
  platform: DesktopPlatform.windows,
  channel: 'prod',
  url: Uri.parse(url),
  sha256: sha256,
  size: size,
  notesFr: 'Réglages',
  notesEn: 'Settings',
);

DesktopUpdateOffer offer({
  AppVersion installed = const AppVersion(1, 8, 0),
  AppVersion? minimum,
  DesktopRelease? of,
}) => DesktopUpdateOffer(
  installed: installed,
  release: of ?? release(),
  minimumSupported: minimum,
);

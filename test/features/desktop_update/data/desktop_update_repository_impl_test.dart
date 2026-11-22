import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_installer.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_release_api.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_release_verifier.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_downloader.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_repository_impl.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';

import '../fixtures.dart';

class _Api extends DesktopReleaseApi {
  Object? answer;
  AppVersion? since;

  _Api() : super(Dio());

  @override
  Future<DesktopLatestWire?> latest({
    required DesktopPlatform platform,
    required AppVersion since,
  }) async {
    this.since = since;
    final value = answer;
    if (value is Exception) throw value;
    return value as DesktopLatestWire?;
  }
}

class _Installer implements DesktopInstaller {
  Object? error;

  @override
  Future<void> install(VerifiedInstaller installer) async {
    if (error != null) throw error!;
  }
}

DesktopLatestWire wire({
  String? minimum,
  String? payload,
  List<DesktopReleaseNotes> notes = const [],
}) => DesktopLatestWire(
  signedPayload: payload ?? signedPayload,
  signature: signature,
  minimumSupported: minimum,
  notesSince: notes,
);

DesktopReleaseNotes notesOf(String version) => DesktopReleaseNotes(
  version: AppVersion.tryParseStrict(version)!,
  notesFr: version,
  notesEn: version,
);

void main() {
  late _Api api;
  late _Installer installer;
  late DesktopUpdateRepositoryImpl repository;

  setUp(() {
    api = _Api();
    installer = _Installer();
    repository = DesktopUpdateRepositoryImpl(
      api: api,
      verifier: DesktopReleaseVerifier(
        platform: DesktopPlatform.windows,
        channel: 'prod',
        publicKeys: [testPublicKey],
      ),
      downloader: DesktopUpdateDownloader(
        dio: Dio(),
        baseDirectory: () => throw UnimplementedError(),
      ),
      installer: installer,
    );
  });

  test('aucune version publiée : rien à proposer', () async {
    api.answer = null;
    final result = await repository.fetchOffer(const AppVersion(1, 8, 0));
    expect(result.getOrElse(() => throw 'left'), isNull);
    expect(api.since, const AppVersion(1, 8, 0));
  });

  test('version plus récente : proposée, minimum et notes lus', () async {
    api.answer = wire(
      minimum: '1.8.5',
      notes: [
        notesOf('1.9.0'),
        notesOf('1.8.5'),
        notesOf('1.8.0'),
        notesOf('2.0.0'),
      ],
    );
    final offer = (await repository.fetchOffer(
      const AppVersion(1, 8, 0),
    )).getOrElse(() => throw 'left')!;
    expect(offer.release.version, const AppVersion(1, 9, 0));
    expect(offer.mandatory, isTrue);
    // Ni la version installée, ni une version au-delà de celle proposée.
    expect(offer.notesSince.map((n) => '${n.version}'), ['1.9.0', '1.8.5']);
  });

  test('version égale ou plus basse : jamais proposée', () async {
    api.answer = wire();
    for (final installed in [
      const AppVersion(1, 9, 0),
      const AppVersion(2, 0, 0),
    ]) {
      final result = await repository.fetchOffer(installed);
      expect(result.getOrElse(() => throw 'left'), isNull);
    }
  });

  test('un minimum au-dessus de la version proposée est ignoré', () async {
    api.answer = wire(minimum: '3.0.0');
    final offer = (await repository.fetchOffer(
      const AppVersion(1, 8, 0),
    )).getOrElse(() => throw 'left')!;
    expect(offer.minimumSupported, isNull);
    expect(offer.mandatory, isFalse);
  });

  test('fiche modifiée : refusée, rien n’est proposé', () async {
    api.answer = wire(payload: tamperedPayload);
    final result = await repository.fetchOffer(const AppVersion(1, 8, 0));
    expect(result.fold((f) => f, (_) => null), isA<UntrustedReleaseFailure>());
  });

  test('réseau injoignable : un échec, pas une offre', () async {
    api.answer = DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    );
    final result = await repository.fetchOffer(const AppVersion(1, 8, 0));
    expect(result.isLeft(), isTrue);
  });

  test('un échec de l’installateur devient InstallFailure', () async {
    installer.error = const DesktopInstallException('tar (2)');
    final result = await repository.install(
      VerifiedInstaller(path: '/x', release: release()),
    );
    expect(result.fold((f) => f, (_) => null), isA<InstallFailure>());
  });

  test('installation lancée : succès', () async {
    final result = await repository.install(
      VerifiedInstaller(path: '/x', release: release()),
    );
    expect(result.isRight(), isTrue);
    expect(result.fold((f) => f, (_) => null), isNot(isA<Failure>()));
  });
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

const MethodChannel pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const MethodChannel packageInfoChannel = MethodChannel(
  'dev.fluttercommunity.plus/package_info',
);

Future<void> installCommonTestPluginMocks() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (
        MethodCall methodCall,
      ) async {
        if (methodCall.method == 'read') return null;
        return null;
      });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (
        MethodCall methodCall,
      ) async {
        return '/tmp';
      });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(packageInfoChannel, (
        MethodCall methodCall,
      ) async {
        return <String, dynamic>{
          'appName': 'ETEELO CONNECT',
          'packageName': 'com.eteelo.school_app_flutter',
          'version': '1.0.0',
          'buildNumber': '1',
          'buildSignature': '',
          'installerStore': null,
        };
      });
}

Future<void> removeCommonTestPluginMocks() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(packageInfoChannel, null);
}

Future<void> pumpBounded(
  WidgetTester tester,
  Widget widget, {
  int frames = 2,
  Duration step = const Duration(milliseconds: 120),
}) async {
  await tester.pumpWidget(widget);
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

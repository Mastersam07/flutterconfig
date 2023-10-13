import 'package:flutterconfig_cli/src/commands/commands.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'package:test/test.dart';

void main() {
  late MockFileAccessor mockFileAccessor;
  late MockLogger mockLogger;
  late CheckCommand checkCommand;
  const mockFlutterConfigContent = '''
metadata:
  name: TestApp
  version: 1.0.0
platform_specific:
  android:
    permissions:
      - android.permission.INTERNET
  ios:
    permissions:
      - NSCameraUsageDescription
visual_assets:
  icons:
    main: assets/icon.png
integrations:
  firebase:
    android_config_path: android/app/google-services.json
    ios_config_path: ios/Runner/GoogleService-Info.plist
signing_details:
  android:
    signing_config:
      store_file_path: android/keystore.jks
  ios:
    signing_config:
      certificate_path: ios/certs/cert.p12
''';

  setUp(() {
    mockFileAccessor = MockFileAccessor();
    mockLogger = MockLogger();
    checkCommand = CheckCommand(
      logger: mockLogger,
      fileAccessor: mockFileAccessor,
    );
  });

  test('Should return success if all configurations match', () async {
    // Mocking the existence of all files
    when(() => mockFileAccessor.existsSync(any())).thenReturn(true);

    final fileContents = {
      'flutter_config.yaml': fileContent,
      'pubspec.yaml': 'name: MyApp\nversion: 1.0.0',
      'android/app/src/main/AndroidManifest.xml':
          '<uses-permission android:name="android.permission.INTERNET"/>\n<application></application>',
      'ios/Runner/Info.plist':
          '<dict><key>NSCameraUsageDescription</key><string>Permission description here</string></dict>'
    };

    when(() => mockFileAccessor.readAsStringSync(any()))
        .thenAnswer((invocation) {
      final path = invocation.positionalArguments[0] as String;
      return fileContents[path] ?? '';
    });

    final result = await checkCommand.run();

    expect(result, equals(ExitCode.success.code));
    verify(() => mockLogger.info('All configurations match successfully!'))
        .called(1);
  });

  test('Should return config error if flutter_config.yaml is missing',
      () async {
    when(() => mockFileAccessor.existsSync('flutter_config.yaml'))
        .thenReturn(false);

    final result = await checkCommand.run();

    expect(result, equals(ExitCode.config.code));
    verify(() => mockLogger.err(
            'flutter_config.yaml does not exist. Please run `flutterconfig init` first.'))
        .called(1);
  });

  test('Should return config error if pubspec.yaml is missing', () async {
    when(() => mockFileAccessor.existsSync('flutter_config.yaml'))
        .thenReturn(true);
    when(() => mockFileAccessor.readAsStringSync('flutter_config.yaml'))
        .thenReturn(mockFlutterConfigContent);
    when(() => mockFileAccessor.existsSync('pubspec.yaml')).thenReturn(false);

    final result = await checkCommand.run();

    expect(result, equals(ExitCode.config.code));
    verify(() => mockLogger.err('pubspec.yaml does not exist.')).called(1);
  });

  test('Should return config error if metadata does not match', () async {
    when(() => mockFileAccessor.existsSync(any())).thenReturn(true);
    when(() => mockFileAccessor.readAsStringSync('flutter_config.yaml'))
        .thenReturn(mockFlutterConfigContent);
    when(() => mockFileAccessor.readAsStringSync('pubspec.yaml'))
        .thenReturn('name: DifferentApp\nversion: 2.0.0');

    final result = await checkCommand.run();

    expect(result, equals(ExitCode.config.code));
    expect(verify(() => mockLogger.err(any())).callCount, greaterThan(1));
  });
}

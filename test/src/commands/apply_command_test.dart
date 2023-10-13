import 'package:flutterconfig_cli/src/commands/commands.dart';
import 'package:flutterconfig_cli/src/utils/file_accessor.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import '../../mocks.dart';

void main() {
  group('ApplyCommand', () {
    late Logger mockLogger;
    late ApplyCommand applyCommand;
    late FileAccessor mockFileAccessor;

    setUp(() {
      mockLogger = MockLogger();
      mockFileAccessor = MockFileAccessor();

      applyCommand = ApplyCommand(
        logger: mockLogger,
        fileAccessor: mockFileAccessor,
      );
    });

    test('Should return error if pubspec.yaml is missing', () async {
      when(() => mockFileAccessor.existsSync('pubspec.yaml')).thenReturn(false);

      final result = await applyCommand.run();

      expect(result, equals(ExitCode.config.code));
      verify(() => mockLogger.err(any())).called(1);
    });

    test('Should return error if android or ios directories are missing',
        () async {
      when(() => mockFileAccessor.existsSync('pubspec.yaml')).thenReturn(true);
      when(() => mockFileAccessor.existsSync('android')).thenReturn(false);
      when(() => mockFileAccessor.existsSync('ios')).thenReturn(true);

      final result = await applyCommand.run();

      expect(result, equals(ExitCode.config.code));
      verify(() => mockLogger.err(any())).called(1);
    });

    test('Should return error if flutter_config.yaml is missing', () async {
      when(() => mockFileAccessor.existsSync('pubspec.yaml')).thenReturn(true);
      when(() => mockFileAccessor.existsSync('android')).thenReturn(true);
      when(() => mockFileAccessor.existsSync('ios')).thenReturn(true);
      when(() => mockFileAccessor.existsSync('flutter_config.yaml'))
          .thenReturn(false);

      final result = await applyCommand.run();

      expect(result, equals(ExitCode.config.code));
      verify(() => mockLogger.err(any())).called(1);
    });

    test('Should apply configurations if everything is in place', () async {
      when(() => mockFileAccessor.existsSync(any())).thenReturn(true);
      // Simulate reading from specific files
      final fileContents = {
        'flutter_config.yaml': fileContent,
        'pubspec.yaml': 'name: OldApp\nversion: 0.0.1',
        'android/app/src/main/AndroidManifest.xml':
            '<application></application>',
        'ios/Runner/Info.plist': '<dict></dict>'
      };

      final capturedLogs = <String>[];
      when(() => mockLogger.info(any())).thenAnswer((invocation) {
        capturedLogs.add(invocation.positionalArguments[0] as String);
        return;
      });

      when(() => mockFileAccessor.readAsStringSync(any()))
          .thenAnswer((invocation) {
        final path = invocation.positionalArguments[0] as String;
        return fileContents[path] ?? '';
      });

      // Capture writes to specific files
      final writtenFiles = <String, String>{};
      when(() => mockFileAccessor.writeAsStringSync(any(), any()))
          .thenAnswer((invocation) {
        final path = invocation.positionalArguments[0] as String;
        final content = invocation.positionalArguments[1] as String;
        writtenFiles[path] = content;
      });

      final result = await applyCommand.run();

      print(capturedLogs);

      expect(result, equals(ExitCode.success.code));
      verify(() => mockLogger.info(any())).called(capturedLogs.length);

      // Verify that the expected files were written
      expect(writtenFiles.keys, contains('pubspec.yaml'));
      expect(writtenFiles.keys,
          contains('android/app/src/main/AndroidManifest.xml'));
      expect(writtenFiles.keys, contains('ios/Runner/Info.plist'));

      // Verify the content written to these files
      expect(writtenFiles['pubspec.yaml'], contains('name: MyApp'));
    });
  });
}

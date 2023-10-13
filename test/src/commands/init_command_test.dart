import 'dart:io';

import 'package:flutterconfig_cli/src/commands/commands.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks.dart';

void main() {
  group('init', () {
    late Logger logger;
    late InitCommand initCommand;

    setUp(() {
      logger = MockLogger();
      initCommand = InitCommand(logger: logger);
    });

    tearDown(() {
      // Clean up created files after each test
      final configFile = File('flutter_config.yaml');
      if (configFile.existsSync()) {
        configFile.deleteSync();
      }
    });

    test('creates flutter_config.yaml with expected content', () async {
      await initCommand.run();

      final configFile = File('flutter_config.yaml');
      expect(configFile.existsSync(), isTrue);

      final content = configFile.readAsStringSync();
      expect(content, contains('name: "MyApp"')); // Add more checks as needed
    });

    test('logs expected message after creation', () async {
      await initCommand.run();

      final configFile = File('flutter_config.yaml');
      verify(() => logger.info(
              'flutter_config.yaml has been created at ${configFile.path}!'))
          .called(1);
    });
  });
}

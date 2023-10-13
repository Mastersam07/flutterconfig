import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

import '../utils/file_accessor.dart';

/// {@template check_command}
///
/// `flutterconfig check`
/// A [Command] to check if the current project setup matches the configurations
/// specified in the `flutter_config.yaml` file.
/// {@endtemplate}
class CheckCommand extends Command<int> {
  /// {@macro check_command}
  CheckCommand({
    required Logger logger,
    required FileAccessor fileAccessor,
  })  : _logger = logger,
        _fileAccessor = fileAccessor;

  @override
  String get description =>
      'Checks if the current project setup matches the configurations in flutter_config.yaml.';

  @override
  String get name => 'check';

  final Logger _logger;
  final FileAccessor _fileAccessor;

  @override
  Future<int> run() async {
    if (!_fileAccessor.existsSync('flutter_config.yaml')) {
      _logger.err(
          'flutter_config.yaml does not exist. Please run `flutterconfig init` first.');
      return ExitCode.config.code;
    }

    final configContent = _fileAccessor.readAsStringSync('flutter_config.yaml');
    final config = loadYaml(configContent) as Map;

    // Check metadata
    if (!_checkMetadata(config['metadata'] as Map<String, dynamic>)) {
      _logger.err('Metadata mismatch detected.');
      return ExitCode.config.code;
    }

    // Check platform-specific configurations
    if (!_checkPlatformSpecificConfig(
        config['platform_specific'] as Map<String, dynamic>)) {
      _logger.err('Platform-specific configuration mismatch detected.');
      return ExitCode.config.code;
    }

    // Check visual assets
    if (!_checkVisualAssets(config['visual_assets'] as Map<String, dynamic>)) {
      _logger.err('Visual assets mismatch detected.');
      return ExitCode.config.code;
    }

    // Check integrations
    if (!_checkIntegrations(config['integrations'] as Map<String, dynamic>)) {
      _logger.err('Integrations mismatch detected.');
      return ExitCode.config.code;
    }

    // Check signing details
    if (!_checkSigningDetails(
        config['signing_details'] as Map<String, dynamic>)) {
      _logger.err('Signing details mismatch detected.');
      return ExitCode.config.code;
    }

    _logger.info('All configurations match successfully!');
    return ExitCode.success.code;
  }

  bool _checkMetadata(Map<String, dynamic> metadata) {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      _logger.err('pubspec.yaml does not exist.');
      return false;
    }

    var content = pubspecFile.readAsStringSync();

    // Check app name, version, etc.
    if (!content.contains('name: ${metadata['name']}')) {
      return false;
    }
    if (!content.contains('version: ${metadata['version']}')) {
      return false;
    }

    // ... Add other metadata checks as needed ...

    return true;
  }

  bool _checkPlatformSpecificConfig(Map<String, dynamic> platformConfig) {
    // For Android
    final androidManifestFile = 'android/app/src/main/AndroidManifest.xml';
    if (!_fileAccessor.existsSync(androidManifestFile)) {
      _logger.err('Missing AndroidManifest.xml.');
      return false;
    }

    // Check Android permissions
    final androidPermissions = platformConfig['android']['permissions'] as List;
    final androidManifestContent =
        _fileAccessor.readAsStringSync(androidManifestFile);
    for (var permission in androidPermissions) {
      if (!androidManifestContent.contains(permission)) {
        _logger.err('Missing Android permission: $permission');
        return false;
      }
    }

    // For iOS
    final infoPlistFile = 'ios/Runner/Info.plist';
    if (!_fileAccessor.existsSync(infoPlistFile)) {
      _logger.err('Missing Info.plist for iOS.');
      return false;
    }

    // Check iOS permissions
    final iosPermissions = platformConfig['ios']['permissions'] as List;
    final infoPlistContent = _fileAccessor.readAsStringSync(infoPlistFile);
    for (var permission in iosPermissions) {
      if (!infoPlistContent.contains(permission)) {
        _logger.err('Missing iOS permission: $permission');
        return false;
      }
    }

    return true;
  }

  bool _checkVisualAssets(Map<String, dynamic> visualAssets) {
    // For this example, we'll just check if the files exist.
    for (var assetType in visualAssets.keys) {
      final assets = visualAssets[assetType] as Map;
      for (var asset in assets.keys) {
        if (!_fileAccessor.existsSync(assets[asset])) {
          _logger.err('Missing asset: ${assets[asset]}');
          return false;
        }
      }
    }
    return true;
  }

  bool _checkIntegrations(Map<String, dynamic> integrations) {
    // For this example, we'll just check if the specified files for integrations exist.
    for (var integration in integrations.keys) {
      final configPaths = integrations[integration] as Map;
      for (var config in configPaths.keys) {
        if (!_fileAccessor.existsSync(configPaths[config])) {
          _logger.err('Missing integration config: ${configPaths[config]}');
          return false;
        }
      }
    }
    return true;
  }

  bool _checkSigningDetails(Map<String, dynamic> signingDetails) {
    // For this example, we'll just check if the specified files for signing exist.
    for (var platform in signingDetails.keys) {
      final configPaths = signingDetails[platform] as Map;
      for (var config in configPaths.keys) {
        if (config == 'signing_config' ||
            config == 'push_notification_config') {
          final details = configPaths[config] as Map;
          for (var detail in details.keys) {
            if (detail.endsWith('_path') &&
                !_fileAccessor.existsSync(details[detail])) {
              _logger.err('Missing signing detail: ${details[detail]}');
              return false;
            }
          }
        }
      }
    }
    return true;
  }
}

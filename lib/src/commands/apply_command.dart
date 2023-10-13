import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

import '../utils/file_accessor.dart';

/// {@template apply_command}
///
/// `flutterconfig apply`
/// A [Command] to apply the configurations from `flutter_config.yaml`
/// {@endtemplate}
class ApplyCommand extends Command<int> {
  /// {@macro apply_command}
  ApplyCommand({
    required Logger logger,
    required FileAccessor fileAccessor,
  })  : _logger = logger,
        _fileAccessor = fileAccessor;

  @override
  String get description =>
      'Applies the configurations from flutter_config.yaml to the Flutter project.';

  @override
  String get name => 'apply';

  final Logger _logger;
  final FileAccessor _fileAccessor;

  @override
  Future<int> run() async {
    // Check if it's a Flutter project by looking for the pubspec.yaml file
    if (!_fileAccessor.existsSync('pubspec.yaml')) {
      _logger.err(
          'This does not seem to be a Flutter project. pubspec.yaml is missing.');
      return ExitCode.config.code;
    }

    // Check for the android and ios directories
    if (!_fileAccessor.existsSync('android') ||
        !_fileAccessor.existsSync('ios')) {
      _logger.err(
          'This Flutter project seems to be missing either the android or ios directories.');
      return ExitCode.config.code;
    }

    if (!_fileAccessor.existsSync('flutter_config.yaml')) {
      _logger.err(
          'flutter_config.yaml does not exist. Please run `flutterconfig init` first.');
      return ExitCode.config.code;
    }

    final configContent = _fileAccessor.readAsStringSync('flutter_config.yaml');
    final configYaml = loadYaml(configContent);
    final Map<String, dynamic> config = Map<String, dynamic>.from(configYaml);

    // Apply metadata
    _applyMetadata(Map<String, dynamic>.from(config['metadata']));

    // Apply platform-specific configurations
    _applyPlatformSpecificConfig(
        Map<String, dynamic>.from(config['platform_specific']));

    // Apply visual assets
    _applyVisualAssets(Map<String, dynamic>.from(config['visual_assets']));

    // Apply integrations
    _applyIntegrations(Map<String, dynamic>.from(config['integrations']));

    // Apply signing details
    _applySigningDetails(Map<String, dynamic>.from(config['signing_details']));

    _logger.info('Configurations have been applied successfully!');
    return ExitCode.success.code;
  }

  void _applyMetadata(Map<String, dynamic> metadata) {
    if (!_fileAccessor.existsSync('pubspec.yaml')) {
      _logger.err('pubspec.yaml does not exist.');
      return;
    }

    var content = _fileAccessor.readAsStringSync('pubspec.yaml');

    // Update app name, version, etc.
    content =
        content.replaceAll(RegExp(r'name: \w+'), 'name: ${metadata['name']}');
    content = content.replaceAll(
        RegExp(r'version: \d+\.\d+\.\d+'), 'version: ${metadata['version']}');

    _fileAccessor.writeAsStringSync('pubspec.yaml', content);
    _logger.info('Metadata applied successfully.');
  }

  void _applyPlatformSpecificConfig(Map<String, dynamic> platformConfig) {
    // For Android
    if (_fileAccessor.existsSync('android/app/src/main/AndroidManifest.xml')) {
      var content = _fileAccessor
          .readAsStringSync('android/app/src/main/AndroidManifest.xml');

      // Update permissions
      final permissions = platformConfig['android']['permissions'] as List;
      for (var permission in permissions) {
        if (!content.contains(permission)) {
          content = content.replaceFirst('<application',
              '<uses-permission android:name="$permission"/>\n<application');
        }
      }

      _fileAccessor.writeAsStringSync(
          'android/app/src/main/AndroidManifest.xml', content);
    }

    // For iOS
    if (_fileAccessor.existsSync('ios/Runner/Info.plist')) {
      var content = _fileAccessor.readAsStringSync('ios/Runner/Info.plist');

      // Update permissions
      final permissions = platformConfig['ios']['permissions'] as List;
      for (var permission in permissions) {
        if (!content.contains(permission)) {
          content = content.replaceFirst('</dict>',
              '  <key>$permission</key>\n  <string>Permission description here</string>\n</dict>');
        }
      }

      _fileAccessor.writeAsStringSync('ios/Runner/Info.plist', content);
    }

    _logger.info('Platform-specific configurations applied successfully.');
  }

  void _applyVisualAssets(Map<String, dynamic> visualAssets) {
    // TODO:
    _logger.info('Visual assets paths:');
    // for (var assetType in visualAssets.keys) {
    //   final assets = visualAssets[assetType] as Map;
    //   for (var asset in assets.keys) {
    //     _logger.info('$assetType - $asset: ${assets[asset]}');
    //   }
    // }
  }

  void _applyIntegrations(Map<String, dynamic> integrations) {
    // TODO:
    _logger.info('Integrations:');
    // for (var integration in integrations.keys) {
    //   _logger.info('$integration: ${integrations[integration]}');
    // }
  }

  void _applySigningDetails(Map<String, dynamic> signingDetails) {
    // TODO:
    _logger.info('Signing details:');
    // for (var platform in signingDetails.keys) {
    //   _logger.info('$platform: ${signingDetails[platform]}');
    // }
  }
}

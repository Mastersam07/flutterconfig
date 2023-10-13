import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// {@template apply_command}
///
/// `flutterconfig apply`
/// A [Command] to apply the configurations from `flutter_config.yaml`
/// {@endtemplate}
class ApplyCommand extends Command<int> {
  /// {@macro apply_command}
  ApplyCommand({
    required Logger logger,
  }) : _logger = logger;

  @override
  String get description =>
      'Applies the configurations from flutter_config.yaml to the Flutter project.';

  @override
  String get name => 'apply';

  final Logger _logger;

  @override
  Future<int> run() async {
    // Check if it's a Flutter project by looking for the pubspec.yaml file
    if (!File('pubspec.yaml').existsSync()) {
      _logger.err(
          'This does not seem to be a Flutter project. pubspec.yaml is missing.');
      return ExitCode.config.code;
    }

    // Check for the android and ios directories
    if (!File('android').existsSync() || !File('ios').existsSync()) {
      _logger.err(
          'This Flutter project seems to be missing either the android or ios directories.');
      return ExitCode.config.code;
    }

    if (!File('flutter_config.yaml').existsSync()) {
      _logger.err(
          'flutter_config.yaml does not exist. Please run `flutterconfig init` first.');
      return ExitCode.config.code;
    }

    final configContent = File('flutter_config.yaml').readAsStringSync();
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
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      _logger.err('pubspec.yaml does not exist.');
      return;
    }

    var content = pubspecFile.readAsStringSync();

    // Update app name, version, etc.
    content =
        content.replaceAll(RegExp(r'name: \w+'), 'name: ${metadata['name']}');
    content = content.replaceAll(
        RegExp(r'version: \d+\.\d+\.\d+'), 'version: ${metadata['version']}');

    pubspecFile.writeAsStringSync(content);
    _logger.info('Metadata applied successfully.');
  }

  void _applyPlatformSpecificConfig(Map<String, dynamic> platformConfig) {
    // For Android
    final androidManifestFile =
        File('android/app/src/main/AndroidManifest.xml');
    if (androidManifestFile.existsSync()) {
      var content = androidManifestFile.readAsStringSync();

      // Update permissions
      final permissions = platformConfig['android']['permissions'] as List;
      for (var permission in permissions) {
        if (!content.contains(permission)) {
          content = content.replaceFirst('<application',
              '<uses-permission android:name="$permission"/>\n<application');
        }
      }

      androidManifestFile.writeAsStringSync(content);
    }

    // For iOS
    final infoPlistFile = File('ios/Runner/Info.plist');
    if (infoPlistFile.existsSync()) {
      var content = infoPlistFile.readAsStringSync();

      // Update permissions
      final permissions = platformConfig['ios']['permissions'] as List;
      for (var permission in permissions) {
        if (!content.contains(permission)) {
          content = content.replaceFirst('</dict>',
              '  <key>$permission</key>\n  <string>Permission description here</string>\n</dict>');
        }
      }

      infoPlistFile.writeAsStringSync(content);
    }

    _logger.info('Platform-specific configurations applied successfully.');
  }

  void _applyVisualAssets(Map<String, dynamic> visualAssets) {
    // We'll just log the paths.
    // You should copy these assets to the respective directories.
    _logger.info('Visual assets paths:');
    for (var assetType in visualAssets.keys) {
      final assets = visualAssets[assetType] as Map;
      for (var asset in assets.keys) {
        _logger.info('$assetType - $asset: ${assets[asset]}');
      }
    }
  }

  void _applyIntegrations(Map<String, dynamic> integrations) {
    // We'll just log the paths.
    // You should copy these assets to the respective directories.
    _logger.info('Integrations:');
    for (var integration in integrations.keys) {
      _logger.info('$integration: ${integrations[integration]}');
    }
  }

  void _applySigningDetails(Map<String, dynamic> signingDetails) {
    // We'll just log the paths.
    // You should copy these assets to the respective directories.
    _logger.info('Signing details:');
    for (var platform in signingDetails.keys) {
      _logger.info('$platform: ${signingDetails[platform]}');
    }
  }
}

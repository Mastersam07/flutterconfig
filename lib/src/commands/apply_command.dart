import 'dart:io';

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
    if (!_fileAccessor.directoryExistsSync('android') ||
        !_fileAccessor.directoryExistsSync('ios')) {
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

    // Update app name
    content = content.replaceAllMapped(
      RegExp(r'name: \w+'),
      (match) => 'name: ${_toCamelCase(metadata['name'])}',
    );

    // Update app description
    // Update description if provided
    final description = metadata['description'];
    if (description != null) {
      final descriptionRegex = RegExp(r'description: [^\n]+');
      if (descriptionRegex.hasMatch(content)) {
        content =
            content.replaceAll(descriptionRegex, 'description: $description');
      } // No need for an else block since we're maintaining the existing description if not found.
    }

    // Extract the existing version and build number
    var existingVersionMatch =
        RegExp(r'version: (\d+\.\d+\.\d+)\+(\d+)').firstMatch(content);
    var existingVersion = existingVersionMatch?.group(1) ?? '1.0.0';
    var existingBuildNumber = existingVersionMatch?.group(2) ?? '1';

    // Use the version and build number from metadata if available, otherwise use the existing values
    var newVersion = metadata['version'] ?? existingVersion;
    var newBuildNumber =
        metadata['build_number']?.toString() ?? existingBuildNumber;

    content = content.replaceAll(
      RegExp(r'version: \d+\.\d+\.\d+\+\d+'),
      'version: $newVersion+$newBuildNumber',
    );

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

      // Update label
      final androidLabel = platformConfig['android']['label'];
      if (androidLabel != null) {
        final labelRegex = RegExp(r'android:label="[^"]+"');
        if (labelRegex.hasMatch(content)) {
          content =
              content.replaceAll(labelRegex, 'android:label="$androidLabel"');
        } else {
          content = content.replaceFirst(
              '<application', '<application android:label="$androidLabel"');
        }
      }

      _fileAccessor.writeAsStringSync(
          'android/app/src/main/AndroidManifest.xml', content);
    }

    final androidPackageName = platformConfig['android']['package_name'];
    if (androidPackageName != null) {
      // Update android/app/build.gradle
      final gradlePath = 'android/app/build.gradle';
      if (_fileAccessor.existsSync(gradlePath)) {
        var gradleContent = _fileAccessor.readAsStringSync(gradlePath);

        var oldGradleContent = gradleContent;

        // Update application id
        // final applicationIdRegex = RegExp(r'applicationId "[^"]+"');
        final applicationIdRegex = RegExp(r'applicationId\s+"([^"]+)"');
        if (applicationIdRegex.hasMatch(gradleContent)) {
          gradleContent = gradleContent.replaceAll(
              applicationIdRegex, 'applicationId "$androidPackageName"');
          _fileAccessor.writeAsStringSync(gradlePath, gradleContent);
        }

        // Update namespace
        final namespaceRegex = RegExp(r'namespace\s+"([^"]+)"');
        if (namespaceRegex.hasMatch(gradleContent)) {
          gradleContent = gradleContent.replaceAll(
              namespaceRegex, 'namespace "$androidPackageName"');
          _fileAccessor.writeAsStringSync(gradlePath, gradleContent);
        }

        final androidMinSdkVersion =
            platformConfig['android']['min_sdk_version'];
        final androidTargetSdkVersion =
            platformConfig['android']['target_sdk_version'];

        // Update minSdkVersion if provided
        if (androidMinSdkVersion != null) {
          final minSdkVersionRegex = RegExp(r'minSdkVersion\s+([^\s]+)');
          if (minSdkVersionRegex.hasMatch(gradleContent)) {
            gradleContent = gradleContent.replaceAll(
                minSdkVersionRegex, 'minSdkVersion $androidMinSdkVersion');
            _fileAccessor.writeAsStringSync(gradlePath, gradleContent);
          } else {
            // If for some reason the minSdkVersion is not found, you can decide to add it or log an error.
            _logger.err('minSdkVersion not found in build.gradle');
          }
        }

        // Update targetSdkVersion if provided
        if (androidTargetSdkVersion != null) {
          final targetSdkVersionRegex = RegExp(r'targetSdkVersion\s+([^\s]+)');
          if (targetSdkVersionRegex.hasMatch(gradleContent)) {
            gradleContent = gradleContent.replaceAll(targetSdkVersionRegex,
                'targetSdkVersion $androidTargetSdkVersion');
            _fileAccessor.writeAsStringSync(gradlePath, gradleContent);
          } else {
            // If for some reason the targetSdkVersion is not found, you can decide to add it or log an error.
            _logger.err('targetSdkVersion not found in build.gradle');
          }
        }

        // Update compileSdkVersion if provided
        if (androidTargetSdkVersion != null) {
          final compileSdkVersionRegex =
              RegExp(r'compileSdkVersion\s+([^\s]+)');
          if (compileSdkVersionRegex.hasMatch(gradleContent)) {
            gradleContent = gradleContent.replaceAll(compileSdkVersionRegex,
                'compileSdkVersion $androidTargetSdkVersion');
            _fileAccessor.writeAsStringSync(gradlePath, gradleContent);
          } else {
            // If for some reason the targetSdkVersion is not found, you can decide to add it or log an error.
            _logger.err('targetSdkVersion not found in build.gradle');
          }
        }

        final match = applicationIdRegex.firstMatch(oldGradleContent);
        if (match != null) {
          final oldPackageName = match.group(1);
          final oldPackagePath = oldPackageName!.replaceAll('.', '/');
          final newPackageName = platformConfig['android']['package_name'];
          final newPackagePath = newPackageName.replaceAll('.', '/');

          final mainActivityPath =
              'android/app/src/main/kotlin/$oldPackagePath/MainActivity.kt';
          if (_fileAccessor.existsSync(mainActivityPath)) {
            var mainActivityContent =
                _fileAccessor.readAsStringSync(mainActivityPath);
            final packageRegex = RegExp(r'^package [^\n]+', multiLine: true);
            if (packageRegex.hasMatch(mainActivityContent)) {
              mainActivityContent = mainActivityContent.replaceAll(
                  packageRegex, 'package $newPackageName');
              _fileAccessor.writeAsStringSync(
                  mainActivityPath, mainActivityContent);
              var currentDirectory = Directory.current.path;
              final oldDirectoryPath =
                  "$currentDirectory/android/app/src/main/kotlin/$oldPackagePath";
              final newDirectoryPath =
                  "$currentDirectory/android/app/src/main/kotlin/$newPackagePath";

              if (_fileAccessor.directoryExistsSync(oldDirectoryPath)) {
                if (!_fileAccessor.directoryExistsSync(newDirectoryPath)) {
                  try {
                    _fileAccessor.renameDirectoryWithCopy(
                        oldDirectoryPath, newDirectoryPath);
                  } catch (e) {
                    _logger.err('Failed to rename directory: $e');
                  }
                } else {
                  _logger.info(
                      'Target directory already exists: $newDirectoryPath');
                }
              } else {
                _logger
                    .err('Source directory does not exist: $oldDirectoryPath');
              }
            }
          }

          // Update references in the code
          final files = _fileAccessor.listSync(
              "android/app/src/main/kotlin/$newPackageName",
              recursive: true);
          for (final file in files) {
            if (file is File && file.path.endsWith('.kt')) {
              var content = file.readAsStringSync();
              content = content.replaceAll(oldPackageName, newPackageName);
              file.writeAsStringSync(content);
            }
          }
        }
      }

      // Update MainActivity.kt
      final mainActivityPath =
          'android/app/src/main/kotlin/com/example/myapp/MainActivity.kt';
      if (_fileAccessor.existsSync(mainActivityPath)) {
        var mainActivityContent =
            _fileAccessor.readAsStringSync(mainActivityPath);
        final packageRegex = RegExp(r'^package [^\n]+', multiLine: true);
        if (packageRegex.hasMatch(mainActivityContent)) {
          mainActivityContent = mainActivityContent.replaceAll(
              packageRegex, 'package $androidPackageName');
          _fileAccessor.writeAsStringSync(
              mainActivityPath, mainActivityContent);
        }
      }
    }

    // For iOS
    if (_fileAccessor.existsSync('ios/Runner/Info.plist')) {
      var content = _fileAccessor.readAsStringSync('ios/Runner/Info.plist');

      // Update permissions
      final permissions = platformConfig['ios']['permissions'] as List;
      for (var permission in permissions) {
        final permissionPattern = RegExp('<key>$permission</key>');
        if (!permissionPattern.hasMatch(content)) {
          content = content.replaceFirst('</dict>',
              '  <key>$permission</key>\n  <string>Permission description here</string>\n</dict>');
        }
      }

      // Update CFBundleDisplayName
      final iosLabel = platformConfig['ios']['label'];
      if (iosLabel != null) {
        final labelRegex =
            RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]+</string>');
        if (labelRegex.hasMatch(content)) {
          content = content.replaceAll(labelRegex,
              '<key>CFBundleDisplayName</key>\n\t<string>$iosLabel</string>');
        } else {
          content = content.replaceFirst('</dict>',
              '  <key>CFBundleDisplayName</key>\n\t<string>$iosLabel</string>\n</dict>');
        }
      }

      // Update CFBundleIdentifier
      final iosBundleId = platformConfig['ios']['bundle_id'];
      if (iosBundleId != null) {
        final bundleIdRegex =
            RegExp(r'<key>CFBundleIdentifier</key>\s*<string>[^<]+</string>');
        if (bundleIdRegex.hasMatch(content)) {
          content = content.replaceAll(bundleIdRegex,
              '<key>CFBundleIdentifier</key>\n\t<string>$iosBundleId</string>');
        } else {
          content = content.replaceFirst('</dict>',
              '  <key>CFBundleIdentifier</key>\n\t<string>$iosBundleId</string>\n</dict>');
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

String _toCamelCase(String text) {
  List<String> words = text.split(RegExp(r'[_\s]'));
  String firstWord = words.first.toLowerCase();
  String remainingWords = words.skip(1).map((word) {
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join('');
  return firstWord + remainingWords;
}

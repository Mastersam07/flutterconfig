import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template init_command}
///
/// `flutterconfig init`
/// A [Command] to init configurations to a `flutter_config.yaml`
/// {@endtemplate}
class InitCommand extends Command<int> {
  /// {@macro sample_command}
  InitCommand({
    required Logger logger,
  }) : _logger = logger;

  @override
  String get description =>
      'Generates a sample flutter_config.yaml file with default values or placeholders.';

  @override
  String get name => 'init';

  final Logger _logger;

  @override
  Future<int> run() async {
    final configContent = '''
metadata:
  name: "MyApp"
  display_name: "My Application"
  description: "This is a sample application."
  version: "1.0.0"
  build_number: "1"

platform_specific:
  android:
    package_name: "com.example.myapp"
    label: "MyApp"
    min_sdk_version: 21
    target_sdk_version: 30
    permissions:
      - "android.permission.INTERNET"
    google_services_json: "path/to/google-services.json"
    signing_config:
      key_alias: "mykeyalias"
      key_password: "keypassword"
      key_store_path: "path/to/keystore.jks"
      key_store_password: "keystorepassword"
    
  ios:
    bundle_id: "com.example.myapp"
    label: "MyApp"
    permissions:
      - "NSCameraUsageDescription"
    device_orientation:
      - "portrait"
      - "landscape"
    push_notification_config:
      certificate_path: "path/to/certificate.p12"
      certificate_password: "certpassword"

visual_assets:
  icons:
    # Android icons
    android_mdpi: "path/to/android_mdpi_icon.png"
    android_hdpi: "path/to/android_hdpi_icon.png"
    android_xhdpi: "path/to/android_xhdpi_icon.png"
    android_xxhdpi: "path/to/android_xxhdpi_icon.png"
    android_xxxhdpi: "path/to/android_xxxhdpi_icon.png"
    
    # iOS icons
    ios_1x: "path/to/ios_1x_icon.png"
    ios_2x: "path/to/ios_2x_icon.png"
    ios_3x: "path/to/ios_3x_icon.png"
  
  splash_screens:
    # This generates native code to customize Flutter's default white native splash screen
    # with background color and splash image.
    # Customize the parameters below

    # color or background_image is the only required parameter.  Use color to set the background
    # of your splash screen to a solid color.  Use background_image to set the background of your
    # splash screen to a png image.  This is useful for gradients. The image will be stretch to the
    # size of the app. Only one parameter can be used, color and background_image cannot both be set.
    color: "#42a5f5"
    #background_image: "assets/background.png"

    # Optional parameters are listed below.  To enable a parameter, uncomment the line by removing
    # the leading # character.

    # The image parameter allows you to specify an image used in the splash screen.  It must be a
    # png file and should be sized for 4x pixel density.
    #image: assets/splash.png
  
  store_images:
    # Android store images
    android_screenshot1: "path/to/android_screenshot1.png"
    android_screenshot2: "path/to/android_screenshot2.png"
    android_feature_graphic: "path/to/android_feature_graphic.png"
    
    # iOS store images
    ios_screenshot1: "path/to/ios_screenshot1.png"
    ios_screenshot2: "path/to/ios_screenshot2.png"

integrations:
  firebase:
    android_config_path: "path/to/android_firebase_config.json"
    ios_config_path: "path/to/ios_firebase_config.plist"
  analytics_tool:
    api_key: "your_analytics_api_key"
    other_config: "other_config_value"

signing_details:
  android:
    signing_config:
      key_alias: "mykeyalias"
      key_password: "keypassword"
      key_store_path: "path/to/keystore.jks"
      key_store_password: "keystorepassword"
  ios:
    push_notification_config:
      certificate_path: "path/to/certificate.p12"
      certificate_password: "certpassword"
''';

    final configFile = File('flutter_config.yaml');
    configFile.writeAsStringSync(configContent);
    _logger.info('flutter_config.yaml has been created at ${configFile.path}!');
    return ExitCode.success.code;
  }
}

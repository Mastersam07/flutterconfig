import 'package:flutterconfig_cli/src/utils/file_accessor.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';

final fileContent = '''
metadata:
  name: "MyApp"
  display_name: "My Application"
  description: "This is a sample application."
  version: "1.0.0"
  build_number: "1"

platform_specific:
  android:
    package_name: "com.example.myapp"
    min_sdk_version: 21
    target_sdk_version: 30
    permissions:
      - "CAMERA"
      - "LOCATION"
      - "MICROPHONE"
    google_services_json: "path/to/google-services.json"
    signing_config:
      key_alias: "mykeyalias"
      key_password: "keypassword"
      key_store_path: "path/to/keystore.jks"
      key_store_password: "keystorepassword"
    
  ios:
    bundle_id: "com.example.myapp"
    permissions:
      - "CAMERA"
      - "LOCATION"
      - "MICROPHONE"
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
    # Android splash screens
    android_mdpi: "path/to/android_mdpi_splash.png"
    android_hdpi: "path/to/android_hdpi_splash.png"
    android_xhdpi: "path/to/android_xhdpi_splash.png"
    android_xxhdpi: "path/to/android_xxhdpi_splash.png"
    android_xxxhdpi: "path/to/android_xxxhdpi_splash.png"
    
    # iOS splash screens
    ios_1x: "path/to/ios_1x_splash.png"
    ios_2x: "path/to/ios_2x_splash.png"
    ios_3x: "path/to/ios_3x_splash.png"
  
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

class MockLogger extends Mock implements Logger {}

class MockFileAccessor extends Mock implements FileAccessor {}

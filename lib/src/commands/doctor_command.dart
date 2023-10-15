import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../utils/file_accessor.dart';

/// {@template doctor_command}
///
/// `flutterconfig doctor`
/// A [Command] to diagnose and check for any issues with the current configuration
/// and project setup.
/// {@endtemplate}
class DoctorCommand extends Command<int> {
  /// {@macro doctor_command}
  DoctorCommand({
    required Logger logger,
    required FileAccessor fileAccessor,
  })  : _logger = logger,
        _fileAccessor = fileAccessor;

  @override
  String get description =>
      'Diagnoses and checks for any issues with the current configuration and project setup.';

  @override
  String get name => 'doctor';

  final Logger _logger;
  final FileAccessor _fileAccessor;

  @override
  Future<int> run() async {
    _logger.info('Running flutterconfig doctor...');

    // Check if flutter_config.yaml exists
    if (!_fileAccessor.existsSync('flutter_config.yaml')) {
      _logger.err('flutter_config.yaml does not exist.');
      return ExitCode.config.code;
    }

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

    _logger.info('No issues found! Everything looks good.');
    return ExitCode.success.code;
  }
}

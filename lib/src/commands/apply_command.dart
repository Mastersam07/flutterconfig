import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template sample_command}
///
/// `flutterconfig sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class ApplyCommand extends Command<int> {
  /// {@macro sample_command}
  ApplyCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'cyan',
      abbr: 'c',
      help: 'Prints the same joke, but in cyan',
      negatable: false,
    );
  }

  @override
  String get description =>
      'Applies the configurations from flutter_config.yaml to the Flutter project.';

  @override
  String get name => 'apply';

  final Logger _logger;

  @override
  Future<int> run() async {
    var output = 'Which unicorn has a cold? The Achoo-nicorn!';
    if (argResults?['cyan'] == true) {
      output = lightCyan.wrap(output)!;
    }
    _logger.info(output);
    return ExitCode.success.code;
  }
}

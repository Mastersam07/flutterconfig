import 'dart:io';

abstract class FileAccessor {
  bool existsSync(String path);
  String readAsStringSync(String path);
  void writeAsStringSync(String path, String content);
}

class RealFileAccessor implements FileAccessor {
  @override
  bool existsSync(String path) => File(path).existsSync();

  @override
  String readAsStringSync(String path) => File(path).readAsStringSync();

  @override
  void writeAsStringSync(String path, String content) {
    File(path).writeAsStringSync(content);
  }
}

import 'dart:io';

abstract class FileAccessor {
  bool existsSync(String path);
  bool directoryExistsSync(String path);
  String readAsStringSync(String path);
  void writeAsStringSync(String path, String content);
  void renameSync(String oldPath, String newPath);
  List<FileSystemEntity> listSync(String path, {bool recursive = false});
  void renameDirectoryWithCopy(String oldPath, String newPath);
  void deleteSync(String path);
  void copyFromDirectory(String oldPath, String newPath);
  void deleteDirectory(String path);
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

  @override
  bool directoryExistsSync(String path) {
    final directory = Directory(path);
    return directory.existsSync();
  }

  @override
  void renameSync(String oldPath, String newPath) {
    final oldDirectory = Directory(oldPath);
    if (oldDirectory.existsSync()) {
      oldDirectory.renameSync(newPath);
    }
  }

  @override
  List<FileSystemEntity> listSync(String path, {bool recursive = false}) {
    final directory = Directory(path);
    if (directory.existsSync()) {
      return directory.listSync(recursive: recursive);
    }
    return [];
  }

  @override
  void deleteSync(String path) {
    File(path).deleteSync();
  }

  @override
  void renameDirectoryWithCopy(String oldPath, String newPath) {
    // 1. Create the new directory
    final newDir = Directory(newPath);
    if (!newDir.existsSync()) {
      newDir.createSync(recursive: true);
    }

    // 2. Copy all contents from the old directory to the new directory
    final oldDir = Directory(oldPath);
    for (var entity in oldDir.listSync(recursive: false)) {
      if (entity is File) {
        final newPathForFile = entity.path.replaceFirst(oldPath, newPath);
        entity.copySync(newPathForFile);
      } else if (entity is Directory) {
        final newPathForDir = entity.path.replaceFirst(oldPath, newPath);
        renameDirectoryWithCopy(entity.path, newPathForDir);
      }
    }

    // 3. Delete the old directory
    oldDir.deleteSync(recursive: true);
  }

  @override
  void deleteDirectory(String path) {
    final oldDir = Directory(path);
    oldDir.deleteSync(recursive: true);
  }

  @override
  void copyFromDirectory(String oldPath, String newPath) {
    // Copy all contents from the old directory to the new directory
    final oldDir = Directory(oldPath);
    for (var entity in oldDir.listSync(recursive: false)) {
      if (entity is File) {
        final newPathForFile = entity.path.replaceFirst(oldPath, newPath);
        entity.copySync(newPathForFile);
      } else if (entity is Directory) {
        final newPathForDir = entity.path.replaceFirst(oldPath, newPath);
        renameDirectoryWithCopy(entity.path, newPathForDir);
      }
    }
  }
}

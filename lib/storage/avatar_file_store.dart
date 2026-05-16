import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AvatarFileStore {
  const AvatarFileStore._();

  static const String managedDirectoryName = 'profile_assets';

  static Future<Directory> managedDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDirectory.path, managedDirectoryName));
  }

  static Future<String> storablePathFor(String avatarPath) async {
    final trimmedPath = avatarPath.trim();
    if (trimmedPath.isEmpty) {
      return '';
    }

    final appDirectory = await getApplicationDocumentsDirectory();
    final normalizedAvatarPath = p.normalize(trimmedPath);
    final normalizedAppPath = p.normalize(appDirectory.path);

    if (p.equals(normalizedAvatarPath, normalizedAppPath) ||
        p.isWithin(normalizedAppPath, normalizedAvatarPath)) {
      return p.relative(normalizedAvatarPath, from: normalizedAppPath);
    }

    return trimmedPath;
  }

  static Future<String?> resolveStoredPath(String? storedPath) async {
    final trimmedPath = storedPath?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return null;
    }

    final appDirectory = await getApplicationDocumentsDirectory();
    final candidatePath = p.isAbsolute(trimmedPath)
        ? trimmedPath
        : p.join(appDirectory.path, trimmedPath);
    if (await File(candidatePath).exists()) {
      return candidatePath;
    }

    final recoveredPath = _recoverManagedPath(
      storedPath: trimmedPath,
      appDirectoryPath: appDirectory.path,
    );
    if (recoveredPath != null && await File(recoveredPath).exists()) {
      return recoveredPath;
    }

    return candidatePath;
  }

  static String? _recoverManagedPath({
    required String storedPath,
    required String appDirectoryPath,
  }) {
    final parts = p.split(storedPath);
    final managedDirectoryIndex = parts.lastIndexOf(managedDirectoryName);
    if (managedDirectoryIndex < 0 ||
        managedDirectoryIndex == parts.length - 1) {
      return null;
    }

    return p.join(
      appDirectoryPath,
      p.joinAll(parts.sublist(managedDirectoryIndex)),
    );
  }
}

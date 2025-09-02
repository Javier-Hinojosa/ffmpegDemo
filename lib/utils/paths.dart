import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> getDownloadsPath() async {
  try {
    if (Platform.isAndroid) {
      for (final p in ['/storage/emulated/0/Download', '/sdcard/Download']) {
        final d = Directory(p);
        if (await d.exists()) return d.path;
      }
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext.path;
    } else if (Platform.isMacOS || Platform.isWindows) {
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir.path;
    } else if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      final d = Directory('${docs.path}/Downloads');
      await d.create(recursive: true);
      return d.path;
    }
  } catch (_) {}
  final docs = await getApplicationDocumentsDirectory();
  return docs.path;
}

Future<String> uniquePath(String dir, String baseName) async {
  String candidate = '$dir/$baseName';
  if (!await File(candidate).exists()) return candidate;
  final dot = baseName.lastIndexOf('.');
  final name = dot > 0 ? baseName.substring(0, dot) : baseName;
  final ext = dot > 0 ? baseName.substring(dot) : '';
  int i = 1;
  while (await File('$dir/${name}_$i$ext').exists()) {
    i++;
  }
  return '$dir/${name}_$i$ext';
}


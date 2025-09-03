import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  if (await Permission.accessMediaLocation.isDenied) {
    // Si todos los permisos están denegados, solicitar el permiso de almacenamiento primero
    await Permission.storage.request();
  }
  // Android 13+ separa los permisos de media
  if (await Permission.videos.isDenied) {
    await Permission.videos.request();
  }
  if (await Permission.photos.isDenied) {
    await Permission.photos.request();
  }

  // Permiso general de almacenamiento (para compatibilidad con Android < 13)
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
}
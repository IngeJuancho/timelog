import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdateInfo {
  final bool isUpdateAvailable;
  final String latestVersion;
  final String releaseUrl;

  UpdateInfo({
    required this.isUpdateAvailable,
    required this.latestVersion,
    required this.releaseUrl,
  });
}

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  } catch (_) {
    return '4.0.0';
  }
});

final updateProvider = FutureProvider<UpdateInfo?>((ref) async {
  try {
    // 1. Obtener versión local
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersionStr = packageInfo.version; // Ej: "4.0.0"
    
    // 2. Obtener versión remota desde GitHub (con fallback onTimeout para no lanzar TimeoutException)
    final response = await http
        .get(
          Uri.parse('https://api.github.com/repos/IngeJuancho/timelog/releases/latest'),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        )
        .timeout(
          const Duration(seconds: 4),
          onTimeout: () => http.Response('{}', 408),
        );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final remoteVersionStr = data['tag_name'] as String; // Ej: "v4.0.1" o "4.0.1"
      final releaseUrl = data['html_url'] as String;

      // Limpiar "v" si existe
      final cleanRemoteVersion = remoteVersionStr.startsWith('v') 
          ? remoteVersionStr.substring(1) 
          : remoteVersionStr;

      // 3. Comparar versiones
      // Una lógica de comparación simple asumiendo semver (X.Y.Z)
      final isNewer = _isRemoteNewer(localVersionStr, cleanRemoteVersion);

      if (isNewer) {
        return UpdateInfo(
          isUpdateAvailable: true,
          latestVersion: cleanRemoteVersion,
          releaseUrl: releaseUrl,
        );
      }
    }
    return UpdateInfo(
      isUpdateAvailable: false,
      latestVersion: localVersionStr,
      releaseUrl: '',
    );
  } catch (e) {
    // En caso de fallo (sin internet, etc), no forzamos nada.
    return null;
  }
});

bool _isRemoteNewer(String local, String remote) {
  try {
    // Limpieza de cualquier sufijo extra (ej. 4.0.0-beta -> 4.0.0)
    local = local.split('-')[0].split('+')[0];
    remote = remote.split('-')[0].split('+')[0];

    final localParts = local.split('.').map(int.parse).toList();
    final remoteParts = remote.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final l = i < localParts.length ? localParts[i] : 0;
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  } catch (e) {
    return false;
  }
}

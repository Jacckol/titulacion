import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PerfilEmpleadorService {
  // 🔹 Perfil extendido (con archivos)
  static const String baseUrl = "http://10.0.2.2:4000/api/empleadores/perfil";

  // 🔹 Perfil básico (Mi Perfil)
  static const String baseEmpleadores = "http://10.0.2.2:4000/api/empleadores";

  static Future<http.Response> crearPerfil({
    required String token,
    required Map<String, String> data,
    File? foto,
    File? cv,
    required File recordPolicial,
  }) async {
    final uri = Uri.parse(baseUrl);
    final request = http.MultipartRequest("POST", uri);

    request.headers["Authorization"] = "Bearer $token";

    // 🔹 Campos texto
    request.fields.addAll(data);

    // 🔹 Foto
    if (foto != null) {
      request.files.add(
        await http.MultipartFile.fromPath("foto", foto.path),
      );
    }

    // 🔹 CV
    if (cv != null) {
      request.files.add(
        await http.MultipartFile.fromPath("cv", cv.path),
      );
    }

    // 🔹 Récord policial (OBLIGATORIO)
    request.files.add(
      await http.MultipartFile.fromPath(
        "recordPolicial",
        recordPolicial.path,
      ),
    );

    final streamed = await request.send();
    return await http.Response.fromStream(streamed);
  }

  // ======================================================
  // ✅ OBTENER MI PERFIL (token)
  // GET /api/empleadores/me
  // ======================================================
  static Future<http.Response> obtenerMiPerfil({
    required String token,
  }) async {
    final uri = Uri.parse("$baseEmpleadores/me");
    return http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  // ======================================================
  // ✅ ACTUALIZAR MI PERFIL (token)
  // PUT /api/empleadores/me
  // ======================================================
  static Future<http.Response> actualizarMiPerfil({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse("$baseEmpleadores/me");
    return http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
  }

  // ======================================================
  // ✅ SUBIR/ACTUALIZAR ARCHIVOS EN MI PERFIL (token)
  // PUT /api/empleadores/me/archivos
  // ======================================================
  static Future<http.Response> actualizarMisArchivos({
    required String token,
    File? foto,
    File? recordPolicial,
  }) async {
    final uri = Uri.parse("$baseEmpleadores/me/archivos");
    final request = http.MultipartRequest('PUT', uri);

    request.headers['Authorization'] = 'Bearer $token';

    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }

    if (recordPolicial != null) {
      request.files.add(
        await http.MultipartFile.fromPath('recordPolicial', recordPolicial.path),
      );
    }

    final streamed = await request.send();
    return await http.Response.fromStream(streamed);
  }
}

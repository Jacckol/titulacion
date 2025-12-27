import 'dart:convert';
import 'package:http/http.dart' as http;

class ServiciosService {
  final String baseUrl = "http://10.0.2.2:4000/api/servicios";

  Future<bool> publicarServicio({
    required String titulo,
    required String categoria,
    required String descripcion,
    required String ubicacion,
    required double presupuesto,
    required int userId,
  }) async {
    try {
      final url = Uri.parse(baseUrl);

      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "titulo": titulo,
          "categoria": categoria,
          "descripcion": descripcion,
          "ubicacion": ubicacion,
          "presupuesto": presupuesto,
          "userId": userId,
        }),
      );

      print("📩 RESPUESTA BACKEND:");
      print(resp.body);

      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      print("❌ Error en ServiciosService: $e");
      return false;
    }
  }

  Future<List<dynamic>> obtenerMisServicios(int userId) async {
    try {
      final url = Uri.parse("$baseUrl/usuario/$userId");
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
      return [];
    } catch (e) {
      print("❌ Error obteniendo servicios: $e");
      return [];
    }
  }
}

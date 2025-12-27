import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServicioProvider extends ChangeNotifier {
  // ⭐ emulador -> backend
  final String baseUrl = "http://10.0.2.2:4000/api/servicios";

  // ======================================================
  // 🔹 PUBLICAR SERVICIO (POST /api/servicios)
  // ======================================================
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "titulo": titulo,
          "categoria": categoria,
          "descripcion": descripcion,
          "ubicacion": ubicacion,
          "presupuesto": presupuesto,
          "userId": userId,
        }),
      );

      debugPrint("📩 publicarServicio status: ${resp.statusCode} body: ${resp.body}");

      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      debugPrint("❌ Error publicando servicio: $e");
      return false;
    }
  }

  // ======================================================
  // 🔹 (OPCIONAL) LISTAR FEED GENERAL (GET /api/servicios)
  // Si no lo usas, puedes borrar este método.
  // ======================================================
  Future<List<dynamic>> listarServiciosFeed() async {
    try {
      final url = Uri.parse(baseUrl);
      final resp = await http.get(url);

      debugPrint("📩 listarServiciosFeed status: ${resp.statusCode}");

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error listarServiciosFeed: $e");
      return [];
    }
  }
}

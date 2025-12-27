import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MisServiciosProvider extends ChangeNotifier {
  final String baseUrl = "http://10.0.2.2:4000/api/servicios";

  List<dynamic> misServicios = [];

  // ======================================================
  // ✅ Cargar MIS SERVICIOS + POSTULACIONES (BACKEND REAL)
  // GET /api/servicios/mis/:userId
  // ======================================================
  Future<List<dynamic>> cargarMisServicios(int userId) async {
    try {
      final url = Uri.parse("$baseUrl/mis/$userId");
      final resp = await http.get(url);

      debugPrint("📩 cargarMisServicios status: ${resp.statusCode}");
      debugPrint("📩 body: ${resp.body}");

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);

        // Debe ser una lista
        misServicios = (decoded is List) ? decoded : [];
        notifyListeners();
        return misServicios;
      } else {
        debugPrint("❌ Error backend: ${resp.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error cargarMisServicios: $e");
      return [];
    }
  }

  // ======================================================
  // 🔹 EDITAR SERVICIO (PUT)
  // ======================================================
  Future<bool> editarServicio({
    required int id,
    required String titulo,
    required String categoria,
    required String descripcion,
    required String ubicacion,
    required double presupuesto,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/$id");

      final resp = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "titulo": titulo,
          "categoria": categoria,
          "descripcion": descripcion,
          "ubicacion": ubicacion,
          "presupuesto": presupuesto,
        }),
      );

      debugPrint("📌 RESPUESTA EDITAR status: ${resp.statusCode} body: ${resp.body}");

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        // tu backend puede devolver {ok:true, servicio:{...}}
        final actualizado =
            (data is Map && data["servicio"] != null) ? data["servicio"] : data;

        final index = misServicios.indexWhere((s) => s["id"] == id);
        if (index != -1) {
          misServicios[index] = actualizado;
          notifyListeners();
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ Error editar servicio: $e");
      return false;
    }
  }

  // ======================================================
  // 🔹 ELIMINAR SERVICIO POR ID
  // ======================================================
  Future<bool> eliminarServicio(int id) async {
    try {
      final url = Uri.parse("$baseUrl/$id");
      final resp = await http.delete(url);

      debugPrint("📌 eliminarServicio status: ${resp.statusCode} body: ${resp.body}");

      if (resp.statusCode == 200) {
        misServicios.removeWhere((s) => s["id"] == id);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ Error eliminar servicio: $e");
      return false;
    }
  }
}

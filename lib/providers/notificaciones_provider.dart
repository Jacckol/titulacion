import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificacionesProvider extends ChangeNotifier {
  final String baseUrl = "http://10.0.2.2:4000";

  List<Map<String, dynamic>> _notificaciones = [];
  List<Map<String, dynamic>> get notificaciones => _notificaciones;

  bool cargado = false;

  // 🔴 Contador de notificaciones no leídas
  int get unreadCount =>
      _notificaciones.where((n) => n['leido'] == false).length;

  // =================================================
  // 🔵 CARGAR NOTIFICACIONES DEL USUARIO (empleador o trabajador)
  // =================================================
  Future<void> cargarNotificaciones(int userId) async {
    try {
      final url = Uri.parse("$baseUrl/api/notificaciones/$userId");

      final resp = await http.get(url);

      print("📥 RESPUESTA NOTIFICACIONES: ${resp.body}");

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        if (data is List) {
          _notificaciones =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _notificaciones = [];
        }

        cargado = true;
      } else {
        print("❌ Error del servidor: ${resp.statusCode}");
      }
    } catch (e) {
      print("❌ Error en cargarNotificaciones: $e");
    }

    notifyListeners();
  }

  // =================================================
  // 🔵 MARCAR COMO LEÍDA
  // =================================================
  Future<void> marcarLeida(int id) async {
    try {
      final url = Uri.parse("$baseUrl/api/notificaciones/$id/leer");
      final resp = await http.patch(url);

      if (resp.statusCode == 200) {
        // Eliminar de la lista local
        _notificaciones.removeWhere((n) => n["id"] == id);
      } else {
        print("❌ Error marcando leída: ${resp.statusCode}");
      }
    } catch (e) {
      print("❌ Error marcarLeida: $e");
    }

    notifyListeners();
  }

  // =================================================
  // 🔵 AGREGAR NOTIFICACIÓN LOCAL
  // =================================================
  void agregarNotificacionLocal(Map<String, dynamic> notificacion) {
    _notificaciones.insert(0, notificacion);
    notifyListeners();
  }

  // =================================================
  // 🔵 LIMPIAR NOTIFICACIONES
  // =================================================
  void limpiar() {
    _notificaciones.clear();
    cargado = false;
    notifyListeners();
  }
}

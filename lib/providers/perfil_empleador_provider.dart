import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/perfil_empleador_service.dart';

class PerfilEmpleadorProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  // ✅ Perfil básico para pantalla "Mi Perfil" (empleador)
  Map<String, dynamic>? miPerfil;

  // ======================================================
  // ✅ GET mi perfil
  // ======================================================
  Future<void> fetchMiPerfil({required String token}) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final resp = await PerfilEmpleadorService.obtenerMiPerfil(token: token);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        miPerfil = (data is Map && data["empleador"] is Map)
            ? Map<String, dynamic>.from(data["empleador"])
            : null;
      } else {
        miPerfil = null;
        try {
          final body = jsonDecode(resp.body);
          error = body["error"] ?? body["msg"] ?? "Error al cargar perfil";
        } catch (_) {
          error = "Error al cargar perfil";
        }
      }
    } catch (e) {
      error = "Error de conexión";
      miPerfil = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ======================================================
  // ✅ PUT mi perfil
  // ======================================================
  Future<bool> guardarMiPerfil({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final resp = await PerfilEmpleadorService.actualizarMiPerfil(
        token: token,
        data: data,
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map && body["empleador"] is Map) {
          miPerfil = Map<String, dynamic>.from(body["empleador"]);
        }
        return true;
      }

      try {
        final body = jsonDecode(resp.body);
        error = body["error"] ?? body["message"] ?? "Error al guardar perfil";
      } catch (_) {
        error = "Error al guardar perfil";
      }
      return false;
    } catch (e) {
      error = "Error de conexión";
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> crearPerfil({
    required String token,
    required Map<String, String> data,
    File? foto,
    File? cv,
    required File recordPolicial,
  }) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final resp = await PerfilEmpleadorService.crearPerfil(
        token: token,
        data: data,
        foto: foto,
        cv: cv,
        recordPolicial: recordPolicial,
      );

      if (resp.statusCode == 201) {
        return true;
      } else {
        final body = jsonDecode(resp.body);
        error = body["message"] ?? "Error al crear perfil";
        return false;
      }
    } catch (e) {
      error = "Error de conexión";
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ======================================================
  // ✅ Subir/actualizar archivos desde "Mi Perfil"
  // ======================================================
  Future<bool> actualizarMisArchivos({
    required String token,
    File? foto,
    File? recordPolicial,
  }) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final resp = await PerfilEmpleadorService.actualizarMisArchivos(
        token: token,
        foto: foto,
        recordPolicial: recordPolicial,
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map && body["empleador"] is Map) {
          miPerfil = Map<String, dynamic>.from(body["empleador"]);
        }
        return true;
      }

      try {
        final body = jsonDecode(resp.body);
        error = body["error"] ?? body["message"] ?? "Error al subir archivos";
      } catch (_) {
        error = "Error al subir archivos";
      }
      return false;
    } catch (e) {
      error = "Error de conexión";
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

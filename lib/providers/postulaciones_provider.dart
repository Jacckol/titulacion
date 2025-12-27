import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ======================================================
// ENUM ESTADOS
// ======================================================
enum EstadoPostulacion { pendiente, aceptada, rechazada }

EstadoPostulacion estadoFromString(String estado) {
  final s = estado.toLowerCase().trim();
  if (s.contains("acept")) return EstadoPostulacion.aceptada;   // aceptado/aceptada
  if (s.contains("rech")) return EstadoPostulacion.rechazada;   // rechazado/rechazada
  return EstadoPostulacion.pendiente;
}

// ======================================================
// MODELO POSTULACIÓN (TRABAJOS) - sin romper tu app
// ======================================================
class Postulacion {
  final int id;
  final int trabajoId;
  final String titulo;
  final String categoria;
  final String empleador;
  final String ubicacion;
  final double presupuesto;
  final String duracion;
  final String mensaje;

  // ✅ ESTA ES TU FECHA REAL (se usa para headers y expiración)
  final DateTime fecha;

  EstadoPostulacion estado;

  Postulacion({
    required this.id,
    required this.trabajoId,
    required this.titulo,
    required this.categoria,
    required this.empleador,
    required this.ubicacion,
    required this.presupuesto,
    required this.duracion,
    required this.mensaje,
    required this.fecha,
    required this.estado,
  });

  // ✅ parsea fecha bien para evitar "Ayer" por zona horaria
  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    final raw = v.toString().trim();
    if (raw.isEmpty) return DateTime.now();

    // Si NO trae Z o +hh:mm, lo tratamos como UTC y le ponemos Z
    final hasTZ = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(raw);
    final normalized = hasTZ ? raw : '${raw}Z';

    final dt = DateTime.tryParse(normalized);
    return (dt ?? DateTime.now()).toLocal();
  }

  factory Postulacion.fromJson(Map<String, dynamic> json) {
    // ✅ soporta "trabajo" o "Trabajo"
    final trabajo = (json["trabajo"] ?? json["Trabajo"] ?? {}) as Map;

    return Postulacion(
      id: _toInt(json["id"]),
      trabajoId: _toInt(trabajo["id"]),
      titulo: (trabajo["titulo"] ?? "Sin título").toString(),
      categoria: (trabajo["categoria"] ?? "General").toString(),
      empleador: (json["empleador"] ?? "Empleador").toString(),
      ubicacion: (trabajo["ubicacion"] ?? "").toString(),
      presupuesto: _toDouble(trabajo["presupuesto"] ?? json["presupuesto"] ?? 0),
      duracion: (trabajo["duracion"] ?? json["duracion"] ?? "").toString(),
      mensaje: (json["mensaje"] ?? "").toString(),

      // ✅ CLAVE: aquí agarramos createdAt real del backend
      fecha: _parseDate(
        json["createdAt"] ??
            json["fecha"] ??
            json["created_at"] ??
            json["fechaCreacion"] ??
            json["fecha_postulacion"],
      ),

      estado: estadoFromString((json["estado"] ?? "pendiente").toString()),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ======================================================
// PROVIDER POSTULACIONES
// ======================================================
class PostulacionesProvider extends ChangeNotifier {
  final String baseUrl = "http://10.0.2.2:4000";

  List<Postulacion> _postulaciones = [];

  List<Postulacion> get todas => _postulaciones;

  List<Postulacion> get pendientes =>
      _postulaciones.where((p) => p.estado == EstadoPostulacion.pendiente).toList();

  List<Postulacion> get aceptadas =>
      _postulaciones.where((p) => p.estado == EstadoPostulacion.aceptada).toList();

  List<Postulacion> get rechazadas =>
      _postulaciones.where((p) => p.estado == EstadoPostulacion.rechazada).toList();

  int get totalPendientes => pendientes.length;
  int get totalAceptadas => aceptadas.length;
  int get totalRechazadas => rechazadas.length;

  // ======================================================
  // GET /api/postulaciones/usuario/:userId
  // ======================================================
  Future<void> cargarPostulaciones(int userId) async {
    try {
      final url = Uri.parse("$baseUrl/api/postulaciones/usuario/$userId");
      final resp = await http.get(url);

      debugPrint("📥 GET cargarPostulaciones => $url");
      debugPrint("📥 status=${resp.statusCode} body=${resp.body}");

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);

        List lista = [];
        if (decoded is List) {
          lista = decoded;
        } else if (decoded is Map && decoded["postulaciones"] is List) {
          lista = decoded["postulaciones"];
        } else if (decoded is Map && decoded["data"] is List) {
          lista = decoded["data"];
        }

        _postulaciones = lista
            .where((e) => e is Map)
            .map<Postulacion>((p) => Postulacion.fromJson(Map<String, dynamic>.from(p)))
            .toList();
      } else {
        _postulaciones = [];
      }
    } catch (e) {
      debugPrint("❌ ERROR cargarPostulaciones: $e");
      _postulaciones = [];
    }

    notifyListeners();
  }

  Future<void> cargarDesdeBackend(int userId) async {
    await cargarPostulaciones(userId);
  }

  // ======================================================
  // POST /api/postulaciones
  // ======================================================
  Future<bool> crearPostulacion({
    required int trabajoId,
    required int userId,
    required String mensaje,

    required String titulo,
    required String categoria,
    required String empleador,
    required String ubicacion,
    required double presupuesto,
    required String duracion,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/postulaciones");

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "trabajoId": trabajoId,
          "userId": userId,
          "mensaje": mensaje,
        }),
      );

      if (resp.statusCode == 201) {
        final nueva = Postulacion(
          id: DateTime.now().millisecondsSinceEpoch,
          trabajoId: trabajoId,
          titulo: titulo,
          categoria: categoria,
          empleador: empleador,
          ubicacion: ubicacion,
          presupuesto: presupuesto,
          duracion: duracion,
          mensaje: mensaje,

          // ✅ fecha local
          fecha: DateTime.now(),

          estado: EstadoPostulacion.pendiente,
        );

        _postulaciones.insert(0, nueva);
        notifyListeners();
        return true;
      }

      debugPrint("❌ crearPostulacion(trabajo) status: ${resp.statusCode} body: ${resp.body}");
      return false;
    } catch (e) {
      debugPrint("❌ ERROR crearPostulacion(trabajo): $e");
      return false;
    }
  }

  // ======================================================
  // POST /api/servicios/:servicioId/postulaciones
  // ======================================================
  Future<bool> crearPostulacionServicio({
    required int servicioId,
    required int userId,
    required String mensaje,
    String? empresa,
  }) async {
    try {
      if (servicioId <= 0) {
        debugPrint("❌ crearPostulacionServicio: servicioId inválido => $servicioId");
        return false;
      }

      final url = Uri.parse("$baseUrl/api/servicios/$servicioId/postulaciones");

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "mensaje": mensaje,
        }),
      );

      debugPrint("📥 crearPostulacionServicio status: ${resp.statusCode} body: ${resp.body}");
      return resp.statusCode == 201;
    } catch (e) {
      debugPrint("❌ ERROR crearPostulacionServicio: $e");
      return false;
    }
  }

  // ======================================================
  // PUT /api/servicios/postulaciones/:id/estado
  // ======================================================
  Future<bool> cambiarEstadoPostulacion({
    required int postulacionId,
    required String estado,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/servicios/postulaciones/$postulacionId/estado");

      final resp = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"estado": estado}),
      );

      if (resp.statusCode == 200) return true;

      debugPrint("❌ cambiarEstadoPostulacion status: ${resp.statusCode} body: ${resp.body}");
      return false;
    } catch (e) {
      debugPrint("❌ ERROR cambiarEstadoPostulacion: $e");
      return false;
    }
  }

  // ======================================================
  // GET /api/servicios/:servicioId/postulaciones
  // ======================================================
  Future<List<Map<String, dynamic>>> obtenerPostulacionesServicio(int servicioId) async {
    try {
      if (servicioId <= 0) return [];

      final url = Uri.parse("$baseUrl/api/servicios/$servicioId/postulaciones");
      final resp = await http.get(url);

      if (resp.statusCode != 200) return [];

      final decoded = jsonDecode(resp.body);
      return _toMapList(decoded);
    } catch (e) {
      debugPrint("❌ ERROR obtenerPostulacionesServicio: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> _toMapList(dynamic decoded) {
    List lista = [];

    if (decoded is List) {
      lista = decoded;
    } else if (decoded is Map && decoded["postulaciones"] is List) {
      lista = decoded["postulaciones"];
    } else if (decoded is Map && decoded["data"] is List) {
      lista = decoded["data"];
    }

    return lista
        .where((e) => e is Map)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ======================================================
  // UTILIDADES LOCALES
  // ======================================================
  void actualizarEstadoLocal(int id, EstadoPostulacion nuevoEstado) {
    final index = _postulaciones.indexWhere((p) => p.id == id);
    if (index != -1) {
      _postulaciones[index].estado = nuevoEstado;
      notifyListeners();
    }
  }

  void eliminarPostulacionLocal(int id) {
    _postulaciones.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void limpiar() {
    _postulaciones.clear();
    notifyListeners();
  }
}

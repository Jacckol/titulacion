import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class TransactionsProvider extends ChangeNotifier {
  List<dynamic> transacciones = [];
  List<dynamic> pendientes = [];
  bool loading = false;

  Future<void> cargarTransacciones(String token) async {
    loading = true;
    notifyListeners();

    // 👉 IP REAL PARA EMULADOR (10.0.2.2) + PUERTO REAL (4000)
    final url = Uri.parse("http://10.0.2.2:4000/api/transactions/mine");

    final resp = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    loading = false;

    if (resp.statusCode == 200) {
      transacciones = jsonDecode(resp.body);
      notifyListeners();
    } else {
      transacciones = [];
      notifyListeners();
    }
  }

  Future<void> cargarPendientes(String token) async {
    loading = true;
    notifyListeners();

    final url = Uri.parse("http://10.0.2.2:4000/api/transactions/pendientes");
    final resp = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    loading = false;
    if (resp.statusCode == 200) {
      pendientes = jsonDecode(resp.body);
    } else {
      pendientes = [];
    }
    notifyListeners();
  }

  Future<bool> confirmarPago({
    required String token,
    required int empleadorId,
    required int trabajadorId,
    int? trabajoId,
    int? servicioId,
    double? monto,
    String? descripcion,
    PlatformFile? comprobante,
  }) async {
    final url = Uri.parse("http://10.0.2.2:4000/api/transactions/confirmar");

    // ✅ Si viene comprobante, enviamos multipart. Si no, igual usamos multipart
    // para simplificar y soportar el flujo de evidencia de pago.
    final req = http.MultipartRequest("POST", url);
    req.headers["Authorization"] = "Bearer $token";

    req.fields["empleadorId"] = empleadorId.toString();
    req.fields["trabajadorId"] = trabajadorId.toString();
    if (trabajoId != null) req.fields["trabajoId"] = trabajoId.toString();
    if (servicioId != null) req.fields["servicioId"] = servicioId.toString();
    if (monto != null) req.fields["monto"] = monto.toString();
    if (descripcion != null) req.fields["descripcion"] = descripcion;

    if (comprobante != null) {
      if (kIsWeb) {
        req.files.add(http.MultipartFile.fromBytes(
          "comprobante",
          comprobante.bytes!,
          filename: comprobante.name,
        ));
      } else {
        req.files.add(await http.MultipartFile.fromPath(
          "comprobante",
          comprobante.path!,
          filename: comprobante.name,
        ));
      }
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    return resp.statusCode == 200;
  }
}
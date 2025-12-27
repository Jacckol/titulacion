import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/trabajo.dart';

class TrabajoProvider extends ChangeNotifier {
  final String _baseUrl = "http://10.0.2.2:4000/api/trabajos"; // cambia IP si usas físico

  Future<bool> publicarTrabajo(Trabajo trabajo) async {
    final url = Uri.parse("$_baseUrl/publicar");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(trabajo.toJson()),
    );

    if (response.statusCode == 200) {
      print("✅ Trabajo publicado: ${response.body}");
      return true;
    } else {
      print("❌ Error al publicar: ${response.body}");
      return false;
    }
  }
}

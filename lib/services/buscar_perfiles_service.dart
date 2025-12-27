import 'dart:convert';
import 'package:http/http.dart' as http;

class BuscarPerfilesService {
  static const String _url =
      'http://10.0.2.2:4000/api/trabajador/buscar';

  static Future<List<dynamic>> obtenerPerfiles() async {
    final res = await http.get(Uri.parse(_url));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['trabajadores'] ?? [];
    } else {
      throw Exception('Error al cargar perfiles');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trabajador_model.dart';

class BuscarTrabajadoresService {
  static const String _url =
      'http://10.0.2.2:4000/api/trabajador/buscar';

  static Future<List<TrabajadorModel>> buscarPerfiles() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List lista = body['trabajadores'] ?? [];

      return lista
          .map((json) => TrabajadorModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Error al cargar trabajadores');
    }
  }
}

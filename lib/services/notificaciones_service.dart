import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificacionesService {
  final String baseUrl = "http://TU_IP:3000/api/notificaciones";

  Future<List<dynamic>> getNotificaciones(int empleadorId) async {
    final url = Uri.parse("$baseUrl/empleador/$empleadorId");
    final resp = await http.get(url);

    return jsonDecode(resp.body);
  }

  Future<void> marcarLeida(int id) async {
    final url = Uri.parse("$baseUrl/$id/leer");
    await http.patch(url);
  }
}

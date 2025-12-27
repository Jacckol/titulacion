import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // =====================================================
  // ✅ BASE URL
  // =====================================================
  final String baseUrl = 'http://10.0.2.2:4000/api';

  // =====================================================
  // 🟦 LOGIN
  // =====================================================
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'token': data['token'],
            'rol': data['rol'] ?? data['user']?['rol'],
            'perfilCompleto': data['perfilCompleto'] ?? false,
            'user': data['user'],
            'trabajador': data['trabajador'],
            'empleador': data['empleador'],
          };
        }
      }
    } catch (e) {
      print('❌ ERROR LOGIN SERVICE: $e');
    }

    return null;
  }

  // =====================================================
  // 🟩 REGISTRO (USUARIO / TRABAJADOR / EMPLEADOR)
  // =====================================================
  Future<bool> registerUser({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    String telefono = '',
  }) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
          'rol': rol,        // 👈 CLAVE (NO QUITAR)
          'telefono': telefono,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('❌ ERROR REGISTER SERVICE: $e');
      return false;
    }
  }

  // =====================================================
  // 🟧 PERFIL LABORAL
  // =====================================================
  Future<bool> savePerfilLaboral(Map<String, dynamic> perfil, String token) async {
    final url = Uri.parse('$baseUrl/perfil-laboral');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(perfil),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ ERROR PERFIL LABORAL: $e');
      return false;
    }
  }
}

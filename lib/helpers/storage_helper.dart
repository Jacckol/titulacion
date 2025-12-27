import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } else {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'token', value: token);
    }
  }

  static Future<String?> readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } else {
      final storage = FlutterSecureStorage();
      return await storage.read(key: 'token');
    }
  }

  static Future<void> deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } else {
      final storage = FlutterSecureStorage();
      await storage.delete(key: 'token');
    }
  }
}

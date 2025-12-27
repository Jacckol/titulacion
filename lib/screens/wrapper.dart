import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// Screens
import 'login_screen.dart';
import 'empleador/home_empleador_screen.dart';
import 'home_trabajador.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ⏳ Cargando sesión
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔒 NO LOGUEADO
    if (auth.token == null || auth.role == null) {
      return const LoginScreen(rol: 'trabajador');
    }

    // 👷 TRABAJADOR
    if (auth.role == 'trabajador') {
      return const HomeTrabajadorScreen();
    }

    // 🧑‍💼 EMPLEADOR
    if (auth.role == 'empleador') {
      return const HomeEmpleadorScreen();
    }

    // FALLBACK (por seguridad)
    return const LoginScreen(rol: 'trabajador');
  }
}

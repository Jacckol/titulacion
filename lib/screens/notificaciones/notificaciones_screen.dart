import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notificaciones_provider.dart';
import '../../providers/auth_provider.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {

  // ======================================================
  // 🔥 CARGAR NOTIFICACIONES AL ENTRAR
  // ======================================================
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final notiProv = context.read<NotificacionesProvider>();

      if (auth.userId != null) {
        notiProv.cargarNotificaciones(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notiProv = context.watch<NotificacionesProvider>();

    // 🚨 NO SE FILTRA POR ROL
    final notificaciones = notiProv.notificaciones;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      appBar: AppBar(
        title: const Text("Notificaciones"),
        centerTitle: true,
        elevation: 0,
      ),
      body: notificaciones.isEmpty
          ? _sinNotificaciones()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notificaciones.length,
              itemBuilder: (_, i) {
                final noti = notificaciones[i];

                final usuario = noti["usuarioNotificacion"] ?? {};
                final nombreUsuario =
                    usuario["nombre"] ?? "Sistema";

                final String mensaje =
                    noti["mensaje"] ?? "Sin mensaje";

                final bool leido = noti["leido"] ?? false;

                return _cardNotificacion(
                  context,
                  notificacion: noti,
                  nombreUsuario: nombreUsuario,
                  mensaje: mensaje,
                  leido: leido,
                  onMarcarLeida: () =>
                      notiProv.marcarLeida(noti["id"]),
                );
              },
            ),
    );
  }

  // ======================================================
  // SIN NOTIFICACIONES
  // ======================================================
  Widget _sinNotificaciones() {
    return const Center(
      child: Text(
        "No hay notificaciones nuevas",
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  // ======================================================
  // CARD NOTIFICACIÓN
  // ======================================================
  Widget _cardNotificacion(
    BuildContext context, {
    required Map<String, dynamic> notificacion,
    required String nombreUsuario,
    required String mensaje,
    required bool leido,
    required VoidCallback onMarcarLeida,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.pushNamed(
          context,
          "/notificacionDetalle",
          arguments: {"notificacion": notificacion},
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: leido ? Colors.white : const Color(0xFFE8E5FF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.deepPurple.shade200,
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreUsuario,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mensaje,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.check_circle,
                color: leido ? Colors.grey : Colors.green,
                size: 30,
              ),
              onPressed: onMarcarLeida,
            ),
          ],
        ),
      ),
    );
  }
}

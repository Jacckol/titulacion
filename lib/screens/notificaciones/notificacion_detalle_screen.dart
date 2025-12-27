import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificacionDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> notificacion;

  const NotificacionDetalleScreen({
    super.key,
    required this.notificacion,
  });

  // ======================================================
  // 🔧 OBTENER TÍTULO DEL TRABAJO O CONTEXTO
  // ======================================================
  String _obtenerTituloTrabajo(Map<String, dynamic> notificacion) {
    final trabajo = notificacion["trabajo"];

    if (trabajo != null && trabajo["titulo"] != null) {
      return trabajo["titulo"];
    }

    // 🔥 USAR EL TÍTULO DE LA NOTIFICACIÓN COMO CONTEXTO
    if (notificacion["titulo"] != null) {
      return notificacion["titulo"];
    }

    return "Trabajo no especificado";
  }

  // ======================================================
  // 📅 FORMATEAR FECHA
  // ======================================================
  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return "Fecha no disponible";

    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null) return "Fecha no disponible";

    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("📩 NOTIFICACIÓN DETALLE:");
    debugPrint(notificacion.toString());

    final usuario = notificacion["usuarioNotificacion"] ?? {};
    final nombreUsuario = usuario["nombre"] ?? "Usuario desconocido";

    final mensaje = notificacion["mensaje"] ?? "Sin mensaje";
    final tituloTrabajo = _obtenerTituloTrabajo(notificacion);
    final fecha = _formatearFecha(notificacion["createdAt"]);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de Notificación"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= AVATAR =================
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.deepPurple.shade300,
                child: const Icon(
                  Icons.notifications,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= USUARIO =================
            Text(
              nombreUsuario,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // ================= FECHA =================
            Text(
              fecha,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // ================= CONTEXTO =================
            Text(
              "Contexto:",
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tituloTrabajo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // ================= MENSAJE =================
            Text(
              "Mensaje:",
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // ================= VOLVER =================
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text(
                  "Volver",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

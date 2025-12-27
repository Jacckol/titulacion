import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/postulaciones_provider.dart';
import '../../providers/auth_provider.dart';

class PostularServicioScreen extends StatefulWidget {
  final int servicioId;

  final String titulo;
  final String categoria;
  final String empresa;
  final String ubicacion;
  final String salario;
  final String descripcion;

  const PostularServicioScreen({
    super.key,
    required this.servicioId,
    required this.titulo,
    required this.categoria,
    required this.empresa,
    required this.ubicacion,
    required this.salario,
    required this.descripcion,
  });

  @override
  State<PostularServicioScreen> createState() => _PostularServicioScreenState();
}

class _PostularServicioScreenState extends State<PostularServicioScreen> {
  final TextEditingController mensajeCtrl = TextEditingController();
  bool enviando = false;

  @override
  void dispose() {
    mensajeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final postProv = context.read<PostulacionesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Detalles del Servicio",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              "Publicado por: ${widget.empresa}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.categoria,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Descripción del Servicio",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              widget.descripcion,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.ubicacion, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(Icons.attach_money, size: 20),
                const SizedBox(width: 4),
                Text(
                  widget.salario,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Mensaje al trabajador:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: mensajeCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        final userId = auth.userId;

                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Debes iniciar sesión primero"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (widget.servicioId <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ID de servicio inválido ❌"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final mensaje = mensajeCtrl.text.trim().isEmpty
                            ? "Estoy interesado en contratar tu servicio."
                            : mensajeCtrl.text.trim();

                        setState(() => enviando = true);

                        try {
                          final ok = await postProv.crearPostulacionServicio(
                            servicioId: widget.servicioId,
                            userId: userId,
                            mensaje: mensaje,
                          );

                          if (!mounted) return;

                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Postulación enviada a "${widget.titulo}"'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Error al enviar la postulación ❌"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => enviando = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Postular Ahora",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

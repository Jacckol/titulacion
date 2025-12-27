
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/postulaciones_provider.dart';
import '../../providers/auth_provider.dart';

class PostularOfertaScreen extends StatefulWidget {
  // ✅ ES TRABAJO ID (NO SERVICIO)
  final int trabajoId;

  final String titulo;
  final String categoria;
  final String empresa;
  final String ubicacion;
  final String salario;
  final String descripcion;
  final String? fechaLimite;

  const PostularOfertaScreen({
    super.key,
    required this.trabajoId,
    required this.titulo,
    required this.categoria,
    required this.empresa,
    required this.ubicacion,
    required this.salario,
    required this.descripcion,
    this.fechaLimite,
  });

  @override
  State<PostularOfertaScreen> createState() => _PostularOfertaScreenState();
}

class _PostularOfertaScreenState extends State<PostularOfertaScreen> {
  final mensajeCtrl = TextEditingController();
  bool enviando = false;

  @override
  void dispose() {
    mensajeCtrl.dispose();
    super.dispose();
  }

  double _parseSalario(String s) {
    // soporta: "$12", "12", "12.50", "12,50"
    final limpio = s
        .replaceAll("\$", "")
        .replaceAll("USD", "")
        .replaceAll("usd", "")
        .replaceAll(",", ".")
        .trim();
    return double.tryParse(limpio) ?? 0.0;
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
          "Detalles del Trabajo",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÍTULO
            Text(
              widget.titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 10),

            // EMPRESA
            Text(
              "Publicado por: ${widget.empresa}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            if (widget.fechaLimite != null && widget.fechaLimite!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      "Fecha límite: ${widget.fechaLimite}",
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // CATEGORÍA
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

            // DESCRIPCIÓN
            const Text(
              "Descripción del Trabajo",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
                  child: Text(
                    widget.ubicacion,
                    style: const TextStyle(fontSize: 14),
                  ),
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
              "Mensaje al empleador:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: mensajeCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje al empleador...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // BOTÓN POSTULAR
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

                        final mensaje = mensajeCtrl.text.trim().isEmpty
                            ? "Estoy interesado en este trabajo."
                            : mensajeCtrl.text.trim();

                        setState(() => enviando = true);

                        try {
                          // ✅ AQUÍ ESTÁ EL FIX: POSTULAR A TRABAJO (NO SERVICIO)
                          final ok = await postProv.crearPostulacion(
                            trabajoId: widget.trabajoId,
                            userId: userId,
                            mensaje: mensaje,

                            // UI inmediata (no afecta backend)
                            titulo: widget.titulo,
                            categoria: widget.categoria,
                            empleador: widget.empresa,
                            ubicacion: widget.ubicacion,
                            presupuesto: _parseSalario(widget.salario),
                            duracion: "",
                          );

                          if (!mounted) return;

                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Postulación enviada a \"${widget.titulo}\"",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // ✅ devuelve true para recargar lista si quieres
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

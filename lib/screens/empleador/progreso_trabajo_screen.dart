import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'pago_transferencia_screen.dart';

const String baseUrl = "http://10.0.2.2:4000/api";

class ProgresoTrabajoScreen extends StatefulWidget {
  final int trabajoId;

  // ✅ PUEDE SER NULL (ahí estaba el error)
  final int? trabajadorId;

  final String nombreTrabajador;
  final String tituloTrabajo;
  final String rol; // EMPLEADOR | TRABAJADOR

  const ProgresoTrabajoScreen({
    super.key,
    required this.trabajoId,
    required this.trabajadorId,
    required this.nombreTrabajador,
    required this.tituloTrabajo,
    required this.rol,
  });

  @override
  State<ProgresoTrabajoScreen> createState() =>
      _ProgresoTrabajoScreenState();
}

class _ProgresoTrabajoScreenState extends State<ProgresoTrabajoScreen> {
  bool loading = false;
  String estadoTrabajo = "activo";

  // ======================================================
  // 🔄 CARGAR ESTADO REAL DEL TRABAJO
  // ======================================================
  Future<void> cargarEstadoTrabajo() async {
    final url = Uri.parse("$baseUrl/trabajos/${widget.trabajoId}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => estadoTrabajo = data["estado"]);
        }
      }
    } catch (_) {}
  }

  // ======================================================
  // 🔥 FINALIZAR TRABAJO + IR A PAGO
  // ======================================================
  Future<void> finalizarTrabajo() async {
    if (loading) return;

    // ❌ PROTECCIÓN CLAVE (ESTO EVITA EL CRASH)
    if (widget.trabajadorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ El trabajador no existe"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    final url = Uri.parse(
      "$baseUrl/trabajos/${widget.trabajoId}/finalizar-simple",
    );

    try {
      final response = await http.put(url);
      setState(() => loading = false);

      if (response.statusCode == 200) {
        setState(() => estadoTrabajo = "finalizado");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Trabajo finalizado. Realiza el pago."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        // ==================================================
        // 👉 IR A PAGO (YA SEGURO)
        // ==================================================
        final pagoRealizado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PagoTransferenciaScreen(
              trabajadorId: widget.trabajadorId!, // 🔒 YA NO ES NULL
              trabajoId: widget.trabajoId,
            ),
          ),
        );

        if (pagoRealizado == true) {
          cargarEstadoTrabajo();
        }
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body["error"] ?? "Error al finalizar"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ No se pudo conectar al servidor"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    cargarEstadoTrabajo();
  }

  // ======================================================
  // 🎨 CHIP DE ESTADO
  // ======================================================
  Widget _estadoChip() {
    final isFinalizado = estadoTrabajo == "finalizado";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isFinalizado ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFinalizado ? "FINALIZADO" : "EN PROGRESO",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esEmpleador = widget.rol == "EMPLEADOR";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A4CE8),
        title: const Text("Progreso del Trabajo"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =========================
            // CARD DEL TRABAJO
            // =========================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: const Icon(
                      Icons.work_outline,
                      color: Colors.deepPurple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tituloTrabajo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Trabajador: ${widget.nombreTrabajador}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        _estadoChip(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (esEmpleador && estadoTrabajo != "finalizado")
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : finalizarTrabajo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Finalizar trabajo",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

            if (estadoTrabajo == "finalizado")
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  "Este trabajo ya fue finalizado ✅",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 👉 AJUSTA SI CAMBIAS DE IP
const String baseUrl = "http://10.0.2.2:4000";

class TrabajoEnProgresoScreen extends StatefulWidget {
  final int trabajoId;
  final String tituloTrabajo;

  const TrabajoEnProgresoScreen({
    super.key,
    required this.trabajoId,
    required this.tituloTrabajo,
  });

  @override
  State<TrabajoEnProgresoScreen> createState() =>
      _TrabajoEnProgresoScreenState();
}

class _TrabajoEnProgresoScreenState extends State<TrabajoEnProgresoScreen> {
  int segundos = 60; // ⏱ 1 minuto de prueba
  Timer? timer;
  bool tiempoFinalizado = false;
  bool enviando = false;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (segundos == 0) {
        t.cancel();
        setState(() {
          tiempoFinalizado = true;
        });
      } else {
        setState(() => segundos--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // =====================================================
  // 🔥 FINALIZAR TRABAJO (ÉXITO / MALO)
  // =====================================================
  Future<void> finalizarTrabajo(String resultado) async {
    if (enviando) return;

    setState(() => enviando = true);

    try {
      final url =
          Uri.parse("$baseUrl/api/trabajos/${widget.trabajoId}/finalizar");

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"resultado": resultado}),
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado == "exitoso"
                  ? "Trabajo finalizado con éxito"
                  : "Trabajo reportado como malo",
            ),
          ),
        );

        Navigator.pop(context); // volver a pantalla anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${resp.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    }

    setState(() => enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F0FF),
      appBar: AppBar(
        title: const Text("Trabajo en progreso"),
        backgroundColor: const Color(0xff6A4CE8),
        automaticallyImplyLeading: !tiempoFinalizado,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICONO
              Icon(
                tiempoFinalizado
                    ? Icons.check_circle
                    : Icons.directions_car,
                size: 90,
                color: tiempoFinalizado ? Colors.green : Colors.blue,
              ),

              const SizedBox(height: 20),

              // TITULO
              Text(
                widget.tituloTrabajo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // MENSAJE
              Text(
                tiempoFinalizado
                    ? "El trabajador llegó al sitio"
                    : "El trabajador se está dirigiendo al lugar",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 30),

              // CONTADOR
              if (!tiempoFinalizado)
                Text(
                  "Tiempo estimado: $segundos s",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              // =====================================
              // 🔘 BOTONES (SOLO CUANDO TERMINA)
              // =====================================
              if (tiempoFinalizado) ...[
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.thumb_up),
                  onPressed:
                      enviando ? null : () => finalizarTrabajo("exitoso"),
                  label: const Text(
                    "Trabajo finalizado con éxito",
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 14),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.report),
                  onPressed:
                      enviando ? null : () => finalizarTrabajo("malo"),
                  label: const Text(
                    "Reportar mal trabajo",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

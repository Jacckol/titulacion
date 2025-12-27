import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'progreso_trabajo_screen.dart';

// EMULADOR → 10.0.2.2
const String baseUrl = "http://10.0.2.2:4000";

class VerPostulacionesScreen extends StatefulWidget {
  final int trabajoId;
  final String tituloTrabajo;

  const VerPostulacionesScreen({
    super.key,
    required this.trabajoId,
    required this.tituloTrabajo,
  });

  @override
  State<VerPostulacionesScreen> createState() => _VerPostulacionesScreenState();
}

class _VerPostulacionesScreenState extends State<VerPostulacionesScreen> {
  bool loading = true;
  List postulaciones = [];

  // ============================
  // CARGAR POSTULACIONES
  // ============================
  Future<void> cargarPostulaciones({bool mostrarLoader = false}) async {
    if (!mounted) return;

    if (mostrarLoader) {
      setState(() => loading = true);
    }

    try {
      final url = Uri.parse(
        "$baseUrl/api/postulaciones/trabajo/${widget.trabajoId}",
      );

      final resp = await http.get(url);

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          postulaciones = data["postulaciones"] ?? [];
          loading = false;
        });
      } else {
        setState(() {
          postulaciones = [];
          loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        postulaciones = [];
        loading = false;
      });
    }
  }

  // =====================================================
  // ✅ ACEPTAR Y ENTRAR A PROGRESO (USER ID)
  // =====================================================
  Future<void> aceptarYIrAProgreso(Map p) async {
    try {
      final url = Uri.parse("$baseUrl/api/postulaciones/${p["id"]}/estado");

      final resp = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"estado": "aceptado"}),
      );

      if (resp.statusCode == 200) {
        final postulante = p["postulante"] ?? {};

        // ✅ USER ID (NO TRABAJADOR ID)
        final trabajadorId = postulante["userId"];

        if (trabajadorId == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se encontró userId del postulante")),
          );
          return;
        }

        await cargarPostulaciones();

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProgresoTrabajoScreen(
              trabajoId: widget.trabajoId,
              trabajadorId: trabajadorId,
              tituloTrabajo: widget.tituloTrabajo,
              nombreTrabajador: postulante["nombre"] ?? "Trabajador",
              rol: "EMPLEADOR",
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo aceptar (${resp.statusCode})")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error aceptando postulación")),
      );
    }
  }

  // ============================
  // RECHAZAR POSTULACIÓN
  // ============================
  Future<void> cambiarEstado(int id, String estado) async {
    try {
      final url = Uri.parse("$baseUrl/api/postulaciones/$id/estado");

      await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"estado": estado}),
      );

      await cargarPostulaciones();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error cambiando estado")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    cargarPostulaciones(mostrarLoader: true);
  }

  // =====================================================
  // 🎨 CHIP DE ESTADO
  // =====================================================
  Widget _estadoChip(String estado) {
    Color color = estado == "aceptado"
        ? Colors.green
        : estado == "rechazado"
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        estado.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = postulaciones.length;
    final aceptadas = postulaciones.where((p) => p["estado"] == "aceptado").length;
    final rechazadas = postulaciones.where((p) => p["estado"] == "rechazado").length;

    return Scaffold(
      backgroundColor: const Color(0xffF3F0FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff6A4CE8),
        centerTitle: true,
        title: const Text(
          "Postulaciones",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ================= CABECERA =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: Color(0xff6A4CE8),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tituloTrabajo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Gestiona las postulaciones recibidas",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Para evitar overflow en pantallas pequeñas
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 22 * 2 - 10) / 2,
                            child: _statCard("Postulaciones", total.toString(), Icons.group, Colors.blue),
                          ),
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 22 * 2 - 10) / 2,
                            child: _statCard("Aceptadas", aceptadas.toString(), Icons.check_circle, Colors.green),
                          ),
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 22 * 2 - 10) / 2,
                            child: _statCard("Rechazadas", rechazadas.toString(), Icons.cancel, Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= LISTA =================
                Expanded(
                  child: postulaciones.isEmpty
                      ? const Center(child: Text("Aún no hay postulaciones"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: postulaciones.length,
                          itemBuilder: (_, i) {
                            final p = postulaciones[i];
                            final postulante = p["postulante"] ?? {};

                            final nombre = (postulante["nombre"] ?? "Sin nombre").toString();
                            final email = (postulante["email"] ?? "Sin email").toString();

                            final msgRaw = (p["mensaje"] ?? "").toString().trim();
                            final mensaje = msgRaw.isEmpty ? "Sin mensaje" : msgRaw;

                            final estado = (p["estado"] ?? "pendiente").toString();

                            // ✅ USER ID
                            final trabajadorId = postulante["userId"];

                            final inicial = nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : "?";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: Colors.deepPurple.shade100,
                                        child: Text(
                                          inicial,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombre,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              email,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _estadoChip(estado),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  Text(mensaje, style: const TextStyle(fontSize: 14)),

                                  const SizedBox(height: 18),

                                  // ✅ FIX AMARILLO: OverflowBar (NO MÁS OVERFLOW)
                                  OverflowBar(
                                    alignment: MainAxisAlignment.end,
                                    overflowAlignment: OverflowBarAlignment.end,
                                    spacing: 8,
                                    overflowSpacing: 6,
                                    children: [
                                      if (estado == "pendiente") ...[
                                        ElevatedButton(
                                          onPressed: () => aceptarYIrAProgreso(p),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text("Aceptar"),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => cambiarEstado(p["id"], "rechazado"),
                                          child: const Text("Rechazar"),
                                        ),
                                      ],
                                      if (estado == "aceptado")
                                        TextButton.icon(
                                          onPressed: () {
                                            if (trabajadorId == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("No se encontró userId del postulante")),
                                              );
                                              return;
                                            }
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProgresoTrabajoScreen(
                                                  trabajoId: widget.trabajoId,
                                                  trabajadorId: trabajadorId,
                                                  tituloTrabajo: widget.tituloTrabajo,
                                                  nombreTrabajador: nombre,
                                                  rol: "EMPLEADOR",
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.timeline),
                                          label: const Text("Ver progreso"),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // ============================
  // 📊 TARJETA DE ESTADÍSTICA
  // ============================
  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 👉 Pantalla donde el trabajador se postula
import 'empleador/postular_oferta_screen.dart';

const String baseUrl = "http://10.0.2.2:4000";

class OfertasTrabajosScreen extends StatefulWidget {
  const OfertasTrabajosScreen({super.key});

  @override
  State<OfertasTrabajosScreen> createState() => _OfertasTrabajosScreenState();
}

class _OfertasTrabajosScreenState extends State<OfertasTrabajosScreen> {
  List trabajos = [];
  bool loading = true;

  // =====================================================
  // 🔥 CARGAR TRABAJOS REALMENTE DEL BACKEND
  // =====================================================
  Future<void> cargarTrabajos() async {
    try {
      final url = Uri.parse("$baseUrl/api/trabajos");

      final resp = await http.get(url);

      print("🟣 RESP API /trabajos → ${resp.statusCode}");
      print("📌 TRABAJOS RECIBIDOS → ${resp.body}");

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        // Si el backend devuelve lista directa → usarla
        // Si devuelve { trabajos: [] } → usar esa
        List lista = [];

        if (data is List) {
          lista = data;
        } else if (data["trabajos"] is List) {
          lista = data["trabajos"];
        }

        if (!mounted) return;

        setState(() {
          trabajos = lista;
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error ${resp.statusCode}: ${resp.body}")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    cargarTrabajos();
  }

  // =====================================================
  // 🔥 UI COMPLETA
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas de Trabajo'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
      backgroundColor: const Color(0xFFF9FAFB),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : trabajos.isEmpty
              ? const Center(
                  child: Text(
                    "No hay trabajos disponibles",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarTrabajos,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                      itemCount: trabajos.length,
                      itemBuilder: (context, index) {
                        final t = trabajos[index];

                        return _cardTrabajo(
                          trabajoId: t["id"],
                          titulo: t["titulo"] ?? "Sin título",
                          descripcion: t["descripcion"] ?? "",
                          categoria: t["categoria"] ?? "",
                          ubicacion: t["ubicacion"] ?? "",
                          salario:
                              (t["salario"] ?? t["presupuesto"] ?? 0).toString(),
                          empresa: t["empleador"]?["nombre"] ?? "Empleador",
                          fechaLimite: (t["fechaLimite"] ?? "").toString(),
                          urgente: (t["urgente"] ?? false) == true,
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  // =====================================================
  // 🔥 CARD DE TRABAJO
  // =====================================================
  Widget _cardTrabajo({
    required int trabajoId,
    required String titulo,
    required String descripcion,
    required String categoria,
    required String ubicacion,
    required String salario,
    required String empresa,
    required String fechaLimite,
    required bool urgente,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔶 TÍTULO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (urgente)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "URGENTE",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(descripcion),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16),
                  Text(" $ubicacion"),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16),
                  Text(salario),
                ],
              )
            ],
          ),

          const SizedBox(height: 12),

          if (fechaLimite.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 16),
                  const SizedBox(width: 4),
                  Text("Fecha límite: $fechaLimite"),
                ],
              ),
            ),

          // 👉 BOTÓN VER MÁS
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostularOfertaScreen(
                      trabajoId: trabajoId,
                      titulo: titulo,
                      categoria: categoria,
                      empresa: empresa,
                      ubicacion: ubicacion,
                      salario: salario,
                      descripcion: descripcion,
                      fechaLimite: fechaLimite.isEmpty ? null : fechaLimite,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text("Ver más"),
            ),
          ),
        ],
      ),
    );
  }
}

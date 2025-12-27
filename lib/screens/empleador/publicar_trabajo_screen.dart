import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'mis_publicaciones_screen.dart';

// 👉 EMULADOR (si usas cel físico cambia a 192.168.100.22)
const String baseUrl = "http://10.0.2.2:4000";

class PublicarTrabajoScreen extends StatefulWidget {
  const PublicarTrabajoScreen({super.key});

  @override
  State<PublicarTrabajoScreen> createState() => _PublicarTrabajoScreenState();
}

class _PublicarTrabajoScreenState extends State<PublicarTrabajoScreen> {
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final ubicacionCtrl = TextEditingController();
  final salarioCtrl = TextEditingController();
  String categoria = "";

  DateTime? fechaLimite;

  bool loading = false;

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  Future<void> _pickFechaLimite() async {
    final ahora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaLimite ?? ahora,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: DateTime(ahora.year + 5),
    );
    if (picked != null) {
      setState(() => fechaLimite = picked);
    }
  }

  // ============================
  // PUBLICAR TRABAJO
  // ============================
  Future<void> publicar() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // 1️⃣ Verificamos que haya sesión
    if (auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: userId no encontrado")),
      );
      return;
    }

    // 2️⃣ Validar campos
    if (tituloCtrl.text.trim().isEmpty ||
        descripcionCtrl.text.trim().isEmpty ||
        ubicacionCtrl.text.trim().isEmpty ||
        salarioCtrl.text.trim().isEmpty ||
        categoria.isEmpty ||
        fechaLimite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos (incluye fecha límite)")),
      );
      return;
    }

    setState(() => loading = true);

    final url = Uri.parse("$baseUrl/api/trabajos");

    // ✅ Enviamos el userId del usuario logueado
    final body = {
      "titulo": tituloCtrl.text.trim(),
      "descripcion": descripcionCtrl.text.trim(),
      "ubicacion": ubicacionCtrl.text.trim(),
      "salario": salarioCtrl.text.trim(),
      "categoria": categoria,
      "fechaLimite": _fmtDate(fechaLimite!),
      "userId": auth.userId, // 👈 IMPORTANTE: userId, ya no 7 ni empleadorId aquí
    };

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    setState(() => loading = false);

    print("📌 RESP PUBLICAR → ${resp.statusCode} | ${resp.body}");

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trabajo publicado correctamente")),
      );

      // Ir directamente a Mis Publicaciones
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MisPublicacionesScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${resp.body}")),
      );
    }
  }

  Widget inputBox(
    String label,
    TextEditingController c, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: c,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    ubicacionCtrl.dispose();
    salarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F0FF),
      appBar: AppBar(
        title: const Text("Publicar Trabajo"),
        backgroundColor: const Color(0xff6A4CE8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            inputBox("Título del trabajo", tituloCtrl),
            inputBox("Descripción detallada", descripcionCtrl, maxLines: 4),

            Row(
              children: [
                Expanded(
                  child: inputBox("Ubicación", ubicacionCtrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: inputBox(
                    "Presupuesto (\$)",
                    salarioCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            // 📅 Fecha límite
            const Text(
              "Fecha límite",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickFechaLimite,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      fechaLimite == null
                          ? "Selecciona una fecha"
                          : _fmtDate(fechaLimite!),
                      style: TextStyle(
                        color: fechaLimite == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Categoría",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: categoria.isEmpty ? null : categoria,
                underline: const SizedBox(),
                hint: const Text("Selecciona categoría"),
                items: const [
                  "Electricidad",
                  "Plomería",
                  "Pintura",
                  "Limpieza",
                  "Construcción",
                ].map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                ).toList(),
                onChanged: (v) => setState(() => categoria = v ?? ""),
              ),
            ),

            const SizedBox(height: 30),

            GestureDetector(
              onTap: loading ? null : publicar,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Publicar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

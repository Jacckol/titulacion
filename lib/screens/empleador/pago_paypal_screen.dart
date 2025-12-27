import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../providers/auth_provider.dart';

const String baseUrl = "http://10.0.2.2:4000/api";

class PagoPayPalScreen extends StatefulWidget {
  final int trabajadorId;
  final int trabajoId; // ✅ ES UN TRABAJO, NO SERVICIO

  const PagoPayPalScreen({
    super.key,
    required this.trabajadorId,
    required this.trabajoId,
  });

  @override
  State<PagoPayPalScreen> createState() => _PagoPayPalScreenState();
}

class _PagoPayPalScreenState extends State<PagoPayPalScreen> {
  final TextEditingController montoCtrl = TextEditingController();
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController tarjetaCtrl = TextEditingController();
  final TextEditingController cvvCtrl = TextEditingController();

  bool cargando = false;

  @override
  void dispose() {
    montoCtrl.dispose();
    nombreCtrl.dispose();
    tarjetaCtrl.dispose();
    cvvCtrl.dispose();
    super.dispose();
  }

  // ======================================================
  // 🔥 PROCESAR PAGO (EMPLEADOR → TRABAJADOR)
  // ======================================================
  Future<void> procesarPago() async {
    final double? monto = double.tryParse(montoCtrl.text);

    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa un monto válido"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    if (auth.token == null || auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sesión no válida"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final resp = await http.post(
        Uri.parse("$baseUrl/transactions"),
        headers: {
          "Authorization": "Bearer ${auth.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          // ✅ EXACTAMENTE lo que espera tu backend
          "empleadorId": auth.userId,
          "trabajadorId": widget.trabajadorId,
          "monto": monto,
          "descripcion": "Pago por trabajo (PayPal simulado)",
          "trabajoId": widget.trabajoId, // 🔥 CLAVE
        }),
      );

      if (!mounted) return;
      setState(() => cargando = false);

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Pago realizado con éxito"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error al pagar: ${resp.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ No se pudo conectar al servidor"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ======================================================
  // 🧱 UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pago PayPal (Simulado)"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Monto a pagar",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: montoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Ej: 30.00",
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Datos de tarjeta (Simulado)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nombre en la tarjeta",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: tarjetaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Número de tarjeta",
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: cvvCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "CVV",
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cargando ? null : procesarPago,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Confirmar Pago",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
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

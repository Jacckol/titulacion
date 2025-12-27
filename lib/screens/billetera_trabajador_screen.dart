import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'cuenta_bancaria_trabajador_screen.dart';

import '../providers/transactions_provider.dart';
import '../providers/auth_provider.dart';

class BilleteraTrabajadorScreen extends StatefulWidget {
  const BilleteraTrabajadorScreen({super.key});

  @override
  State<BilleteraTrabajadorScreen> createState() =>
      _BilleteraTrabajadorScreenState();
}

class _BilleteraTrabajadorScreenState
    extends State<BilleteraTrabajadorScreen> {

  String? _miQrCuentaUrl;

  @override
  void initState() {
    super.initState();

    // 🔥 CARGAR INGRESOS DEL TRABAJADOR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context
          .read<TransactionsProvider>()
          .cargarTransacciones(auth.token!);
      context.read<TransactionsProvider>().cargarPendientes(auth.token!);

      _cargarMiQr(auth.token!);
    });
  }

  Future<void> _cargarMiQr(String token) async {
    try {
      final resp = await http.get(
        Uri.parse("http://10.0.2.2:4000/api/perfil/mine"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data["qrCuentaUrl"] != null) {
          final q = data["qrCuentaUrl"].toString();
          if (q.trim().isNotEmpty && mounted) {
            setState(() => _miQrCuentaUrl = q);
          }
        }
      }
    } catch (_) {}
  }

  void _verQrDialog(String url) {
    final full = url.startsWith("http") ? url : "http://10.0.2.2:4000$url";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Mi QR"),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(full, fit: BoxFit.contain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transProv = context.watch<TransactionsProvider>();

    // 🔹 SOLO INGRESOS
    final ingresos = transProv.transacciones
        .where((t) => t["tipo"] == "ingreso")
        .toList();

    // 🔹 PENDIENTES
    final pendientes = transProv.pendientes
        .where((t) => t["tipo"] == "ingreso")
        .toList();


    // 🔹 TOTAL INGRESOS
    final totalIngreso = ingresos.fold<double>(
      0,
      (sum, t) => sum + (t["monto"] as num).toDouble(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Mi Billetera (Trabajador)",
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: transProv.loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "Resumen Financiero",
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),
                  const Text(
                    "Tus ingresos generados por servicios",
                    style:
                        TextStyle(fontSize: 15, color: Colors.black54),
                  ),

                  const SizedBox(height: 25),

                  /// ============================
                  /// RESUMEN
                  /// ============================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _cardResumen(
                        "Total Ingreso",
                        "\$${totalIngreso.toStringAsFixed(2)}",
                        "Acumulado",
                        Icons.attach_money,
                        iconColor: Colors.green,
                      ),
                      _cardResumen(
                        "Servicios",
                        ingresos.length.toString(),
                        "Pagados",
                        Icons.task_alt,
                        iconColor: Colors.blue,
                      ),
                      _cardResumen(
                        "Estado",
                        ingresos.isEmpty ? "0%" : "↑",
                        "Activo",
                        Icons.trending_up,
                        iconColor: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.account_balance),
                      label: const Text("Configurar cuenta bancaria"),
                      onPressed: () {
                        final auth = context.read<AuthProvider>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CuentaBancariaTrabajadorScreen()),
                        ).then((_) {
                          if (auth.token != null) {
                            _cargarMiQr(auth.token!);
                          }
                        });
                      },
                    ),
                  ),

                  if (_miQrCuentaUrl != null && _miQrCuentaUrl!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text("Ver mi QR"),
                        onPressed: () => _verQrDialog(_miQrCuentaUrl!),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ============================
                  // 🔥 PAGOS PENDIENTES
                  // ============================
                  if (pendientes.isNotEmpty) ...[
                    const Text(
                      "Pagos pendientes",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...pendientes.take(5).map((t) {
                      final m = (t["monto"] as num).toDouble();
                      final f = DateFormat('dd/MM/yyyy')
                          .format(DateTime.parse(t["createdAt"]));
                      return _itemIngreso(
                        t["descripcion"] ?? "Pago pendiente",
                        "En espera",
                        m,
                        f,
                        null,
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    "Historial de Ingresos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ingresos.isEmpty
                      ? _itemIngreso(
                          "Sin ingresos aún",
                          "Aún no te han pagado",
                          0,
                          "--/--/----",
                          null,
                        )
                      : Column(
                          children: ingresos.map((t) {
                            return _itemIngreso(
                              t["descripcion"] ?? "Pago recibido",
                              "Empleador",
                              (t["monto"] as num).toDouble(),
                              DateFormat('dd/MM/yyyy')
                                  .format(DateTime.parse(t["createdAt"])),
                              t["comprobanteUrl"],
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ======================================================
  // TARJETA RESUMEN
  // ======================================================
  Widget _cardResumen(
    String titulo,
    String total,
    String descripcion,
    IconData icon, {
    Color iconColor = Colors.blue,
  }) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(height: 10),
          Text(
            total,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // ITEM INGRESO
  // ======================================================
  Widget _itemIngreso(
      String titulo, String cliente, double precio, String fecha, dynamic comprobanteUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.arrow_downward,
                    color: Colors.green),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    cliente,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${precio.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              Text(
                fecha,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black54),
              ),

if (comprobanteUrl != null && comprobanteUrl.toString().trim().isNotEmpty) ...[
  const SizedBox(height: 6),
  TextButton(
    onPressed: () {
      final full = comprobanteUrl.toString().startsWith("http")
          ? comprobanteUrl.toString()
          : "http://10.0.2.2:4000" + comprobanteUrl.toString();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Comprobante de pago"),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(full, fit: BoxFit.contain),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        ),
      );
    },
    child: const Text("Ver comprobante"),
  ),
],
            ],
          ),
        ],
      ),
    );
  }
}
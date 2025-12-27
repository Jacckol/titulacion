import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../providers/transactions_provider.dart';
import '../../providers/auth_provider.dart';

import 'pago_paypal_screen.dart';
import 'pago_transferencia_screen.dart';
import 'historial_transacciones_screen.dart';
import 'cuenta_bancaria_empleador_screen.dart';

class MiBilleteraEmpleadorScreen extends StatefulWidget {
  const MiBilleteraEmpleadorScreen({super.key});

  @override
  State<MiBilleteraEmpleadorScreen> createState() =>
      _MiBilleteraEmpleadorScreenState();
}

class _MiBilleteraEmpleadorScreenState
    extends State<MiBilleteraEmpleadorScreen>
    with SingleTickerProviderStateMixin {

  String? _miQrCuentaUrl;

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final transProv =
        Provider.of<TransactionsProvider>(context, listen: false);

    transProv.cargarTransacciones(auth.token!);
    transProv.cargarPendientes(auth.token!);

    if (auth.token != null) {
      _cargarMiQr(auth.token!);
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transProv = Provider.of<TransactionsProvider>(context);
    final trans = transProv.transacciones;
    final pendientes = transProv.pendientes
        .where((t) => t["tipo"] == "gasto")
        .toList();

    double totalGastos = 0;
    for (var t in trans) {
      if (t["tipo"] == "gasto") {
        totalGastos += (t["monto"] as num).toDouble();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FF),
      appBar: AppBar(
        title: const Text(
          "Mi Billetera",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6D4AFF),
        elevation: 0,
      ),
      body: transProv.loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardGlassResumen(totalGastos),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.account_balance),
                        label: const Text("Configurar mi cuenta/QR"),
                        onPressed: () {
                          final auth = context.read<AuthProvider>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CuentaBancariaEmpleadorScreen(),
                            ),
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

                    const SizedBox(height: 18),

                    // ==================================================
                    // 🔥 PAGOS PENDIENTES (TRANSFERENCIA SIMULADA)
                    // ==================================================
                    if (pendientes.isNotEmpty) ...[
                      const Text(
                        "Pagos pendientes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...pendientes.take(5).map((t) {
                        final monto = (t["monto"] as num).toDouble();
                        final destinoId = t["destinoUserId"] as int?;
                        final trabajoId = t["trabajoId"] as int?;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title: Text(t["descripcion"] ?? "Pago pendiente"),
                            subtitle: Text(
                              trabajoId != null
                                  ? "Trabajo #$trabajoId"
                                  : "Servicio",
                            ),
                            trailing: ElevatedButton(
                              onPressed: destinoId == null
                                  ? null
                                  : () async {
                                      final auth = context.read<AuthProvider>();
                                      final ok = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PagoTransferenciaScreen(
                                            trabajadorId: destinoId,
                                            trabajoId: trabajoId,
                                            montoSugerido: monto,
                                          ),
                                        ),
                                      );
                                      if (ok == true && auth.token != null) {
                                        await transProv.cargarTransacciones(auth.token!);
                                        await transProv.cargarPendientes(auth.token!);
                                      }
                                    },
                              child: Text("Pagar \$${monto.toStringAsFixed(2)}"),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                    ],

                    // ======================
                    // 🔥 PAGOS PENDIENTES
                    // ======================
                    if (pendientes.isNotEmpty) ...[
                      const Text(
                        "Pagos Pendientes",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendientes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = pendientes[i];
                            final monto = (p["monto"] as num).toDouble();
                            final trabajoId = p["trabajoId"];
                            final trabajadorId = p["destinoUserId"];
                            return ListTile(
                              title: Text(p["descripcion"] ?? "Pago pendiente"),
                              subtitle: Text(
                                trabajoId == null
                                    ? "Servicio"
                                    : "Trabajo #$trabajoId",
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PagoTransferenciaScreen(
                                        trabajadorId: trabajadorId,
                                        trabajoId: trabajoId,
                                        montoSugerido: monto,
                                      ),
                                    ),
                                  ).then((ok) {
                                    if (ok == true) {
                                      final auth = context.read<AuthProvider>();
                                      context
                                          .read<TransactionsProvider>()
                                          .cargarTransacciones(auth.token!);
                                      context
                                          .read<TransactionsProvider>()
                                          .cargarPendientes(auth.token!);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6D4AFF),
                                ),
                                child: const Text(
                                  "Pagar",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],

                    // 🔥 BOTÓN PAGO (FIX FINAL)
                    _botonGradiente(
                      text: "Pagar con PayPal (Simulado)",
                      icon: Icons.payment,
                      colors: const [
                        Color(0xFF6D4AFF),
                        Color(0xFF9D7BFF),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PagoPayPalScreen(
                              trabajadorId: 0, // dummy
                              trabajoId: 0,    // 🔥 FIX CLAVE
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    _botonGradiente(
                      text: "Ver Historial Completo",
                      icon: Icons.history,
                      colors: const [Colors.black87, Colors.black54],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const HistorialTransaccionesScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Últimos Gastos",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: ListView.builder(
                        itemCount: trans.length,
                        itemBuilder: (_, i) {
                          final t = trans[i];
                          if (t["tipo"] != "gasto") return const SizedBox();
                          final comprobanteUrl = t["comprobanteUrl"];
                          return ListTile(
                            title: Text(t["descripcion"] ?? "Pago"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t["createdAt"].toString().substring(0, 10),
                                ),
                                if (comprobanteUrl != null && comprobanteUrl.toString().trim().isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      final full = comprobanteUrl
                                              .toString()
                                              .startsWith("http")
                                          ? comprobanteUrl.toString()
                                          : "http://10.0.2.2:4000" +
                                              comprobanteUrl.toString();
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Comprobante de pago"),
                                          content: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(full,
                                                fit: BoxFit.contain),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("Cerrar"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child:
                                        const Text("Ver comprobante"),
                                  ),
                              ],
                            ),
                            trailing: Text(
                              "-\$${(t["monto"] as num).toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ================= UI =================

  Widget _cardGlassResumen(double total) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wallet, size: 40, color: Colors.white),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Gastado",
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                "\$${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonGradiente({
    required String text,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

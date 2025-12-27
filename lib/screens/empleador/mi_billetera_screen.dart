import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _MiBilleteraEmpleadorScreenState extends State<MiBilleteraEmpleadorScreen>
    with SingleTickerProviderStateMixin {
  static const _apiBase = "http://10.0.2.2:4000";

  String? _miQrCuentaUrl;

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Cargar data al inicio
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarTodo());
  }

  Future<void> _cargarTodo() async {
    final auth = context.read<AuthProvider>();
    final transProv = context.read<TransactionsProvider>();
    final token = auth.token;

    if (token == null || token.trim().isEmpty) return;

    await transProv.cargarTransacciones(token);
    await transProv.cargarPendientes(token);
    await _cargarMiQr(token);
  }

  Future<void> _cargarMiQr(String token) async {
    try {
      final resp = await http.get(
        Uri.parse("$_apiBase/api/perfil/mine"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data["qrCuentaUrl"] != null) {
          final q = data["qrCuentaUrl"].toString().trim();
          if (q.isNotEmpty && mounted) {
            setState(() => _miQrCuentaUrl = q);
          }
        }
      }
    } catch (_) {
      // Silencioso (si quieres, puedes mostrar SnackBar)
    }
  }

  String _money(num v) => "\$${v.toStringAsFixed(2)}";

  String _dateOnly(dynamic createdAt) {
    final s = (createdAt ?? "").toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  String _fullUrl(String url) {
    final u = url.trim();
    if (u.startsWith("http")) return u;
    return "$_apiBase$u";
  }

  void _verImagenDialog({
    required String title,
    required String url,
  }) {
    final full = _fullUrl(url);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              full,
              fit: BoxFit.contain,
              loadingBuilder: (c, w, p) {
                if (p == null) return w;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Text("No se pudo cargar la imagen"),
              ),
            ),
          ),
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

  Future<void> _irConfigCuentaQR() async {
    final auth = context.read<AuthProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CuentaBancariaEmpleadorScreen()),
    );

    if (!mounted) return;
    if (auth.token != null) {
      await _cargarMiQr(auth.token!);
    }
  }

  Future<void> _pagarPendiente({
    required int trabajadorId,
    required int? trabajoId,
    required double montoSugerido,
  }) async {
    final auth = context.read<AuthProvider>();
    final transProv = context.read<TransactionsProvider>();

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PagoTransferenciaScreen(
          trabajadorId: trabajadorId,
          trabajoId: trabajoId,
          montoSugerido: montoSugerido,
        ),
      ),
    );

    if (ok == true && auth.token != null) {
      await transProv.cargarTransacciones(auth.token!);
      await transProv.cargarPendientes(auth.token!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ========================= UI =========================

  @override
  Widget build(BuildContext context) {
    final transProv = context.watch<TransactionsProvider>();

    final trans = transProv.transacciones;
    final gastos = trans.where((t) => t["tipo"] == "gasto").toList();

    final pendientes = (transProv.pendientes)
        .where((t) => t["tipo"] == "gasto")
        .toList();

    double totalGastos = 0;
    for (final t in gastos) {
      final monto = (t["monto"] as num?) ?? 0;
      totalGastos += monto.toDouble();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text(
          "Mi Billetera",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF6D4AFF),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D4AFF), Color(0xFF9D7BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: transProv.loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fade,
              child: RefreshIndicator(
                onRefresh: _cargarTodo,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ResumenCard(totalGastos: totalGastos),
                            const SizedBox(height: 14),

                            // Acciones cuenta / QR
                            _ActionRow(
                              onConfigCuenta: _irConfigCuentaQR,
                              onVerQr: (_miQrCuentaUrl != null &&
                                      _miQrCuentaUrl!.trim().isNotEmpty)
                                  ? () => _verImagenDialog(
                                        title: "Mi QR",
                                        url: _miQrCuentaUrl!,
                                      )
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Pendientes (UNA sola sección)
                            if (pendientes.isNotEmpty) ...[
                              _SectionHeader(
                                title: "Pagos pendientes",
                                subtitle:
                                    "Transacciones por completar (transferencia simulada).",
                              ),
                              const SizedBox(height: 10),
                              _PendientesCard(
                                pendientes: pendientes,
                                onPagar: (trabajadorId, trabajoId, monto) =>
                                    _pagarPendiente(
                                  trabajadorId: trabajadorId,
                                  trabajoId: trabajoId,
                                  montoSugerido: monto,
                                ),
                                money: _money,
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Botones grandes
                            _GradientButton(
                              text: "Pagar con PayPal (Simulado)",
                              icon: Icons.payment,
                              colors: const [Color(0xFF6D4AFF), Color(0xFF9D7BFF)],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PagoPayPalScreen(
                                      trabajadorId: 0,
                                      trabajoId: 0,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _GradientButton(
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
                            const SizedBox(height: 18),

                            _SectionHeader(
                              title: "Últimos gastos",
                              subtitle: "Tus pagos realizados recientemente.",
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // Lista de gastos
                    if (gastos.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
                          child: _EmptyState(
                            title: "Sin gastos aún",
                            subtitle: "Cuando realices pagos, se verán aquí.",
                            icon: Icons.receipt_long,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
                        sliver: SliverList.separated(
                          itemCount: gastos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final t = gastos[i];
                            final desc = (t["descripcion"] ?? "Pago").toString();
                            final monto = ((t["monto"] as num?) ?? 0).toDouble();
                            final createdAt = t["createdAt"];
                            final comprobanteUrl = t["comprobanteUrl"];

                            return _TransaccionTile(
                              descripcion: desc,
                              fecha: _dateOnly(createdAt),
                              monto: monto,
                              onVerComprobante: (comprobanteUrl != null &&
                                      comprobanteUrl.toString().trim().isNotEmpty)
                                  ? () => _verImagenDialog(
                                        title: "Comprobante de pago",
                                        url: comprobanteUrl.toString(),
                                      )
                                  : null,
                              money: _money,
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
}

// ========================= Widgets UI =========================

class _ResumenCard extends StatelessWidget {
  final double totalGastos;

  const _ResumenCard({required this.totalGastos});

  String _money(num v) => "\$${v.toStringAsFixed(2)}";

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D4AFF), Color(0xFF9D7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.wallet, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total gastado",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(totalGastos),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.trending_down, color: Colors.white70),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onConfigCuenta;
  final VoidCallback? onVerQr;

  const _ActionRow({
    required this.onConfigCuenta,
    required this.onVerQr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.account_balance),
            label: const Text("Cuenta / QR"),
            onPressed: onConfigCuenta,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_2),
            label: const Text("Ver mi QR"),
            onPressed: onVerQr,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PendientesCard extends StatefulWidget {
  final List<dynamic> pendientes;
  final void Function(int trabajadorId, int? trabajoId, double monto) onPagar;
  final String Function(num v) money;

  const _PendientesCard({
    required this.pendientes,
    required this.onPagar,
    required this.money,
  });

  @override
  State<_PendientesCard> createState() => _PendientesCardState();
}

class _PendientesCardState extends State<_PendientesCard> {
  bool _verTodos = false;

  @override
  Widget build(BuildContext context) {
    final items = _verTodos ? widget.pendientes : widget.pendientes.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = items[i] as Map;
              final desc = (p["descripcion"] ?? "Pago pendiente").toString();
              final monto = ((p["monto"] as num?) ?? 0).toDouble();
              final trabajoId = p["trabajoId"] as int?;
              final destinoId = p["destinoUserId"] as int?;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D4AFF).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pending_actions, color: Color(0xFF6D4AFF)),
                ),
                title: Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  trabajoId != null ? "Trabajo #$trabajoId" : "Servicio",
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: ElevatedButton(
                  onPressed: (destinoId == null)
                      ? null
                      : () => widget.onPagar(destinoId, trabajoId, monto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D4AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Pagar ${widget.money(monto)}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),

          if (widget.pendientes.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => setState(() => _verTodos = !_verTodos),
                  icon: Icon(_verTodos ? Icons.expand_less : Icons.expand_more),
                  label: Text(_verTodos ? "Ver menos" : "Ver todos (${widget.pendientes.length})"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _GradientButton({
    required this.text,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransaccionTile extends StatelessWidget {
  final String descripcion;
  final String fecha;
  final double monto;
  final VoidCallback? onVerComprobante;
  final String Function(num v) money;

  const _TransaccionTile({
    required this.descripcion,
    required this.fecha,
    required this.monto,
    required this.onVerComprobante,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.payments, color: Colors.red),
          ),
          title: Text(
            descripcion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fecha, style: const TextStyle(color: Colors.black54)),
              if (onVerComprobante != null)
                TextButton(
                  onPressed: onVerComprobante,
                  child: const Text("Ver comprobante"),
                ),
            ],
          ),
          trailing: Text(
            "-${money(monto)}",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

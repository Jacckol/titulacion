import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/transactions_provider.dart';

class HistorialTransaccionesScreen extends StatefulWidget {
  const HistorialTransaccionesScreen({super.key});

  @override
  State<HistorialTransaccionesScreen> createState() =>
      _HistorialTransaccionesScreenState();
}

class _HistorialTransaccionesScreenState extends State<HistorialTransaccionesScreen> {
  static const String _apiBase = "http://10.0.2.2:4000";

  String filtroMes = "todos";

  final List<String> meses = const [
    "todos",
    "enero",
    "febrero",
    "marzo",
    "abril",
    "mayo",
    "junio",
    "julio",
    "agosto",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    final transProv = context.read<TransactionsProvider>();
    if (auth.token == null) return;
    await transProv.cargarTransacciones(auth.token!);
  }

  String _fullUrl(String url) {
    final u = url.trim();
    if (u.startsWith("http")) return u;
    return "$_apiBase$u";
  }

  void _verComprobanteDialog(String comprobanteUrl) {
    final full = _fullUrl(comprobanteUrl);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Comprobante de pago"),
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
                child: Text("No se pudo cargar el comprobante"),
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

  @override
  Widget build(BuildContext context) {
    final transProv = context.watch<TransactionsProvider>();
    var trans = List<Map<String, dynamic>>.from(transProv.transacciones);

    // ✅ Filtrar solo gastos (si quieres ver TODO, borra esta parte)
    // Si tu historial debe mostrar ingresos también, comenta estas 2 líneas:
    // trans = trans.where((t) => (t["tipo"] ?? "").toString() == "gasto").toList();

    // FILTRO POR MES
    if (filtroMes != "todos") {
      trans = trans.where((t) {
        final created = (t["createdAt"] ?? "").toString();
        if (created.isEmpty) return false;
        final fecha = DateTime.tryParse(created);
        if (fecha == null) return false;
        final nombreMes = meses[fecha.month].toLowerCase();
        return nombreMes == filtroMes;
      }).toList();
    }

    // Ordenar más nuevo primero (si ya viene ordenado, no pasa nada)
    trans.sort((a, b) {
      final fa = DateTime.tryParse((a["createdAt"] ?? "").toString()) ?? DateTime(1970);
      final fb = DateTime.tryParse((b["createdAt"] ?? "").toString()) ?? DateTime(1970);
      return fb.compareTo(fa);
    });

    double total = 0;
    for (final t in trans) {
      total += ((t["monto"] as num?) ?? 0).toDouble();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text(
          "Historial de Transacciones",
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
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _ResumenHistorialCard(
                    total: total,
                    cantidad: trans.length,
                    filtroMes: filtroMes,
                  ),
                  const SizedBox(height: 14),

                  // FILTRO MES
                  Container(
                    padding: const EdgeInsets.all(14),
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
                    child: DropdownButtonFormField<String>(
                      value: filtroMes,
                      onChanged: (String? v) {
                        if (v == null) return;
                        setState(() => filtroMes = v);
                      },
                      items: meses
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: "Filtrar por mes",
                        prefixIcon: const Icon(Icons.calendar_month),
                        filled: true,
                        fillColor: const Color(0xFFF5F3FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF6D4AFF), width: 1.6),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // LISTA DE TRANSACCIONES
                  if (trans.isEmpty)
                    const _EmptyState(
                      title: "No hay transacciones",
                      subtitle: "Cuando realices pagos, se verán aquí.",
                      icon: Icons.receipt_long,
                    )
                  else
                    ...List.generate(trans.length, (i) {
                      final t = trans[i];
                      final comprobanteUrl = t["comprobanteUrl"];
                      final createdAt = (t["createdAt"] ?? "").toString();
                      final dt = DateTime.tryParse(createdAt);
                      final fecha = dt == null
                          ? createdAt
                          : DateFormat("yyyy-MM-dd").format(dt);

                      final monto = ((t["monto"] as num?) ?? 0).toDouble();
                      final desc = (t["descripcion"] ?? "Transacción").toString();

                      // si tienes "tipo": gasto/ingreso
                      final tipo = (t["tipo"] ?? "gasto").toString().toLowerCase();
                      final esGasto = tipo == "gasto";

                      return _AnimatedAppear(
                        delayMs: i * 30,
                        child: _TransaccionCard(
                          descripcion: desc,
                          fecha: fecha,
                          monto: monto,
                          esGasto: esGasto,
                          onVerComprobante: (comprobanteUrl != null &&
                                  comprobanteUrl.toString().trim().isNotEmpty)
                              ? () => _verComprobanteDialog(comprobanteUrl.toString())
                              : null,
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

// ========================= UI WIDGETS =========================

class _ResumenHistorialCard extends StatelessWidget {
  final double total;
  final int cantidad;
  final String filtroMes;

  const _ResumenHistorialCard({
    required this.total,
    required this.cantidad,
    required this.filtroMes,
  });

  String _money(num v) => "\$${v.toStringAsFixed(2)}";

  @override
  Widget build(BuildContext context) {
    final titulo = filtroMes == "todos"
        ? "Resumen general"
        : "Resumen: ${filtroMes.toUpperCase()}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D4AFF), Color(0xFF9D7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
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
            child: const Icon(Icons.insights, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Total: ${_money(total)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Transacciones: $cantidad",
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransaccionCard extends StatelessWidget {
  final String descripcion;
  final String fecha;
  final double monto;
  final bool esGasto;
  final VoidCallback? onVerComprobante;

  const _TransaccionCard({
    required this.descripcion,
    required this.fecha,
    required this.monto,
    required this.esGasto,
    required this.onVerComprobante,
  });

  String _money(num v) => "\$${v.toStringAsFixed(2)}";

  @override
  Widget build(BuildContext context) {
    final icon = esGasto ? Icons.payments : Icons.savings;
    final badgeText = esGasto ? "GASTO" : "INGRESO";
    final badgeBg = esGasto ? Colors.red.withOpacity(0.10) : Colors.green.withOpacity(0.10);
    final badgeFg = esGasto ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6D4AFF).withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF6D4AFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      fecha,
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeFg,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (onVerComprobante != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onVerComprobante,
                      icon: const Icon(Icons.visibility),
                      label: const Text("Ver comprobante"),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            esGasto ? "-${_money(monto)}" : "+${_money(monto)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: esGasto ? Colors.red : Colors.green,
            ),
          ),
        ],
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Animación liviana (sin controllers por item)
class _AnimatedAppear extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _AnimatedAppear({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, child) {
        final offsetY = (1 - v) * 12;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          ),
        );
      },
      // Pequeño delay simulando cascada
      onEnd: () {},
    );
  }
}

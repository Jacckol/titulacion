import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

class _BilleteraTrabajadorScreenState extends State<BilleteraTrabajadorScreen> {
  static const _apiBase = "http://10.0.2.2:4000";

  String? _miQrCuentaUrl;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) return;

      await context.read<TransactionsProvider>().cargarTransacciones(token);
      await context.read<TransactionsProvider>().cargarPendientes(token);
      await _cargarMiQr(token);
    });
  }

  // ================== HELPERS ==================

  String _s(dynamic v, {String fallback = ""}) {
    final s = (v ?? "").toString().trim();
    return s.isEmpty ? fallback : s;
  }

  // ✅ clave para comparar items y evitar duplicados (pendiente vs historial)
  String _keyFrom(Map t) {
    final id = t["id"];
    if (id != null) return "id:$id";

    final trabajoId = t["trabajoId"];
    final servicioId = t["servicioId"];
    final createdAt = _s(t["createdAt"]);
    final monto = _s(t["monto"]);
    return "k:$trabajoId|$servicioId|$createdAt|$monto";
  }

  bool _isPendiente(Map t) {
    final e = _s(t["estado"]).toLowerCase();
    if (e.isEmpty) return false;
    return e.contains("pend") || e.contains("espera") || e.contains("waiting");
  }

  /// ✅ Texto final bonito:
  /// "Pago pendiente por trabajo: Juan" -> "Pago recibido por: Juan"
  /// Quita "pendiente" si viene suelto y limpia espacios.
  String _cleanTitulo(String raw) {
    var desc = raw.trim();

    // Reemplazo principal
    desc = desc.replaceAll(
      RegExp(
        r'^pago\s+pendiente\s+por\s+trabajo:\s*',
        caseSensitive: false,
      ),
      "Pago recibido por: ",
    );

    // Por si viene "pago por trabajo:" (otras variantes)
    desc = desc.replaceAll(
      RegExp(
        r'^pago\s+por\s+trabajo:\s*',
        caseSensitive: false,
      ),
      "Pago recibido por: ",
    );

    // quitar la palabra "pendiente" suelta
    desc = desc.replaceAll(
      RegExp(r'\bpendiente\b', caseSensitive: false),
      "",
    );

    // limpiar dobles espacios
    desc = desc.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    // si por alguna razón queda solo "Pago recibido por:" sin nombre
    if (desc.toLowerCase() == "pago recibido por:" ||
        desc.toLowerCase() == "pago recibido por") {
      return "Pago recibido";
    }

    return desc.isEmpty ? "Pago recibido" : desc;
  }

  // ================== API ==================

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
    } catch (_) {}
  }

  String _fullUrl(String url) {
    final u = url.trim();
    if (u.startsWith("http")) return u;
    return "$_apiBase$u";
  }

  void _verImagenDialog({required String titulo, required String url}) {
    final full = _fullUrl(url);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
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
              errorBuilder: (_, __, ___) =>
                  const Center(child: Text("No se pudo cargar la imagen")),
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

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    await context.read<TransactionsProvider>().cargarTransacciones(token);
    await context.read<TransactionsProvider>().cargarPendientes(token);
    await _cargarMiQr(token);
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final transProv = context.watch<TransactionsProvider>();

    // ✅ SOLO INGRESOS (RAW)
    final ingresosAll = transProv.transacciones
        .where((t) => _s(t["tipo"]) == "ingreso")
        .toList();

    // ✅ PENDIENTES INGRESO (RAW)
    final pendientesAll = transProv.pendientes
        .where((t) => _s(t["tipo"]) == "ingreso")
        .toList();

    // ✅ si el backend manda "estado", filtramos SOLO los realmente pendientes
    final hayEstadoEnPendientes =
        pendientesAll.any((p) => _s(p["estado"]).isNotEmpty);

    final pendientes = hayEstadoEnPendientes
        ? pendientesAll
            .where((p) => _isPendiente(Map<String, dynamic>.from(p)))
            .toList()
        : pendientesAll;

    // ✅ keys de pendientes para NO repetir en historial
    final pendingKeys = <String>{};
    for (final p in pendientes) {
      pendingKeys.add(_keyFrom(Map<String, dynamic>.from(p)));
    }

    // ✅ INGRESOS filtrados: si está en pendientes, NO va al historial
    final ingresos = ingresosAll.where((t0) {
      final t = Map<String, dynamic>.from(t0);
      final key = _keyFrom(t);

      if (pendingKeys.contains(key)) return false; // no duplicar
      if (_isPendiente(t)) return false; // si viene estado pendiente, fuera
      return true;
    }).toList();

    final totalIngreso = ingresos.fold<double>(
      0,
      (sum, t) => sum + ((t["monto"] as num?) ?? 0).toDouble(),
    );

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
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _ResumenTrabajadorCard(
                    totalIngreso: totalIngreso,
                    ingresosCount: ingresos.length,
                    pendientesCount: pendientes.length,
                  ),
                  const SizedBox(height: 14),

                  // Acciones Cuenta/QR
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.account_balance),
                          label: const Text("Cuenta / QR"),
                          onPressed: () {
                            final auth = context.read<AuthProvider>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CuentaBancariaTrabajadorScreen(),
                              ),
                            ).then((_) {
                              if (auth.token != null) {
                                _cargarMiQr(auth.token!);
                              }
                            });
                          },
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
                          onPressed: (_miQrCuentaUrl != null &&
                                  _miQrCuentaUrl!.trim().isNotEmpty)
                              ? () => _verImagenDialog(
                                    titulo: "Mi QR",
                                    url: _miQrCuentaUrl!,
                                  )
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ==========================
                  // PENDIENTES
                  // ==========================
                  if (pendientes.isNotEmpty) ...[
                    const _SectionHeader(
                      title: "Pagos pendientes",
                      subtitle: "Ingresos aún en espera de confirmación.",
                    ),
                    const SizedBox(height: 10),
                    _ListaPendientes(
                      pendientes: pendientes,
                      cleanTitulo: _cleanTitulo,
                    ),
                    const SizedBox(height: 16),
                  ],

                  const _SectionHeader(
                    title: "Historial de ingresos",
                    subtitle: "Pagos recibidos por tus servicios.",
                  ),
                  const SizedBox(height: 10),

                  if (ingresos.isEmpty)
                    const _EmptyState(
                      title: "Sin ingresos aún",
                      subtitle:
                          "Cuando te paguen por un servicio, se verá aquí.",
                      icon: Icons.savings,
                    )
                  else
                    ...List.generate(ingresos.length, (i) {
                      final t = Map<String, dynamic>.from(ingresos[i]);

                      final descRaw =
                          (t["descripcion"] ?? "Pago recibido").toString();
                      final desc = _cleanTitulo(descRaw);

                      final monto = ((t["monto"] as num?) ?? 0).toDouble();

                      final createdAt = (t["createdAt"] ?? "").toString();
                      final dt = DateTime.tryParse(createdAt);
                      final fecha = dt == null
                          ? "--/--/----"
                          : DateFormat('dd/MM/yyyy').format(dt);

                      final comprobanteUrl = t["comprobanteUrl"];

                      return _AnimatedAppear(
                        delayMs: i * 25,
                        child: _IngresoCard(
                          titulo: desc,
                          cliente: "Empleador",
                          precio: monto,
                          fecha: fecha,
                          onVerComprobante: (comprobanteUrl != null &&
                                  comprobanteUrl.toString().trim().isNotEmpty)
                              ? () => _verImagenDialog(
                                    titulo: "Comprobante de pago",
                                    url: comprobanteUrl.toString(),
                                  )
                              : null,
                        ),
                      );
                    }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

// ========================= UI =========================

class _ResumenTrabajadorCard extends StatelessWidget {
  final double totalIngreso;
  final int ingresosCount;
  final int pendientesCount;

  const _ResumenTrabajadorCard({
    required this.totalIngreso,
    required this.ingresosCount,
    required this.pendientesCount,
  });

  String _money(num v) => "\$${v.toStringAsFixed(2)}";

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Resumen financiero",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _money(totalIngreso),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Total de ingresos acumulados",
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.task_alt,
                  label: "Pagados",
                  value: ingresosCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.pending_actions,
                  label: "Pendientes",
                  value: pendientesCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _MiniStat(
                  icon: Icons.trending_up,
                  label: "Estado",
                  value: "Activo",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _ListaPendientes extends StatelessWidget {
  final List<dynamic> pendientes;
  final String Function(String raw) cleanTitulo;

  const _ListaPendientes({
    required this.pendientes,
    required this.cleanTitulo,
  });

  @override
  Widget build(BuildContext context) {
    final items = pendientes.take(6).toList();

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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final t = Map<String, dynamic>.from(items[i] as Map);
          final m = ((t["monto"] as num?) ?? 0).toDouble();
          final createdAt = (t["createdAt"] ?? "").toString();
          final dt = DateTime.tryParse(createdAt);
          final fecha =
              dt == null ? "--/--/----" : DateFormat('dd/MM/yyyy').format(dt);

          final raw = (t["descripcion"] ?? "Pago pendiente").toString();
          final desc = cleanTitulo(raw);

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.hourglass_bottom, color: Colors.orange),
            ),
            title: Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              "En espera • $fecha",
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Text(
              "+\$${m.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IngresoCard extends StatelessWidget {
  final String titulo;
  final String cliente;
  final double precio;
  final String fecha;
  final VoidCallback? onVerComprobante;

  const _IngresoCard({
    required this.titulo,
    required this.cliente,
    required this.precio,
    required this.fecha,
    required this.onVerComprobante,
  });

  @override
  Widget build(BuildContext context) {
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
              color: Colors.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.arrow_downward, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cliente,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_month,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      fecha,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "+\$${precio.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animación liviana sin controllers por item
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
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

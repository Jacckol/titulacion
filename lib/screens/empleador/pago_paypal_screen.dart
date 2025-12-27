import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../providers/auth_provider.dart';

const String baseUrl = "http://10.0.2.2:4000/api";

class PagoPayPalScreen extends StatefulWidget {
  final int trabajadorId;
  final int trabajoId;

  const PagoPayPalScreen({
    super.key,
    required this.trabajadorId,
    required this.trabajoId,
  });

  @override
  State<PagoPayPalScreen> createState() => _PagoPayPalScreenState();
}

class _PagoPayPalScreenState extends State<PagoPayPalScreen> {
  // ✅ transferencia
  final TextEditingController montoCtrl = TextEditingController();
  final TextEditingController cuentaDestinoCtrl = TextEditingController();
  final TextEditingController referenciaCtrl = TextEditingController();

  // ✅ ordenante (autorrelleno SOLO nombre)
  final TextEditingController nombreOrdenanteCtrl = TextEditingController();

  // ✅ cédula va en Transferencia (NO en ordenante)
  final TextEditingController cedulaCtrl = TextEditingController();

  bool cargando = false;
  bool cargandoOrdenante = true;

  // 🎨 UI
  static const Color _primary = Color(0xFF673AB7);
  static const Color _bg = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    Future.microtask(_autorrellenarNombreOrdenante);
  }

  @override
  void dispose() {
    montoCtrl.dispose();
    cuentaDestinoCtrl.dispose();
    referenciaCtrl.dispose();
    nombreOrdenanteCtrl.dispose();
    cedulaCtrl.dispose();
    super.dispose();
  }

  // ======================================================
  // ✅ Helper: agrupa dígitos para que NO desborde (ej: 2222 2222 2222)
  // ======================================================
  String _groupDigits(String input, {int group = 4}) {
    final s = input.replaceAll(' ', '').trim();
    if (s.isEmpty) return '';
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      if ((i + 1) % group == 0 && i != s.length - 1) buf.write(' ');
    }
    return buf.toString();
  }

  // ======================================================
  // ✅ Helper: fila clave/valor que WRAPEA (no overflow)
  // ======================================================
  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              "$k:",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              v.isEmpty ? "—" : v,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // ✅ TRAER SOLO NOMBRE DEL BACKEND (o fallback AuthProvider)
  // ======================================================
  Future<void> _autorrellenarNombreOrdenante() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    // fallback rápido
    nombreOrdenanteCtrl.text = (auth.userName ?? "").trim();

    if (token == null || token.isEmpty) {
      if (mounted) setState(() => cargandoOrdenante = false);
      return;
    }

    final endpoints = <String>[
      "$baseUrl/perfilLaboral/me",
      "$baseUrl/trabajadores/me",
      "$baseUrl/empleadores/me",
      "$baseUrl/users/me",
      "$baseUrl/me",
    ];

    try {
      for (final url in endpoints) {
        final resp = await http.get(
          Uri.parse(url),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (resp.statusCode != 200) continue;

        final data = jsonDecode(resp.body);

        Map<String, dynamic>? m;
        if (data is Map<String, dynamic>) {
          m = (data["perfilLaboral"] is Map)
              ? Map<String, dynamic>.from(data["perfilLaboral"])
              : m;
          m = (m ??
              ((data["trabajador"] is Map)
                  ? Map<String, dynamic>.from(data["trabajador"])
                  : null));
          m = (m ??
              ((data["empleador"] is Map)
                  ? Map<String, dynamic>.from(data["empleador"])
                  : null));
          m = (m ??
              ((data["user"] is Map)
                  ? Map<String, dynamic>.from(data["user"])
                  : null));
          m = (m ?? data);
        }

        if (m == null) continue;

        final nombre = (m["nombreCompleto"] ??
                m["nombre"] ??
                m["empresa"] ??
                auth.userName ??
                "")
            .toString()
            .trim();

        if (nombre.isNotEmpty) {
          nombreOrdenanteCtrl.text = nombre;
        }
        break;
      }
    } catch (_) {
      // no crash
    } finally {
      if (mounted) setState(() => cargandoOrdenante = false);
    }
  }

  // ======================================================
  // ✅ CONFIRMAR TRANSFERENCIA (DIALOG) - FIX OVERFLOW
  // ======================================================
  Future<void> _confirmarPago() async {
    final double? monto = double.tryParse(montoCtrl.text.replaceAll(',', '.'));

    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa un monto válido"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cuentaDestinoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa la cuenta destino"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cedulaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa tu cédula / RUC"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ordenante = nombreOrdenanteCtrl.text.trim();
    final cuentaFmt = _groupDigits(cuentaDestinoCtrl.text.trim(), group: 4);
    final cedulaFmt = _groupDigits(cedulaCtrl.text.trim(), group: 3); // 172 591 237 0 (más fácil de partir)
    final ref = referenciaCtrl.text.trim().isEmpty ? "Sin referencia" : referenciaCtrl.text.trim();

    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),

        // ✅ TÍTULO SIN OVERFLOW
        title: Row(
          children: [
            const Icon(Icons.verified_outlined, color: _primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Confirmar transferencia",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),

        // ✅ CONTENIDO QUE SE AJUSTA
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _kv("Ordenante", ordenante.isEmpty ? "—" : ordenante),
              _kv("Monto", "\$${monto.toStringAsFixed(2)}"),
              _kv("Cuenta destino", cuentaFmt),
              _kv("Cédula/RUC", cedulaFmt),
              _kv("Referencia", ref),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("¿Seguro deseas continuar?"),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Sí, transferir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await procesarPago();
    }
  }

  // ======================================================
  // 🔥 REGISTRAR TRANSACCIÓN (EMPLEADOR → TRABAJADOR)
  // ======================================================
  Future<void> procesarPago() async {
    final double? monto = double.tryParse(montoCtrl.text.replaceAll(',', '.'));

    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un monto válido"), backgroundColor: Colors.red),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sesión no válida"), backgroundColor: Colors.red),
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
          "empleadorId": auth.userId,
          "trabajadorId": widget.trabajadorId,
          "monto": monto,
          "descripcion":
              "Transferencia simulada a ${cuentaDestinoCtrl.text.trim()} - ${referenciaCtrl.text.trim().isEmpty ? "Sin referencia" : referenciaCtrl.text.trim()} - CI/RUC: ${cedulaCtrl.text.trim()}",
          "trabajoId": widget.trabajoId,
        }),
      );

      if (!mounted) return;
      setState(() => cargando = false);

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Transferencia registrada con éxito"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al transferir: ${resp.body}"), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No se pudo conectar al servidor"), backgroundColor: Colors.red),
      );
    }
  }

  // ===================== UI Helpers =====================

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  InputDecoration _dec({
    required String label,
    required IconData icon,
    String? hint,
    bool locked = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary),
      suffixIcon: locked ? const Icon(Icons.lock_outline, size: 18) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF8E6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.22),
            child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Transferencia (Simulada)",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text("Rellena y registra la transacción", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text("Transferencia"),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 14),
              Container(
                decoration: _box(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Datos del ordenante",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // ✅ SOLO NOMBRE AQUÍ
                    TextField(
                      controller: nombreOrdenanteCtrl,
                      readOnly: true,
                      decoration: _dec(label: "Nombre", icon: Icons.person_outline, locked: true),
                    ),

                    if (cargandoOrdenante) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                          const SizedBox(width: 10),
                          Text("Cargando nombre...", style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(height: 22),

                    const Text(
                      "Transferencia",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(label: "Monto", icon: Icons.attach_money, hint: "Ej: 30.00"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: cuentaDestinoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(
                        label: "Cuenta destino",
                        icon: Icons.account_balance_outlined,
                        hint: "Ej: 2100123456789",
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ CÉDULA AQUÍ (Transferencia)
                    TextField(
                      controller: cedulaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(
                        label: "Cédula / RUC",
                        icon: Icons.badge_outlined,
                        hint: "Ej: 1712345678",
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: referenciaCtrl,
                      decoration: _dec(
                        label: "Referencia (opcional)",
                        icon: Icons.description_outlined,
                        hint: "Ej: Pago por trabajo",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: cargando ? null : _confirmarPago,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    cargando ? "Procesando..." : "Confirmar Transferencia",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Simulación: no se valida como banco real, solo registra la transacción.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

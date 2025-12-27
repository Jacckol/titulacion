import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

const String baseUrl = "http://10.0.2.2:4000/api";

class CuentaBancariaTrabajadorScreen extends StatefulWidget {
  const CuentaBancariaTrabajadorScreen({super.key});

  @override
  State<CuentaBancariaTrabajadorScreen> createState() =>
      _CuentaBancariaTrabajadorScreenState();
}

class _CuentaBancariaTrabajadorScreenState
    extends State<CuentaBancariaTrabajadorScreen> {
  final _formKey = GlobalKey<FormState>();

  final bancoCtrl = TextEditingController();
  final tipoCtrl = TextEditingController(text: "ahorros"); // ✅ se mantiene
  final numeroCtrl = TextEditingController();
  final titularCtrl = TextEditingController();
  final cedulaCtrl = TextEditingController();

  PlatformFile? qrFile;
  String? qrCuentaUrlActual;

  bool cargandoPerfil = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    bancoCtrl.dispose();
    tipoCtrl.dispose();
    numeroCtrl.dispose();
    titularCtrl.dispose();
    cedulaCtrl.dispose();
    super.dispose();
  }

  // ================== HELPERS ==================

  String _fullUrl(String url) {
    final u = url.trim();
    if (u.startsWith("http")) return u;
    return "http://10.0.2.2:4000$u";
  }

  void _snack(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  // ================== API ==================

  Future<void> _pickQr() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (res == null || res.files.isEmpty) return;
    setState(() => qrFile = res.files.first);
  }

  Future<void> _cargarPerfil() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) {
      if (mounted) setState(() => cargandoPerfil = false);
      return;
    }

    try {
      final resp = await http.get(
        Uri.parse("$baseUrl/perfil/mine"),
        headers: {
          "Authorization": "Bearer ${auth.token}",
          "Content-Type": "application/json",
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map) {
          bancoCtrl.text = (data["banco"] ?? "").toString();
          tipoCtrl.text = (data["tipoCuenta"] ?? tipoCtrl.text).toString();
          numeroCtrl.text = (data["numeroCuenta"] ?? "").toString();
          titularCtrl.text = (data["titularCuenta"] ?? "").toString();
          cedulaCtrl.text = (data["cedulaTitular"] ?? "").toString();

          final qr = data["qrCuentaUrl"];
          qrCuentaUrlActual = (qr is String && qr.trim().isNotEmpty) ? qr : null;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => cargandoPerfil = false);
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

  Future<void> _guardar() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    // ✅ Validación (no cambia tu lógica, solo evita enviar vacíos)
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => guardando = true);

    try {
      // 1) Guardar datos bancarios (JSON)
      final resp = await http.put(
        Uri.parse("$baseUrl/perfil"),
        headers: {
          "Authorization": "Bearer ${auth.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "banco": bancoCtrl.text.trim(),
          "tipoCuenta": tipoCtrl.text.trim(), // ✅ se mantiene
          "numeroCuenta": numeroCtrl.text.trim(),
          "titularCuenta": titularCtrl.text.trim(),
          "cedulaTitular": cedulaCtrl.text.trim(),
        }),
      );

      if (resp.statusCode != 200) {
        throw Exception(resp.body);
      }

      // 2) Subir QR si se eligió
      if (qrFile != null) {
        final req =
            http.MultipartRequest("POST", Uri.parse("$baseUrl/perfil/qr"));
        req.headers["Authorization"] = "Bearer ${auth.token}";

        if (kIsWeb) {
          req.files.add(
            http.MultipartFile.fromBytes(
              "qr",
              qrFile!.bytes!,
              filename: qrFile!.name,
            ),
          );
        } else {
          req.files.add(
            await http.MultipartFile.fromPath("qr", qrFile!.path!),
          );
        }

        final streamed = await req.send();
        final body = await streamed.stream.bytesToString();
        if (streamed.statusCode != 200) {
          throw Exception(body);
        }
      }

      if (!mounted) return;
      _snack("✅ Cuenta bancaria guardada", ok: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack("❌ Error: $e", ok: false);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text(
          "Cuenta bancaria",
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
      body: cargandoPerfil
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      children: [
                        const _HeaderCard(
                          title: "Datos bancarios del trabajador",
                          subtitle:
                              "Completa tu cuenta para recibir tus pagos. El QR es opcional.",
                        ),
                        const SizedBox(height: 14),

                        // FORM CARD
                        Container(
                          padding: const EdgeInsets.all(16),
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _input(
                                  controller: bancoCtrl,
                                  label: "Banco",
                                  icon: Icons.account_balance,
                                  validator: (v) {
                                    if ((v ?? "").trim().isEmpty) {
                                      return "Ingresa el banco";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Tipo cuenta (manteniendo tu controller)
                                _input(
                                  controller: tipoCtrl,
                                  label: "Tipo de cuenta (ahorros/corriente)",
                                  icon: Icons.account_balance_wallet,
                                  validator: (v) {
                                    final s = (v ?? "").trim().toLowerCase();
                                    if (s.isEmpty) return "Ingresa el tipo";
                                    // opcional: normalizar
                                    if (!(s.contains("ahor") || s.contains("corr"))) {
                                      return "Escribe: ahorros o corriente";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                _input(
                                  controller: numeroCtrl,
                                  label: "Número de cuenta",
                                  icon: Icons.numbers,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    final s = (v ?? "").trim();
                                    if (s.isEmpty) return "Ingresa el número";
                                    if (s.length < 6) return "Número inválido";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                _input(
                                  controller: titularCtrl,
                                  label: "Titular",
                                  icon: Icons.person,
                                  validator: (v) {
                                    if ((v ?? "").trim().isEmpty) {
                                      return "Ingresa el titular";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                _input(
                                  controller: cedulaCtrl,
                                  label: "Cédula",
                                  icon: Icons.badge,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    final s = (v ?? "").trim();
                                    if (s.isEmpty) return "Ingresa la cédula";
                                    if (s.length < 10) return "Cédula inválida";
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // QR CARD
                        Container(
                          padding: const EdgeInsets.all(16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.qr_code_2, color: Color(0xFF6D4AFF)),
                                  SizedBox(width: 8),
                                  Text(
                                    "QR de cuenta (opcional)",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Sube una imagen de tu QR para recibir pagos más rápido.",
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 12),

                              if (qrCuentaUrlActual != null) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _verImagenDialog(
                                      titulo: "Mi QR actual",
                                      url: qrCuentaUrlActual!,
                                    ),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text("Ver QR actual"),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _pickQr,
                                  icon: const Icon(Icons.upload),
                                  label: Text(
                                    qrFile == null
                                        ? "Subir / actualizar QR"
                                        : "QR seleccionado: ${qrFile!.name}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),

                              if (qrFile != null) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    color: const Color(0xFFF5F3FF),
                                    padding: const EdgeInsets.all(12),
                                    child: _previewQrFile(qrFile!),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),

                  // Bottom Save Button
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.black.withOpacity(0.08)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: guardando ? null : _guardar,
                        icon: guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          guardando ? "Guardando..." : "Guardar cambios",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6D4AFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
    );
  }

  Widget _previewQrFile(PlatformFile f) {
    if (kIsWeb) {
      return Image.memory(f.bytes!, height: 220, fit: BoxFit.contain);
    }
    if (f.path == null) return const SizedBox.shrink();
    return Image.file(File(f.path!), height: 220, fit: BoxFit.contain);
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
  });

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
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

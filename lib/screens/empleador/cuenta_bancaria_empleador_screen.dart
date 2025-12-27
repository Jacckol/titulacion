import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

const String baseUrl = "http://10.0.2.2:4000/api";

/// ✅ Misma funcionalidad que el trabajador: guardar datos bancarios + subir QR
/// (La tabla `perfil` es por usuario, así que aplica para ambos roles.)
class CuentaBancariaEmpleadorScreen extends StatefulWidget {
  const CuentaBancariaEmpleadorScreen({super.key});

  @override
  State<CuentaBancariaEmpleadorScreen> createState() =>
      _CuentaBancariaEmpleadorScreenState();
}

class _CuentaBancariaEmpleadorScreenState
    extends State<CuentaBancariaEmpleadorScreen> {
  final bancoCtrl = TextEditingController();
  final tipoCtrl = TextEditingController(text: "ahorros");
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

  Future<void> _pickQr() async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: kIsWeb);
    if (res == null || res.files.isEmpty) return;
    setState(() => qrFile = res.files.first);
  }

  void _verImagenDialog({required String titulo, required String url}) {
    final full = url.startsWith("http") ? url : "http://10.0.2.2:4000$url";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
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

  Future<void> _guardar() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    setState(() => guardando = true);

    try {
      // 1) Guardar datos bancarios
      final resp = await http.put(
        Uri.parse("$baseUrl/perfil"),
        headers: {
          "Authorization": "Bearer ${auth.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "banco": bancoCtrl.text.trim(),
          "tipoCuenta": tipoCtrl.text.trim(),
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
        final req = http.MultipartRequest(
            "POST", Uri.parse("$baseUrl/perfil/qr"));
        req.headers["Authorization"] = "Bearer ${auth.token}";

        if (kIsWeb) {
          req.files.add(http.MultipartFile.fromBytes(
            "qr",
            qrFile!.bytes!,
            filename: qrFile!.name,
          ));
        } else {
          req.files.add(await http.MultipartFile.fromPath(
              "qr", qrFile!.path!));
        }

        final streamed = await req.send();
        final body = await streamed.stream.bytesToString();
        if (streamed.statusCode != 200) {
          throw Exception(body);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("✅ Cuenta bancaria guardada"),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cuenta bancaria (Empleador)"),
        backgroundColor: Colors.deepPurple,
      ),
      body: cargandoPerfil
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  TextField(
                      controller: bancoCtrl,
                      decoration:
                          const InputDecoration(labelText: "Banco")),
                  TextField(
                      controller: tipoCtrl,
                      decoration: const InputDecoration(
                          labelText: "Tipo de cuenta (ahorros/corriente)")),
                  TextField(
                      controller: numeroCtrl,
                      decoration:
                          const InputDecoration(labelText: "Número de cuenta")),
                  TextField(
                      controller: titularCtrl,
                      decoration:
                          const InputDecoration(labelText: "Titular")),
                  TextField(
                      controller: cedulaCtrl,
                      decoration:
                          const InputDecoration(labelText: "Cédula")),

                  const SizedBox(height: 14),

                  if (qrCuentaUrlActual != null) ...[
                    OutlinedButton.icon(
                      onPressed: () => _verImagenDialog(
                          titulo: "Mi QR actual", url: qrCuentaUrlActual!),
                      icon: const Icon(Icons.visibility),
                      label: const Text("Ver QR actual"),
                    ),
                    const SizedBox(height: 10),
                  ],

                  OutlinedButton.icon(
                    onPressed: _pickQr,
                    icon: const Icon(Icons.qr_code),
                    label: Text(qrFile == null
                        ? "Subir/actualizar QR (opcional)"
                        : "QR seleccionado: ${qrFile!.name}"),
                  ),

                  if (qrFile != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _previewQrFile(qrFile!),
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(guardando ? "Guardando..." : "Guardar",
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
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

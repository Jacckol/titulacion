import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../providers/trabajador_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PerfilTrabajadorScreen extends StatefulWidget {
  final int userId;
  final String nombre;
  final String telefono;

  const PerfilTrabajadorScreen({
    super.key,
    required this.userId,
    required this.nombre,
    required this.telefono,
  });

  @override
  State<PerfilTrabajadorScreen> createState() => _PerfilTrabajadorScreenState();
}

class _PerfilTrabajadorScreenState extends State<PerfilTrabajadorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  final _ubicacionCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _experienciaCtrl = TextEditingController();

  final _habilidadCtrl = TextEditingController();
  List<String> _habilidades = [];

  PlatformFile? _pickedFoto;
  PlatformFile? _pickedCv;

  @override
  void initState() {
    super.initState();

    _nombreCtrl = TextEditingController(text: widget.nombre);
    _telefonoCtrl = TextEditingController(text: widget.telefono);

    Future.microtask(() async {
      final provider = context.read<TrabajadorProvider>();
      await provider.fetchPerfil();

      final p = provider.perfil;

      if (p != null) {
        _telefonoCtrl.text = p["telefono"] ?? widget.telefono;
        _ubicacionCtrl.text = p["direccion"] ?? "";
        _categoriaCtrl.text = p["categoria"] ?? "";
        _experienciaCtrl.text = p["experiencia"]?.toString() ?? "0";

        if (p["habilidades"] is List) {
          _habilidades = List<String>.from(p["habilidades"]);
        }
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _ubicacionCtrl.dispose();
    _categoriaCtrl.dispose();
    _experienciaCtrl.dispose();
    _habilidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _pickedFoto = res.files.first);
    }
  }

  Future<void> _pickCv() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _pickedCv = res.files.first);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    File? fotoFile;
    File? cvFile;

    if (!kIsWeb) {
      if (_pickedFoto?.path != null) fotoFile = File(_pickedFoto!.path!);
      if (_pickedCv?.path != null) cvFile = File(_pickedCv!.path!);
    }

    final provider = context.read<TrabajadorProvider>();

    // 🔥 CAMPOS CORRECTOS (perfil simple)
    final ok = await provider.savePerfil(
      telefono: _telefonoCtrl.text.trim(),
      categoria: _categoriaCtrl.text.trim(),
      direccion: _ubicacionCtrl.text.trim(),
      experiencia: int.tryParse(_experienciaCtrl.text.trim()) ?? 0,
      habilidades: _habilidades,
    );

    if (fotoFile != null) await provider.uploadFoto(fotoFile);
    if (cvFile != null) await provider.uploadCv(cvFile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Perfil actualizado ✅' : 'Error guardando ❌'),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Seguro deseas cerrar sesión?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Sí'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await context.read<AuthProvider>().logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(rol: 'trabajador'),
        ),
      );
    }
  }

  @override

Future<void> _descargarCV(Map<String, dynamic> perfil) async {
  final doc = pw.Document();

  final nombre = (perfil['nombre'] ?? widget.nombre ?? '').toString();
  final telefono = (perfil['telefono'] ?? widget.telefono ?? '').toString();
  final categoria = (perfil['categoria'] ?? '').toString();
  final direccion = (perfil['direccion'] ?? '').toString();
  final experiencia = (perfil['experiencia'] ?? '').toString();
  final habilidades = (perfil['habilidades'] is List)
      ? List<String>.from(perfil['habilidades'])
      : <String>[];

  doc.addPage(
    pw.Page(
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(nombre.isEmpty ? 'CV' : nombre,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (telefono.isNotEmpty) pw.Text('Teléfono: $telefono'),
            pw.SizedBox(height: 12),

            pw.Text('Perfil', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            if (categoria.isNotEmpty) pw.Text('Categoría: $categoria'),
            if (direccion.isNotEmpty) pw.Text('Dirección: $direccion'),
            if (experiencia.isNotEmpty) pw.Text('Experiencia (años): $experiencia'),

            pw.SizedBox(height: 12),
            pw.Text('Habilidades', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            if (habilidades.isEmpty)
              pw.Text('—')
            else
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: habilidades
                    .map((h) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 0.8),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Text(h, style: const pw.TextStyle(fontSize: 10)),
                        ))
                    .toList(),
              ),
          ],
        );
      },
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'CV_${nombre.isEmpty ? 'trabajador' : nombre.replaceAll(' ', '_')}.pdf',
  );
}

  Widget build(BuildContext context) {
    final provider = context.watch<TrabajadorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Portal Trabajador',
          style: TextStyle(
            color: Color(0xFF7C3AED),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.black87),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),

      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi Perfil Profesional',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mantén tu información actualizada para recibir mejores oportunidades',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

const SizedBox(height: 14),
SizedBox(
  width: double.infinity,
  height: 46,
  child: OutlinedButton.icon(
    onPressed: provider.perfil == null ? null : () => _descargarCV(provider.perfil!),
    icon: const Icon(Icons.picture_as_pdf),
    label: const Text('Descargar CV'),
  ),
),



                  Row(
                    children: [
                      Expanded(child: _infoCard('⭐', '4.8', 'Calificación')),
                      const SizedBox(width: 12),
                      Expanded(child: _infoCard('📋', '156', 'Trabajos')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          '💼',
                          _experienciaCtrl.text.isNotEmpty
                              ? _experienciaCtrl.text
                              : '0',
                          'Años',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _fotoCard(),
                  const SizedBox(height: 20),
                  _formCard(),
                  const SizedBox(height: 20),
                  _habilidadesCard(),
                  const SizedBox(height: 20),
                  _cvCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _fotoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Foto de Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              widget.nombre.isNotEmpty
                  ? widget.nombre[0].toUpperCase()
                  : 'T',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFoto,
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Subir Foto'),
            ),
          ),
          if (_pickedFoto != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_pickedFoto!.name),
            ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _campo('Nombre Completo', _nombreCtrl, readOnly: true),
            const SizedBox(height: 12),
            _campo('Teléfono', _telefonoCtrl),
            const SizedBox(height: 12),
            _campo('Ubicación *', _ubicacionCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo('Categoría *', _categoriaCtrl)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: _campo('Años *', _experienciaCtrl),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardar,
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _habilidadesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Habilidades', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _habilidadCtrl,
                  decoration: const InputDecoration(
                    hintText: "Agregar habilidad...",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final h = _habilidadCtrl.text.trim();
                  if (h.isNotEmpty) {
                    setState(() {
                      _habilidades.add(h);
                      _habilidadCtrl.clear();
                    });
                  }
                },
                child: const Text("Agregar"),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: _habilidades
                .map((h) => Chip(
                      label: Text(h),
                      onDeleted: () {
                        setState(() => _habilidades.remove(h));
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _cvCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Currículum (CV)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _pickCv,
            child: const Text("Seleccionar Archivo"),
          ),
          if (_pickedCv != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_pickedCv!.name),
            ),
        ],
      ),
    );
  }

  Widget _campo(String label, TextEditingController c, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          readOnly: readOnly,
          validator: (v) {
            if (!readOnly && (v == null || v.isEmpty)) return 'Campo obligatorio';
            return null;
          },
        ),
      ],
    );
  }

  Widget _infoCard(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    );
  }
}
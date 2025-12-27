import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../providers/trabajador_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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
        _telefonoCtrl.text = (p["telefono"] ?? widget.telefono).toString();
        _ubicacionCtrl.text = (p["direccion"] ?? "").toString();
        _categoriaCtrl.text = (p["categoria"] ?? "").toString();
        _experienciaCtrl.text = (p["experiencia"] ?? 0).toString();

        if (p["habilidades"] is List) {
          _habilidades = List<String>.from(p["habilidades"])
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }

      if (mounted) setState(() {});
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

    final ok = await provider.savePerfil(
      telefono: _telefonoCtrl.text.trim(),
      categoria: _categoriaCtrl.text.trim(),
      direccion: _ubicacionCtrl.text.trim(),
      experiencia: int.tryParse(_experienciaCtrl.text.trim()) ?? 0,
      habilidades: _habilidades,
    );

    if (fotoFile != null) await provider.uploadFoto(fotoFile);
    if (cvFile != null) await provider.uploadCv(cvFile);

    if (!mounted) return;
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
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(rol: 'trabajador')),
      );
    }
  }

  // ==========================================================
  // ✅ PDF CV con DISEÑO PRO (SIN withOpacity)
  // ==========================================================
  Future<void> _descargarCV(Map<String, dynamic> perfil) async {
    final doc = pw.Document();

    final nombre = (perfil['nombre'] ?? widget.nombre ?? '').toString().trim();
    final telefono =
        (perfil['telefono'] ?? widget.telefono ?? '').toString().trim();
    final categoria = (perfil['categoria'] ?? '').toString().trim();
    final direccion = (perfil['direccion'] ?? '').toString().trim();
    final experiencia = (perfil['experiencia'] ?? 0).toString().trim();

    final habilidades = (perfil['habilidades'] is List)
        ? List<String>.from(perfil['habilidades'])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final fecha = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Colores PDF (AARRGGBB)
    final purple = PdfColor.fromInt(0xFF7C3AED);
    final purpleDark = PdfColor.fromInt(0xFF5B21B6);
    final text = PdfColor.fromInt(0xFF111827);
    final muted = PdfColor.fromInt(0xFF6B7280);
    final border = PdfColor.fromInt(0xFFE5E7EB);
    final soft = PdfColor.fromInt(0xFFF3F4F6);

    // Blancos con alpha (NO withOpacity)
    final white18 = PdfColor.fromInt(0x2EFFFFFF); // ~18%
    final white85 = PdfColor.fromInt(0xD9FFFFFF); // ~85%
    final white92 = PdfColor.fromInt(0xEBFFFFFF); // ~92%
    final white75 = PdfColor.fromInt(0xBFFFFFFF); // ~75%

    pw.Widget tag(String t) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const pw.EdgeInsets.only(right: 6, bottom: 6),
        decoration: pw.BoxDecoration(
          color: soft,
          borderRadius: pw.BorderRadius.circular(20),
          border: pw.Border.all(color: border, width: 0.8),
        ),
        child: pw.Text(
          t,
          style: pw.TextStyle(fontSize: 10.5, color: text),
        ),
      );
    }

    pw.Widget sectionTitle(String t) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
        child: pw.Row(
          children: [
            pw.Container(
              width: 6,
              height: 14,
              decoration: pw.BoxDecoration(
                color: purple,
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              t,
              style: pw.TextStyle(
                fontSize: 12.5,
                fontWeight: pw.FontWeight.bold,
                color: text,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget infoRow(String k, String v) {
      final vv = v.trim();
      if (vv.isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 92,
              child: pw.Text(
                k,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  color: muted,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                vv,
                style: pw.TextStyle(fontSize: 10.8, color: text),
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(22),
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(18),
              border: pw.Border.all(color: border, width: 1),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // LEFT SIDEBAR
                pw.Container(
                  width: 170,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: purpleDark,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(18),
                      bottomLeft: pw.Radius.circular(18),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 56,
                        height: 56,
                        decoration: pw.BoxDecoration(
                          color: white18,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.white, width: 1),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'T',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        nombre.isEmpty ? 'CV Trabajador' : nombre,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        maxLines: 2,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        categoria.isEmpty ? 'Trabajador' : categoria,
                        style: pw.TextStyle(
                          color: white85,
                          fontSize: 10.5,
                        ),
                      ),
                      pw.SizedBox(height: 14),
                      pw.Container(height: 1, color: white18),
                      pw.SizedBox(height: 14),
                      pw.Text(
                        "CONTACTO",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      if (telefono.isNotEmpty)
                        pw.Text(
                          "📞  $telefono",
                          style: pw.TextStyle(
                            color: white92,
                            fontSize: 10.5,
                          ),
                        ),
                      if (direccion.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(
                          "📍  $direccion",
                          style: pw.TextStyle(
                            color: white92,
                            fontSize: 10.5,
                          ),
                          maxLines: 3,
                        ),
                      ],
                      pw.Spacer(),
                      pw.Container(height: 1, color: white18),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        "Generado: $fecha",
                        style: pw.TextStyle(
                          color: white75,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT CONTENT
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                "CURRÍCULUM VITAE",
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: text,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: soft,
                                borderRadius: pw.BorderRadius.circular(20),
                                border: pw.Border.all(color: border, width: 0.8),
                              ),
                              child: pw.Text(
                                "ServX",
                                style: pw.TextStyle(
                                  fontSize: 10.5,
                                  color: PdfColor.fromInt(0xFF5B21B6),
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),

                        sectionTitle("Perfil"),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(14),
                            border: pw.Border.all(color: border, width: 1),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              infoRow("Nombre", nombre.isEmpty ? "—" : nombre),
                              infoRow("Categoría", categoria.isEmpty ? "—" : categoria),
                              infoRow("Experiencia", "${experiencia.isEmpty ? "0" : experiencia} años"),
                              infoRow("Ubicación", direccion.isEmpty ? "—" : direccion),
                              infoRow("Teléfono", telefono.isEmpty ? "—" : telefono),
                            ],
                          ),
                        ),

                        sectionTitle("Habilidades"),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(14),
                            border: pw.Border.all(color: border, width: 1),
                          ),
                          child: habilidades.isEmpty
                              ? pw.Text("—",
                                  style: pw.TextStyle(color: muted, fontSize: 11))
                              : pw.Wrap(
                                  children: habilidades.map(tag).toList(),
                                ),
                        ),

                        sectionTitle("Resumen"),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: soft,
                            borderRadius: pw.BorderRadius.circular(14),
                            border: pw.Border.all(color: border, width: 1),
                          ),
                          child: pw.Text(
                            "Trabajador registrado en ServX. Perfil generado automáticamente con los datos proporcionados en la aplicación.",
                            style: pw.TextStyle(color: muted, fontSize: 10.8),
                          ),
                        ),

                        pw.Spacer(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "Documento generado desde la app",
                              style: pw.TextStyle(color: muted, fontSize: 9.5),
                            ),
                            pw.Text(
                              "© ServX",
                              style: pw.TextStyle(color: muted, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'CV_${(nombre.isEmpty ? 'trabajador' : nombre).replaceAll(' ', '_')}.pdf',
    );
  }

  @override
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

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: provider.perfil == null ? null : () => _descargarCV(provider.perfil!),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Descargar CV'),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(child: _infoCard('⭐', '4.8', 'Calificación')),
                      const SizedBox(width: 12),
                      Expanded(child: _infoCard('📋', '156', 'Trabajos')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          '💼',
                          _experienciaCtrl.text.isNotEmpty ? _experienciaCtrl.text : '0',
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
              widget.nombre.isNotEmpty ? widget.nombre[0].toUpperCase() : 'T',
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
                SizedBox(width: 110, child: _campo('Años *', _experienciaCtrl)),
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
                  decoration: const InputDecoration(hintText: "Agregar habilidad..."),
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
                .map(
                  (h) => Chip(
                    label: Text(h),
                    onDeleted: () => setState(() => _habilidades.remove(h)),
                  ),
                )
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

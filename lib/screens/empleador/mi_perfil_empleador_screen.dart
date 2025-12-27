import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../../providers/auth_provider.dart';
import '../../providers/perfil_empleador_provider.dart';

class MiPerfilEmpleadorScreen extends StatefulWidget {
  const MiPerfilEmpleadorScreen({super.key});

  @override
  State<MiPerfilEmpleadorScreen> createState() =>
      _MiPerfilEmpleadorScreenState();
}

class _MiPerfilEmpleadorScreenState extends State<MiPerfilEmpleadorScreen> {
  final _formKey = GlobalKey<FormState>();

  String _tipo = 'NATURAL';

  final _nombreCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  bool _cargado = false;

  File? _fotoNueva;
  File? _recordNuevo;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final prov = context.read<PerfilEmpleadorProvider>();

      final token = auth.token;
      if (token == null || token.isEmpty) return;

      await prov.fetchMiPerfil(token: token);
      final p = prov.miPerfil;

      if (p != null) {
        _tipo = (p['tipoEmpleador'] ?? 'NATURAL').toString();

        _nombreCtrl.text = (p['nombre'] ?? auth.userName ?? '').toString();
        _empresaCtrl.text = (p['empresa'] ?? '').toString();
        _rucCtrl.text = (p['ruc'] ?? '').toString();
        _responsableCtrl.text = (p['responsable'] ?? '').toString();
        _telefonoCtrl.text = (p['telefono'] ?? '').toString();
        _direccionCtrl.text = (p['direccion'] ?? '').toString();
      } else {
        _nombreCtrl.text = auth.userName ?? '';
      }

      setState(() => _cargado = true);
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _empresaCtrl.dispose();
    _rucCtrl.dispose();
    _responsableCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final prov = context.read<PerfilEmpleadorProvider>();

    final token = auth.token;
    if (token == null || token.isEmpty) return;

    final data = <String, dynamic>{
      'tipoEmpleador': _tipo,
      'nombre': _nombreCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
    };

    if (_tipo == 'JURIDICA') {
      data['empresa'] = _empresaCtrl.text.trim();
      data['ruc'] = _rucCtrl.text.trim();
      data['responsable'] = _responsableCtrl.text.trim();
    } else {
      // Para NATURAL, limpiamos campos de empresa para evitar confusiones
      data['empresa'] = '';
      data['ruc'] = '';
      data['responsable'] = '';
    }

    final ok = await prov.guardarMiPerfil(token: token, data: data);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Cambios guardados ✅' : (prov.error ?? 'Error ❌')),
      ),
    );
  }

  Future<void> _pickFoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _fotoNueva = File(result.files.single.path!));
    }
  }

  Future<void> _pickRecordPolicial() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _recordNuevo = File(result.files.single.path!));
    }
  }

  Future<void> _subirArchivos() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<PerfilEmpleadorProvider>();

    final token = auth.token;
    if (token == null || token.isEmpty) return;

    if (_fotoNueva == null && _recordNuevo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un archivo')),
      );
      return;
    }

    final ok = await prov.actualizarMisArchivos(
      token: token,
      foto: _fotoNueva,
      recordPolicial: _recordNuevo,
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        _fotoNueva = null;
        _recordNuevo = null;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Archivos actualizados ✅' : (prov.error ?? 'Error ❌'))),
    );
  }

Future<void> _subirSoloRecordPolicial() async {
  final auth = context.read<AuthProvider>();
  final prov = context.read<PerfilEmpleadorProvider>();

  final token = auth.token;
  if (token == null || token.isEmpty) return;

  if (_recordNuevo == null) {
    await _pickRecordPolicial();
  }
  if (_recordNuevo == null) return;

  final ok = await prov.actualizarMisArchivos(
    token: token,
    recordPolicial: _recordNuevo,
  );

  if (!mounted) return;

  if (ok) {
    setState(() => _recordNuevo = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Récord policial actualizado')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PerfilEmpleadorProvider>();
    final auth = context.watch<AuthProvider>();
    final nombreMostrar = (_nombreCtrl.text.isNotEmpty
            ? _nombreCtrl.text
            : (auth.userName ?? 'E'))
        .trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Color(0xFF7C3AED),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: (!_cargado || prov.loading)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos del empleador',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Actualiza tu información para que puedas contratar y gestionar servicios sin problemas.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: _infoCard('⭐', '4.7', 'Calificación')),
                      const SizedBox(width: 12),
                      Expanded(child: _infoCard('📋', '0', 'Publicaciones')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          '🏷️',
                          _tipo == 'JURIDICA' ? 'Empresa' : 'Natural',
                          'Tipo',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Foto (solo visual)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _box(),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.grey.shade300,
                          child: Text(
                            nombreMostrar.isNotEmpty
                                ? nombreMostrar[0].toUpperCase()
                                : 'E',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreMostrar,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tipo == 'JURIDICA'
                                    ? (_empresaCtrl.text.isNotEmpty
                                        ? _empresaCtrl.text
                                        : 'Empresa')
                                    : 'Persona natural',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =============================
                  // ✅ DOCUMENTOS (FOTO / RÉCORD)
                  // =============================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _box(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Documentos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        _archivoRow(
                          titulo: 'Foto de perfil (opcional)',
                          actual: (prov.miPerfil?['foto_url'] ?? '').toString(),
                          seleccionado: _fotoNueva,
                          onPick: _pickFoto,
                        ),
                        const SizedBox(height: 12),
                        _archivoRow(
                          titulo: 'Récord policial (PDF o imagen)',
                          actual: (prov.miPerfil?['record_policial_url'] ?? '')
                              .toString(),
                          seleccionado: _recordNuevo,
                          onPick: _pickRecordPolicial,
                        ),

                        

const SizedBox(height: 10),
SizedBox(
  width: double.infinity,
  height: 46,
  child: OutlinedButton.icon(
    onPressed: prov.loading ? null : _subirSoloRecordPolicial,
    icon: const Icon(Icons.verified_user),
    label: const Text('Subir récord policial'),
  ),
),

                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: prov.loading ? null : _subirArchivos,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Subir / Actualizar documentos'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Nota: se guardan en el backend y se reflejan aquí mismo al recargar.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Formulario
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _box(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          _tipoSelector(),
                          const SizedBox(height: 14),

                          if (_tipo == 'NATURAL') ...[
                            _field('Nombre completo', _nombreCtrl,
                                icon: Icons.person, requiredField: true),
                          ] else ...[
                            _field('Empresa', _empresaCtrl,
                                icon: Icons.business, requiredField: true),
                            const SizedBox(height: 12),
                            _field('RUC', _rucCtrl,
                                icon: Icons.confirmation_number,
                                requiredField: true,
                                keyboard: TextInputType.number),
                            const SizedBox(height: 12),
                            _field('Responsable', _responsableCtrl,
                                icon: Icons.person_pin, requiredField: false),
                            const SizedBox(height: 12),
                          ],

                          _field('Teléfono', _telefonoCtrl,
                              icon: Icons.phone,
                              requiredField: false,
                              keyboard: TextInputType.phone),
                          const SizedBox(height: 12),
                          _field('Dirección', _direccionCtrl,
                              icon: Icons.location_on, requiredField: false),

                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: prov.loading ? null : _guardar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: prov.loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Guardar cambios',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tipoSelector() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Persona natural'),
            selected: _tipo == 'NATURAL',
            onSelected: (v) {
              if (!v) return;
              setState(() => _tipo = 'NATURAL');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ChoiceChip(
            label: const Text('Empresa'),
            selected: _tipo == 'JURIDICA',
            onSelected: (v) {
              if (!v) return;
              setState(() => _tipo = 'JURIDICA');
            },
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: _box(),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _archivoRow({
    required String titulo,
    required String actual,
    required File? seleccionado,
    required VoidCallback onPick,
  }) {
    final actualTxt = actual.isNotEmpty ? 'Actual: $actual' : 'Sin archivo actual';
    final selTxt = seleccionado != null
        ? 'Seleccionado: ${seleccionado.path.split(Platform.pathSeparator).last}'
        : 'Ninguno seleccionado';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(actualTxt, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 2),
          Text(selTxt, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file),
              label: const Text('Seleccionar archivo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    required IconData icon,
    required bool requiredField,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
      ),
      validator: (v) {
        if (!requiredField) return null;
        if (v == null || v.trim().isEmpty) return 'Campo requerido';
        return null;
      },
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

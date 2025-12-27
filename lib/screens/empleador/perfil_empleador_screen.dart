import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../login_screen.dart';

/// ==========================================================
/// ✅ PERFIL EMPLEADOR (BÁSICO)
/// - Carga/guarda datos del empleador (NATURAL / JURÍDICA)
/// - Usa endpoints existentes del backend:
///   GET /api/empleadores/me
///   PUT /api/empleadores/me
/// - NO toca login ni notificaciones.
/// ==========================================================
class PerfilEmpleadorScreen extends StatefulWidget {
  const PerfilEmpleadorScreen({super.key});

  @override
  State<PerfilEmpleadorScreen> createState() => _PerfilEmpleadorScreenState();
}

class _PerfilEmpleadorScreenState extends State<PerfilEmpleadorScreen> {
  static const String _baseUrl = 'http://10.0.2.2:4000/api/empleadores/me';

  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  String _tipo = 'NATURAL'; // NATURAL | JURIDICA
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargar);
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

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final resp = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final e = (data['empleador'] ?? {}) as Map<String, dynamic>;

        _tipo = (e['tipoEmpleador'] ?? 'NATURAL').toString();
        _nombreCtrl.text = (e['nombre'] ?? '').toString();
        _empresaCtrl.text = (e['empresa'] ?? '').toString();
        _rucCtrl.text = (e['ruc'] ?? '').toString();
        _responsableCtrl.text = (e['responsable'] ?? '').toString();
        _telefonoCtrl.text = (e['telefono'] ?? '').toString();
        _direccionCtrl.text = (e['direccion'] ?? '').toString();
      }
    } catch (_) {
      // Silencioso: no rompemos la UX
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Vuelve a iniciar sesión.')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final payload = {
        'tipoEmpleador': _tipo,
        'nombre': _nombreCtrl.text.trim(),
        'empresa': _empresaCtrl.text.trim(),
        'ruc': _rucCtrl.text.trim(),
        'responsable': _responsableCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
      };

      // Limpieza para NATURAL (evita guardar ruc/empresa si no aplica)
      if (_tipo == 'NATURAL') {
        payload['empresa'] = '';
        payload['ruc'] = '';
        payload['responsable'] = '';
      }

      final resp = await http.put(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final ok = resp.statusCode == 200;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Perfil actualizado ✅' : 'Error guardando ❌'),
        ),
      );

      if (ok) {
        await _cargar();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión ❌')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
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
          builder: (_) => const LoginScreen(rol: 'empleador'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombreHeader = (auth.userName ?? 'Empleador').trim();

    if (auth.token == null || auth.token!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sesión no encontrada'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen(rol: 'empleador')),
                  );
                },
                child: const Text('Ir a Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Portal Empleador',
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi Perfil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Edita tus datos para que se vean correctamente en el módulo de empleador',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: _infoCard('🏢', _tipo == 'JURIDICA' ? 'Empresa' : 'Natural', 'Tipo')),
                      const SizedBox(width: 12),
                      Expanded(child: _infoCard('📍', _direccionCtrl.text.isNotEmpty ? 'OK' : '--', 'Dirección')),
                      const SizedBox(width: 12),
                      Expanded(child: _infoCard('📞', _telefonoCtrl.text.isNotEmpty ? 'OK' : '--', 'Teléfono')),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _fotoCard(nombreHeader),
                  const SizedBox(height: 20),
                  _formCard(),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Guardar cambios',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _fotoCard(String nombreHeader) {
    final initial = nombreHeader.isNotEmpty ? nombreHeader[0].toUpperCase() : 'E';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Foto / Identidad', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              initial,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Por ahora este módulo guarda datos básicos.\n(La verificación con archivos está en el perfil extendido)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Datos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // Tipo
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Persona Natural'),
                    selected: _tipo == 'NATURAL',
                    onSelected: (v) {
                      if (v) setState(() => _tipo = 'NATURAL');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Empresa (RUC)'),
                    selected: _tipo == 'JURIDICA',
                    onSelected: (v) {
                      if (v) setState(() => _tipo = 'JURIDICA');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_tipo == 'NATURAL') ...[
              _input(
                label: 'Nombre completo',
                ctrl: _nombreCtrl,
                requiredField: true,
              ),
            ] else ...[
              _input(
                label: 'Empresa',
                ctrl: _empresaCtrl,
                requiredField: true,
              ),
              const SizedBox(height: 12),
              _input(
                label: 'RUC',
                ctrl: _rucCtrl,
                requiredField: true,
              ),
              const SizedBox(height: 12),
              _input(
                label: 'Responsable',
                ctrl: _responsableCtrl,
              ),
            ],

            const SizedBox(height: 12),
            _input(
              label: 'Teléfono',
              ctrl: _telefonoCtrl,
            ),
            const SizedBox(height: 12),
            _input(
              label: 'Dirección',
              ctrl: _direccionCtrl,
              requiredField: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController ctrl,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (!requiredField) return null;
        if (v == null || v.trim().isEmpty) return 'Requerido';
        return null;
      },
    );
  }

  Widget _infoCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _box(),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
      border: Border.all(color: Colors.grey.shade200),
    );
  }
}

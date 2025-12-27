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

  // 🎨 Paleta
  static const Color _primary = Color(0xFF7C3AED);
  static const Color _bg = Color(0xFFF6F7FB);

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
      // Silencioso
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

      // Limpieza para NATURAL
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
        SnackBar(content: Text(ok ? 'Perfil actualizado ✅' : 'Error guardando ❌')),
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
        backgroundColor: _bg,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: _box(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 38),
                const SizedBox(height: 10),
                const Text('Sesión no encontrada', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen(rol: 'empleador')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ir a Login', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Portal Empleador',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.black87),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerCard(nombreHeader),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _infoCard(
                            icon: Icons.badge_outlined,
                            value: _tipo == 'JURIDICA' ? 'Empresa' : 'Natural',
                            label: 'Tipo',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _infoCard(
                            icon: Icons.phone_outlined,
                            value: _telefonoCtrl.text.isNotEmpty ? 'OK' : '--',
                            label: 'Teléfono',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _infoCard(
                            icon: Icons.location_on_outlined,
                            value: _direccionCtrl.text.isNotEmpty ? 'OK' : '--',
                            label: 'Dirección',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _sectionTitle('Datos del perfil', 'Completa tu información para que se muestre bien'),
                    const SizedBox(height: 10),
                    _formCard(),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.save_outlined, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        label: const Text(
                          'Guardar cambios',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
    );
  }

  // ===================== UI NUEVA (NO TOCA LÓGICA) =====================

  Widget _headerCard(String nombreHeader) {
    final initial = nombreHeader.isNotEmpty ? nombreHeader[0].toUpperCase() : 'E';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Text(
                initial,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreHeader.isEmpty ? 'Empleador' : nombreHeader,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tipo == 'JURIDICA' ? 'Perfil de Empresa (RUC)' : 'Perfil Persona Natural',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_user_outlined, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
            const Text('Tipo de empleador', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Persona Natural'),
                    selected: _tipo == 'NATURAL',
                    selectedColor: _primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _tipo == 'NATURAL' ? _primary : Colors.black87,
                    ),
                    onSelected: (v) {
                      if (v) setState(() => _tipo = 'NATURAL');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Empresa (RUC)'),
                    selected: _tipo == 'JURIDICA',
                    selectedColor: _primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _tipo == 'JURIDICA' ? _primary : Colors.black87,
                    ),
                    onSelected: (v) {
                      if (v) setState(() => _tipo = 'JURIDICA');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tipo == 'NATURAL'
                  ? Column(
                      key: const ValueKey('natural'),
                      children: [
                        _input(
                          label: 'Nombre completo',
                          ctrl: _nombreCtrl,
                          icon: Icons.person_outline,
                          requiredField: true,
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('juridica'),
                      children: [
                        _input(
                          label: 'Empresa',
                          ctrl: _empresaCtrl,
                          icon: Icons.apartment_outlined,
                          requiredField: true,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          label: 'RUC',
                          ctrl: _rucCtrl,
                          icon: Icons.numbers_outlined,
                          requiredField: true,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          label: 'Responsable',
                          ctrl: _responsableCtrl,
                          icon: Icons.manage_accounts_outlined,
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),
            _input(
              label: 'Teléfono',
              ctrl: _telefonoCtrl,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            _input(
              label: 'Dirección',
              ctrl: _direccionCtrl,
              icon: Icons.location_on_outlined,
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
    required IconData icon,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
      validator: (v) {
        if (!requiredField) return null;
        if (v == null || v.trim().isEmpty) return 'Requerido';
        return null;
      },
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: _box(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
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

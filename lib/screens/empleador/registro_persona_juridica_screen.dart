import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistroPersonaJuridicaScreen extends StatefulWidget {
  const RegistroPersonaJuridicaScreen({super.key});

  @override
  State<RegistroPersonaJuridicaScreen> createState() =>
      _RegistroPersonaJuridicaScreenState();
}

class _RegistroPersonaJuridicaScreenState
    extends State<RegistroPersonaJuridicaScreen> {
  final _formKey = GlobalKey<FormState>();

  final empresaCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final rucCtrl = TextEditingController();
  final responsableCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();

  bool loading = false;
  bool _verPassword = false;

  @override
  void dispose() {
    empresaCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    rucCtrl.dispose();
    responsableCtrl.dispose();
    direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final resp = await http.post(
      Uri.parse('http://10.0.2.2:4000/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nombre": empresaCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
        "rol": "empleador",
        "empresa": empresaCtrl.text.trim(),
        "ruc": rucCtrl.text.trim(),
        "responsable": responsableCtrl.text.trim(),
        "direccion": direccionCtrl.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (!mounted) return;

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      Navigator.pushReplacementNamed(context, '/login', arguments: {
        "rol": "empleador",
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar empresa")),
      );
    }
  }

  // ===================== UI HELPERS =====================

  static const Color _primary = Color(0xFF7C3AED);
  static const Color _bg = Color(0xFFF6F7FB);

  InputDecoration _dec({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text("Registro Empresa"),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Header bonito
            Container(
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: const Icon(Icons.apartment_outlined,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Crea tu cuenta de empresa",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Completa tus datos para empezar a contratar en ServX",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Form Card
            Container(
              decoration: _box(),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Empresa
                    TextFormField(
                      controller: empresaCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(
                        label: "Empresa",
                        icon: Icons.business_outlined,
                        hint: "Nombre de la empresa",
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Requerido" : null,
                    ),
                    const SizedBox(height: 12),

                    // Correo
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(
                        label: "Correo",
                        icon: Icons.email_outlined,
                        hint: "empresa@correo.com",
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Requerido" : null,
                    ),
                    const SizedBox(height: 12),

                    // Password con ver/ocultar
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: !_verPassword,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(
                        label: "Contraseña",
                        icon: Icons.lock_outline,
                        hint: "Mínimo 6 caracteres",
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _verPassword = !_verPassword),
                          icon: Icon(_verPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                        ),
                      ),
                      validator: (v) {
                        final txt = (v ?? '').trim();
                        if (txt.isEmpty) return "Requerido";
                        if (txt.length < 6) return "Mínimo 6 caracteres";
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Datos legales (opcional visualmente)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Datos legales (opcional)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: rucCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(
                        label: "RUC",
                        icon: Icons.numbers_outlined,
                        hint: "Ej: 1790012345001",
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: responsableCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(
                        label: "Responsable",
                        icon: Icons.person_outline,
                        hint: "Nombre del responsable",
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: direccionCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: _dec(
                        label: "Dirección",
                        icon: Icons.location_on_outlined,
                        hint: "Dirección de la empresa",
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : registrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "Registrar Empresa",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Textito abajo
            Center(
              child: Text(
                "Al registrarte, aceptas los términos y condiciones.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

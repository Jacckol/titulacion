import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterTrabajadorScreen extends StatefulWidget {
  final String rol;
  const RegisterTrabajadorScreen({super.key, required this.rol});

  @override
  State<RegisterTrabajadorScreen> createState() => _RegisterTrabajadorScreenState();
}

class _RegisterTrabajadorScreenState extends State<RegisterTrabajadorScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(32),
            width: size.width > 500 ? 450 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "REGISTRO TRABAJADOR",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B21B6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nombre completo
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: const Icon(Icons.person_2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),

                  const SizedBox(height: 16),

                  // Usuario
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),

                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),

                  const SizedBox(height: 16),

                  // Contraseña
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),

                  const SizedBox(height: 16),

                  // Teléfono
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),

                  const SizedBox(height: 24),

                  // Botón registrar trabajador
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                final ok = await auth.registerWorker(
                                  nombreController.text.trim(),
                                  usernameController.text.trim(),
                                  passwordController.text.trim(),
                                  emailController.text.trim(),
                                  phoneController.text.trim(),
                                );

                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Trabajador registrado correctamente")),
                                  );

                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                    arguments: {'rol': 'trabajador'},
                                  );
                                }
                              }
                            },
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Registrar Trabajador",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "¿Ya tienes cuenta? Inicia sesión",
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
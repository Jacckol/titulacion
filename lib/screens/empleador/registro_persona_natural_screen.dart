import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistroPersonaNaturalScreen extends StatefulWidget {
  const RegistroPersonaNaturalScreen({super.key});

  @override
  State<RegistroPersonaNaturalScreen> createState() =>
      _RegistroPersonaNaturalScreenState();
}

class _RegistroPersonaNaturalScreenState
    extends State<RegistroPersonaNaturalScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();

  bool loading = false;

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final resp = await http.post(
      Uri.parse('http://10.0.2.2:4000/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nombre": nombreCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
        "rol": "empleador",
        "telefono": telefonoCtrl.text.trim(),
        "direccion": direccionCtrl.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      Navigator.pushReplacementNamed(context, '/login', arguments: {
        "rol": "empleador",
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Persona Natural")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre completo"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Correo"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                validator: (v) => v!.length < 6 ? "Mínimo 6 caracteres" : null,
              ),
              TextFormField(
                controller: telefonoCtrl,
                decoration: const InputDecoration(labelText: "Teléfono"),
              ),
              TextFormField(
                controller: direccionCtrl,
                decoration: const InputDecoration(labelText: "Dirección"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : registrar,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Registrar"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

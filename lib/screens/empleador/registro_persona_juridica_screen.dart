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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro Empresa")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: empresaCtrl,
                decoration: const InputDecoration(labelText: "Empresa"),
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
                controller: rucCtrl,
                decoration: const InputDecoration(labelText: "RUC"),
              ),
              TextFormField(
                controller: responsableCtrl,
                decoration: const InputDecoration(labelText: "Responsable"),
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
                    : const Text("Registrar Empresa"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

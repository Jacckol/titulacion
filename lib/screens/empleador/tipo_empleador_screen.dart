import 'package:flutter/material.dart';

class TipoEmpleadorScreen extends StatelessWidget {
  const TipoEmpleadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Empleador"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            const Text(
              "Selecciona el tipo de empleador",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text("Persona Natural"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/empleador/registro-natural',
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.business),
              label: const Text("Persona Jurídica / Empresa"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/empleador/registro-juridico',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

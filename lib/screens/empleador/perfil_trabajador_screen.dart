import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/trabajador_model.dart';

class PerfilTrabajadorScreen extends StatelessWidget {
  final TrabajadorModel trabajador;

  const PerfilTrabajadorScreen({super.key, required this.trabajador});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del trabajador'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Nombre
            Text(
              trabajador.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // 📌 Info
            Text('📂 Categoría: ${trabajador.categoria}'),
            Text('🧠 Experiencia: ${trabajador.experiencia} años'),

            const SizedBox(height: 15),

            // 📝 Descripción
            Text(trabajador.descripcion),

            const Divider(height: 30),

            // 📧 Contacto
            const Text(
              'Contacto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Text(trabajador.email),

            const Spacer(),

            // 📋 Copiar email
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copiar contacto'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: trabajador.email),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contacto copiado al portapapeles'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

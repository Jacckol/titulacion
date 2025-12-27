import 'package:flutter/material.dart';
import '../../services/buscar_trabajadores_service.dart';
import '../../models/trabajador_model.dart';
import 'perfil_trabajador_screen.dart';

class BuscarPerfilesScreen extends StatelessWidget {
  const BuscarPerfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar perfiles'),
      ),
      body: FutureBuilder<List<TrabajadorModel>>(
        future: BuscarTrabajadoresService.buscarPerfiles(),
        builder: (context, snapshot) {
          // ⏳ Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar perfiles',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final trabajadores = snapshot.data ?? [];

          // 📭 Vacío
          if (trabajadores.isEmpty) {
            return const Center(
              child: Text('No hay trabajadores registrados'),
            );
          }

          // ✅ Lista
          return ListView.builder(
            itemCount: trabajadores.length,
            itemBuilder: (context, index) {
              final t = trabajadores[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),

                  // 👤 NOMBRE (sin overflow)
                  title: Text(
                    t.nombre,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  // 📌 CATEGORÍA + EXPERIENCIA
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.categoria,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Experiencia: ${t.experiencia} años',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PerfilTrabajadorScreen(trabajador: t),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

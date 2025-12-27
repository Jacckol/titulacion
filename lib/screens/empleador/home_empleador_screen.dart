import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../providers/auth_provider.dart';
import '../../providers/notificaciones_provider.dart';

// Pantallas
import '../../screens/notificaciones/notificaciones_screen.dart';
import '../ofertas_screen.dart';
import 'mi_billetera_screen.dart';

// Buscar perfiles
import 'package:flutter_frontend/screens/empleador/buscar_perfiles_screen.dart';

class HomeEmpleadorScreen extends StatefulWidget {
  const HomeEmpleadorScreen({super.key});

  @override
  State<HomeEmpleadorScreen> createState() => _HomeEmpleadorScreenState();
}

class _HomeEmpleadorScreenState extends State<HomeEmpleadorScreen> {
  @override
  void initState() {
    super.initState();

    /// 🔔 Cargar notificaciones
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      final notiProv = context.read<NotificacionesProvider>();

      final userId = auth.userId;

      if (userId != null && userId != 0) {
        notiProv.cargarNotificaciones(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final noti = context.watch<NotificacionesProvider>();

    final nombre = auth.userName ?? 'Empleador';

    final userId = auth.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // =====================================================
      // 🔹 APPBAR
      // =====================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Portal del Empleador",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 🔔 NOTIFICACIONES
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificacionesScreen(),
                    ),
                  );

                  if (userId != null && userId != 0) {
                    noti.cargarNotificaciones(userId);
                  }
                },
              ),
              if (noti.unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${noti.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // 🚪 CERRAR SESIÓN
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: "Cerrar sesión",
            onPressed: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/seleccion',
                (route) => false,
              );
            },
          ),
        ],
      ),

      // =====================================================
      // 🔹 BODY
      // =====================================================
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // 👋 BIENVENIDA
            Text(
              'Bienvenido 👋 $nombre',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B21B6),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Gestiona tu perfil y servicios",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 25),

            // 🧍‍♂️ MI PERFIL
            _menuButton(
              icon: Icons.person_outline,
              color: Colors.purple,
              title: "Mi Perfil",
              subtitle: "Editar información",
              onTap: () {
                Navigator.pushNamed(context, '/perfilEmpleador');
              },
            ),

            const SizedBox(height: 15),

            // ➕ PUBLICAR TRABAJO
            _menuButton(
              icon: Icons.add_circle_outline,
              color: Colors.blue,
              title: "Publicar un Trabajo",
              subtitle: "Crea una nueva oferta de trabajo",
              onTap: () => Navigator.pushNamed(context, "/publicarTrabajo"),
            ),

            const SizedBox(height: 15),

            // 🔍 BUSCAR PERFILES
            _menuButton(
              icon: Icons.group_outlined,
              color: Colors.green,
              title: "Buscar Perfiles Destacados",
              subtitle: "Encuentra trabajadores calificados",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuscarPerfilesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // 🔎 BUSCAR SERVICIOS
            _menuButton(
              icon: Icons.search,
              color: Colors.purple,
              title: "Buscar Servicios",
              subtitle: "Explora servicios disponibles",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OfertasScreen()),
                );
              },
            ),

            const SizedBox(height: 15),

            // 💰 MI BILLETERA
            _menuButton(
              icon: Icons.wallet_outlined,
              color: Colors.orange,
              title: "Mi Billetera",
              subtitle: "Control de gastos y recargas",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MiBilleteraEmpleadorScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // 🗂 MIS PUBLICACIONES
            _menuButton(
              icon: Icons.post_add_outlined,
              color: Colors.blue,
              title: "Mis Publicaciones",
              subtitle: "Gestiona tus trabajos publicados",
              onTap: () => Navigator.pushNamed(context, "/misPublicaciones"),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 🔧 BOTÓN REUTILIZABLE
  // =====================================================
  Widget _menuButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

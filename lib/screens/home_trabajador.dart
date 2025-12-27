import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/auth_provider.dart';
import '../providers/notificaciones_provider.dart';

// Pantallas del trabajador
import 'perfil_trabajador_screen.dart';
import 'mis_postulaciones_screen.dart';
import 'publicaciones_screen.dart';
import 'publicar_servicio_screen.dart';
import 'ofertas_screen.dart';
import 'billetera_trabajador_screen.dart';
import 'ofertas_trabajos_screen.dart';

// Notificaciones
import '../screens/notificaciones/notificaciones_screen.dart';

// Login
import 'login_screen.dart';

class HomeTrabajadorScreen extends StatefulWidget {
  const HomeTrabajadorScreen({super.key});

  @override
  State<HomeTrabajadorScreen> createState() => _HomeTrabajadorScreenState();
}

class _HomeTrabajadorScreenState extends State<HomeTrabajadorScreen> {

  // ======================================================
  // 🔥 CARGAR NOTIFICACIONES AL ENTRAR AL HOME
  // ======================================================
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final notiProv = context.read<NotificacionesProvider>();

      if (auth.userId != null) {
        notiProv.cargarNotificaciones(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.userName ?? "Trabajador";

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Portal del Trabajador',
          style: TextStyle(
            color: Color(0xFF8B5CF6),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [

          // ======================================================
          // 🔔 CAMPANA DE NOTIFICACIONES (YA FUNCIONA)
          // ======================================================
          Consumer<NotificacionesProvider>(
            builder: (_, noti, __) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      color: Color(0xFF8B5CF6),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificacionesScreen(),
                        ),
                      );

                      // 🔄 RECARGAR AL VOLVER
                      if (auth.userId != null) {
                        noti.cargarNotificaciones(auth.userId!);
                      }
                    },
                  ),

                  // 🔴 BADGE
                  if (noti.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${noti.unreadCount}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // ======================================================
          // 🚪 CERRAR SESIÓN
          // ======================================================
          TextButton.icon(
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Seguro deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sí'),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                await auth.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(rol: 'trabajador'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.black87),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.black87),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      // ======================== BODY ========================
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido 👋 $userName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B21B6),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gestiona tu perfil y servicios',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return _menuCard(
                          icon: Icons.search,
                          color: Colors.blue,
                          title: 'Buscar\nOfertas',
                          subtitle: 'Trabajos disponibles',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OfertasTrabajosScreen(),
                            ),
                          ),
                        );

                      case 1:
                        return _menuCard(
                          icon: Icons.person,
                          color: Colors.purple,
                          title: 'Mi\nPerfil',
                          subtitle: 'Editar información',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PerfilTrabajadorScreen(
                                userId: auth.userId ?? 0,
                                nombre: userName,
                                telefono: "No registrado",
                              ),
                            ),
                          ),
                        );

                      case 2:
                        return _menuCard(
                          icon: Icons.note_alt_outlined,
                          color: Colors.green,
                          title: 'Mis\nPostulaciones',
                          subtitle: 'Revisar solicitudes',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MisPostulacionesScreen(),
                            ),
                          ),
                        );

                      case 3:
                        return _menuCard(
                          icon: Icons.add_circle_outline,
                          color: Colors.orange,
                          title: 'Publicar\nServicio',
                          subtitle: 'Ofrece tus habilidades',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PublicarServicioScreen(),
                            ),
                          ),
                        );

                      case 4:
                        return _menuCard(
                          icon: Icons.account_balance_wallet,
                          color: Colors.teal,
                          title: 'Mi\nBilletera',
                          subtitle: 'Pagos e ingresos',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const BilleteraTrabajadorScreen(),
                            ),
                          ),
                        );

                      case 5:
                        return _menuCard(
                          icon: Icons.list_alt,
                          color: Colors.indigo,
                          title: 'Mis\nPublicaciones',
                          subtitle: 'Ver y gestionar',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PublicacionesScreen(),
                            ),
                          ),
                        );

                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // TARJETA MENÚ
  // ======================================================
  Widget _menuCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Flexible(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

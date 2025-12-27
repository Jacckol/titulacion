import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔹 Providers
import 'providers/auth_provider.dart';
import 'providers/trabajo_provider.dart';
import 'providers/trabajador_provider.dart';
import 'providers/postulaciones_provider.dart';
import 'providers/mis_servicios_provider.dart';
import 'providers/servicio_provider.dart';
import 'providers/transactions_provider.dart';
import 'providers/notificaciones_provider.dart';
import 'providers/billetera_provider.dart';
import 'providers/perfil_empleador_provider.dart'; // ✅ NUEVO

// 🔹 Pantallas principales
import 'screens/seleccion_screen.dart';
import 'screens/login_screen.dart';

// 🔹 Registro
import 'screens/register_trabajador_screen.dart';
import 'screens/register_employer_screen.dart';

// 🔹 Registro Empleador (nuevo flujo)
import 'screens/empleador/tipo_empleador_screen.dart';
import 'screens/empleador/registro_persona_natural_screen.dart';
import 'screens/empleador/registro_persona_juridica_screen.dart';

// 🔹 Home Empleador
import 'screens/empleador/home_empleador_screen.dart';
import 'screens/empleador/perfil_empleador_screen.dart';
import 'screens/empleador/mis_publicaciones_screen.dart';
import 'screens/empleador/publicar_trabajo_screen.dart';
import 'screens/empleador/mi_billetera_screen.dart';
import 'screens/empleador/historial_transacciones_screen.dart';
import 'screens/empleador/mi_perfil_empleador_screen.dart';

// 🔹 Home Trabajador
import 'screens/home_trabajador.dart';
import 'screens/perfil_trabajador_screen.dart';
import 'screens/mis_postulaciones_screen.dart';
import 'screens/publicar_servicio_screen.dart';
import 'screens/publicaciones_screen.dart';

// 🔹 Ofertas y trabajos
import 'screens/ofertas_screen.dart';
import 'screens/ofertas_trabajos_screen.dart';

// 🔹 Notificaciones
import 'screens/notificaciones/notificaciones_screen.dart';
import 'screens/notificaciones/notificacion_detalle_screen.dart';

// 🔥 Progreso del trabajo
import 'screens/empleador/progreso_trabajo_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TrabajoProvider()),
        ChangeNotifierProvider(create: (_) => TrabajadorProvider()),
        ChangeNotifierProvider(create: (_) => PostulacionesProvider()),
        ChangeNotifierProvider(create: (_) => MisServiciosProvider()),
        ChangeNotifierProvider(create: (_) => ServicioProvider()),
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),
        ChangeNotifierProvider(create: (_) => NotificacionesProvider()),
        ChangeNotifierProvider(create: (_) => BilleteraProvider()),

        // ✅ Perfil empleador (nuevo)
        ChangeNotifierProvider(create: (_) => PerfilEmpleadorProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TodoServy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFF3F5F7),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        initialRoute: '/seleccion',

        // ==========================================================
        // 🔥 SISTEMA DE RUTAS (SE MANTIENE + NUEVAS RUTAS)
        // ==========================================================
        onGenerateRoute: (settings) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final rol = args['rol'];

          switch (settings.name) {
            case '/seleccion':
              return MaterialPageRoute(
                builder: (_) => const SeleccionScreen(),
              );

            case '/login':
              return MaterialPageRoute(
                builder: (_) => LoginScreen(
                  rol: rol ?? 'trabajador',
                ),
              );

            case '/register':
              if (rol == 'trabajador') {
                return MaterialPageRoute(
                  builder: (_) =>
                      const RegisterTrabajadorScreen(rol: 'trabajador'),
                );
              }
              if (rol == 'empleador') {
                return MaterialPageRoute(
                  builder: (_) => const RegisterEmployerScreen(),
                );
              }
              return MaterialPageRoute(
                builder: (_) => const SeleccionScreen(),
              );

            // ================= NUEVO REGISTRO EMPLEADOR =================
            case '/empleador/tipo':
              return MaterialPageRoute(
                builder: (_) => const TipoEmpleadorScreen(),
              );

            case '/empleador/registro-natural':
              return MaterialPageRoute(
                builder: (_) => const RegistroPersonaNaturalScreen(),
              );

            case '/empleador/registro-juridico':
              return MaterialPageRoute(
                builder: (_) => const RegistroPersonaJuridicaScreen(),
              );
            // ============================================================

            case '/homeEmpleador':
              return MaterialPageRoute(
                builder: (_) => const HomeEmpleadorScreen(),
              );

            case '/perfilEmpleador':
              return MaterialPageRoute(
                builder: (_) => const PerfilEmpleadorScreen(),
              );

            case '/perfilEmpleador':
              return MaterialPageRoute(
                builder: (_) => const PerfilEmpleadorScreen(),
              );

            case '/perfilEmpleador':
              return MaterialPageRoute(
                builder: (_) => const MiPerfilEmpleadorScreen(),
              );

            case '/homeTrabajador':
              return MaterialPageRoute(
                builder: (_) => const HomeTrabajadorScreen(),
              );

            case '/perfilTrabajador':
              return MaterialPageRoute(
                builder: (_) => PerfilTrabajadorScreen(
                  userId: args['userId'] ?? 0,
                  nombre: args['nombre'] ?? 'Sin nombre',
                  telefono: args['telefono'] ?? 'No registrado',
                ),
              );

            case '/ofertasServicios':
              return MaterialPageRoute(
                builder: (_) => const OfertasScreen(),
              );

            case '/ofertasTrabajos':
              return MaterialPageRoute(
                builder: (_) => const OfertasTrabajosScreen(),
              );

            case '/misPostulaciones':
              return MaterialPageRoute(
                builder: (_) => const MisPostulacionesScreen(),
              );

            case '/publicarServicio':
              return MaterialPageRoute(
                builder: (_) => const PublicarServicioScreen(),
              );

            case '/publicaciones':
              return MaterialPageRoute(
                builder: (_) => const PublicacionesScreen(),
              );

            case '/publicarTrabajo':
              return MaterialPageRoute(
                builder: (_) => const PublicarTrabajoScreen(),
              );

            case '/misPublicaciones':
              return MaterialPageRoute(
                builder: (_) => const MisPublicacionesScreen(),
              );

            case '/miBilleteraEmpleador':
              return MaterialPageRoute(
                builder: (_) => const MiBilleteraEmpleadorScreen(),
              );

            case '/historialTransacciones':
              return MaterialPageRoute(
                builder: (_) => const HistorialTransaccionesScreen(),
              );

            case '/notificaciones':
              return MaterialPageRoute(
                builder: (_) => const NotificacionesScreen(),
              );

            case '/notificacionDetalle':
              return MaterialPageRoute(
                builder: (_) => NotificacionDetalleScreen(
                  notificacion: args['notificacion'],
                ),
              );

            // 🔥 PROGRESO DEL TRABAJO (YA CORRECTO)
            case '/progresoTrabajo':
              return MaterialPageRoute(
                builder: (_) => ProgresoTrabajoScreen(
                  trabajoId: args['trabajoId'],
                  trabajadorId: args['trabajadorId'],
                  nombreTrabajador: args['nombreTrabajador'],
                  tituloTrabajo: args['tituloTrabajo'],
                  rol: args['rol'],
                ),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const SeleccionScreen(),
              );
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/postulaciones_provider.dart';
import '../providers/auth_provider.dart';
import 'postulacion_detalle_screen.dart';

class MisPostulacionesScreen extends StatefulWidget {
  const MisPostulacionesScreen({super.key});

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

enum FiltroPostulacion { todas, pendientes, aceptadas, rechazadas }

// ✅ Item para lista con headers (fechas) + postulaciones
class _ListItem {
  final String? header;
  final Postulacion? postulacion;

  const _ListItem.header(this.header) : postulacion = null;
  const _ListItem.postulacion(this.postulacion) : header = null;

  bool get isHeader => header != null;
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> {
  FiltroPostulacion _filtro = FiltroPostulacion.todas;

  // ✅ AQUÍ CAMBIAS EL TIEMPO (2 = 48h)
  static const int diasExpiracion = 2;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postulacionesProv = context.read<PostulacionesProvider>();
      final auth = context.read<AuthProvider>();

      if (auth.userId != null) {
        postulacionesProv.cargarPostulaciones(auth.userId!);
      }
    });
  }

  // ======================================================
  // ✅ FECHA REAL: tu modelo ya tiene p.fecha (DateTime)
  // ======================================================
  DateTime _getCreated(Postulacion p) {
    final dt = p.fecha;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  // ======================================================
  // ✅ CUÁNTO TIEMPO QUEDA (para mostrar en UI)
  // ======================================================
  String _tiempoRestante(DateTime created) {
    final now = DateTime.now();
    final expira = created.add(const Duration(days: diasExpiracion));
    final diff = expira.difference(now);

    if (diff.isNegative) return "Expirada";

    final totalHoras = diff.inHours;
    final dias = totalHoras ~/ 24;
    final horas = totalHoras % 24;

    if (dias <= 0) return "Quedan ${horas}h";
    return "Quedan ${dias}d ${horas}h";
  }

  // ======================================================
  // ✅ FILTRAR POSTULACIONES VIGENTES (48h)
  // ======================================================
  List<Postulacion> _vigentes(List<Postulacion> input) {
    final now = DateTime.now();

    final filtradas = input.where((p) {
      final created = _getCreated(p);
      final horas = now.difference(created).inHours;
      return horas < (diasExpiracion * 24); // 2 días = 48h
    }).toList();

    // ordenar del más nuevo al más viejo
    filtradas.sort((a, b) => _getCreated(b).compareTo(_getCreated(a)));
    return filtradas;
  }

  // ======================================================
  // ✅ HEADER: Hoy / Ayer / dd/mm/yyyy
  // ======================================================
  String _fechaHeader(DateTime d) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final fecha = DateTime(d.year, d.month, d.day);

    final diff = hoy.difference(fecha).inDays;
    if (diff == 0) return "Hoy";
    if (diff == 1) return "Ayer";

    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return "$dd/$mm/$yyyy";
  }

  // ======================================================
  // ✅ CONSTRUIR LISTA CON HEADERS POR FECHA
  // ======================================================
  List<_ListItem> _buildItemsPorFecha(List<Postulacion> lista) {
    final items = <_ListItem>[];
    String? lastKey;

    for (final p in lista) {
      final created = _getCreated(p);
      final key =
          "${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}";
      final label = _fechaHeader(created);

      if (key != lastKey) {
        items.add(_ListItem.header(label));
        lastKey = key;
      }

      items.add(_ListItem.postulacion(p));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PostulacionesProvider>();

    // ✅ filtro por estado
    List<Postulacion> base;
    switch (_filtro) {
      case FiltroPostulacion.pendientes:
        base = prov.pendientes;
        break;
      case FiltroPostulacion.aceptadas:
        base = prov.aceptadas;
        break;
      case FiltroPostulacion.rechazadas:
        base = prov.rechazadas;
        break;
      default:
        base = prov.todas;
    }

    // ✅ expiración + orden
    final lista = _vigentes(base);

    // ✅ contadores que coincidan con lo visible
    final totalPend = _vigentes(prov.pendientes).length;
    final totalAcept = _vigentes(prov.aceptadas).length;
    final totalRech = _vigentes(prov.rechazadas).length;

    final items = _buildItemsPorFecha(lista);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Postulaciones'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // ================= CONTADORES =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _contador('Pendientes', totalPend, const Color(0xFFFFF7E0),
                    const Color(0xFF92400E)),
                const SizedBox(width: 8),
                _contador('Aceptadas', totalAcept, const Color(0xFFE0FBEA),
                    const Color(0xFF166534)),
                const SizedBox(width: 8),
                _contador('Rechazadas', totalRech, const Color(0xFFFEE2E2),
                    const Color(0xFFB91C1C)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= FILTROS =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filtroChip('Todas', FiltroPostulacion.todas),
                _filtroChip('Pendientes', FiltroPostulacion.pendientes),
                _filtroChip('Aceptadas', FiltroPostulacion.aceptadas),
                _filtroChip('Rechazadas', FiltroPostulacion.rechazadas),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ================= LISTA (CON HEADERS) =================
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no tienes postulaciones',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];

                      // ✅ HEADER FECHA
                      if (it.isHeader) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 10),
                          child: Text(
                            it.header!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }

                      return _cardPostulacion(it.postulacion!);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // CONTADOR
  // ======================================================
  Widget _contador(String label, int cantidad, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(
              cantidad.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: textColor)),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // FILTRO CHIP
  // ======================================================
  Widget _filtroChip(String texto, FiltroPostulacion value) {
    final activo = _filtro == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtro = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                color: activo ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================================================
  // CARD POSTULACIÓN (SIN ACEPTAR/RECHAZAR) + chip tiempo
  // ======================================================
  Widget _cardPostulacion(Postulacion p) {
    Color bg;
    Color txt;
    String estadoTxt;

    switch (p.estado) {
      case EstadoPostulacion.aceptada:
        bg = const Color(0xFFE0FBEA);
        txt = const Color(0xFF166534);
        estadoTxt = 'Aceptada';
        break;
      case EstadoPostulacion.rechazada:
        bg = const Color(0xFFFEE2E2);
        txt = const Color(0xFFB91C1C);
        estadoTxt = 'Rechazada';
        break;
      default:
        bg = const Color(0xFFFFF7E0);
        txt = const Color(0xFF92400E);
        estadoTxt = 'Pendiente';
    }

    final created = _getCreated(p);
    final tiempoTxt = _tiempoRestante(created);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              p.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // ✅ tiempo restante
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tiempoTxt,
              style: const TextStyle(
                color: Color(0xFF5B21B6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // ✅ estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(
              estadoTxt,
              style: TextStyle(
                color: txt,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ]),

        const SizedBox(height: 10),

        Text(
          p.categoria,
          style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 12),
        ),

        const SizedBox(height: 14),

        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostulacionDetalleScreen(postulacion: p),
              ),
            ),
            child: const Text('Ver detalle'),
          ),
          TextButton(
            onPressed: () {
              context.read<PostulacionesProvider>().eliminarPostulacionLocal(p.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ])
      ]),
    );
  }
}

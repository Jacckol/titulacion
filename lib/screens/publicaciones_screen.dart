import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../providers/mis_servicios_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/postulaciones_provider.dart';
import 'editar_servicio_screen.dart';

class PublicacionesScreen extends StatefulWidget {
  const PublicacionesScreen({super.key});

  @override
  State<PublicacionesScreen> createState() => _PublicacionesScreenState();
}

// ✅ Item para lista con headers (fechas) + servicios
class _ListItem {
  final String? header;
  final Map<String, dynamic>? servicio;

  const _ListItem.header(this.header) : servicio = null;
  const _ListItem.servicio(this.servicio) : header = null;

  bool get isHeader => header != null;
}

class _PublicacionesScreenState extends State<PublicacionesScreen> {
  List<dynamic> servicios = [];
  bool cargando = true;

  // bloquear botones mientras acepta/rechaza
  final Set<int> _postulacionesCargando = {};

  // ✅ cache local para NO depender de servicio["postulaciones"]
  final Map<int, List<Map<String, dynamic>>> _cachePostulaciones = {};
  final Map<int, int> _conteoPostulaciones = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  // ============================================================
  // 🔥 CARGAR SERVICIOS (SOLO < 24 HORAS)
  // ============================================================
  Future<void> _cargarDatos() async {
    if (mounted) setState(() => cargando = true);

    final auth = context.read<AuthProvider>();
    final prov = context.read<MisServiciosProvider>();

    final data = await prov.cargarMisServicios(auth.userId ?? 0);
    final ahora = DateTime.now();

    servicios = data.where((s) {
      if (s["createdAt"] == null) return false;
      try {
        final fecha = DateTime.parse(s["createdAt"]).toLocal();
        return ahora.difference(fecha).inHours < 24;
      } catch (_) {
        return false;
      }
    }).toList();

    // ✅ ordenar del más nuevo al más viejo por createdAt
    servicios.sort((a, b) {
      final da = DateTime.tryParse((a["createdAt"] ?? "").toString())?.toLocal();
      final db = DateTime.tryParse((b["createdAt"] ?? "").toString())?.toLocal();
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    // ✅ RESETEO cache
    _cachePostulaciones.clear();
    _conteoPostulaciones.clear();

    // ✅ si el backend ya manda postulaciones embebidas, se usan para que el contador NO sea 0
    for (final s in servicios) {
      final sid = _toInt(s["id"]);
      final raw = s["postulaciones"];

      if (sid > 0 && raw is List) {
        final lista = raw
            .whereType<Map>()
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

        _cachePostulaciones[sid] = lista;
        _conteoPostulaciones[sid] = lista.length;
      } else if (sid > 0) {
        _conteoPostulaciones[sid] = _conteoPostulaciones[sid] ?? 0;
      }
    }

    if (mounted) setState(() => cargando = false);
  }

  // ============================
  // FECHAS → "Hoy / Ayer / dd/mm/yyyy"
  // ============================
  String _fechaHeader(DateTime d) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final fecha = DateTime(d.year, d.month, d.day);

    final diff = hoy.difference(fecha).inDays;
    if (diff == 0) return "Hoy";
    if (diff == 1) return "Ayer";

    String dd = d.day.toString().padLeft(2, '0');
    String mm = d.month.toString().padLeft(2, '0');
    String yyyy = d.year.toString();
    return "$dd/$mm/$yyyy";
  }

  // ✅ construir lista con headers por fecha
  List<_ListItem> _buildItemsPorFecha(List<dynamic> lista) {
    final items = <_ListItem>[];
    String? lastKey;

    for (final s in lista) {
      final createdStr = (s["createdAt"] ?? "").toString();
      final parsed = DateTime.tryParse(createdStr);

      String key;
      String label;

      if (parsed == null) {
        key = "SIN_FECHA";
        label = "Sin fecha";
      } else {
        final d = parsed.toLocal();
        key =
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        label = _fechaHeader(d);
      }

      if (key != lastKey) {
        items.add(_ListItem.header(label));
        lastKey = key;
      }

      items.add(_ListItem.servicio(Map<String, dynamic>.from(s)));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItemsPorFecha(servicios);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text("Mis Publicaciones"),
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : servicios.isEmpty
              ? const Center(
                  child: Text(
                    "No tienes publicaciones activas (24h)",
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }

                    return _cardPublicacion(context, it.servicio!);
                  },
                ),
    );
  }

  // ============================================================
  // 🔹 CARD DE PUBLICACIÓN
  // ============================================================
  Widget _cardPublicacion(BuildContext context, Map<String, dynamic> servicio) {
    final int servicioId = _toInt(servicio["id"]);
    final String titulo = (servicio["titulo"] ?? "").toString();
    final String categoria = (servicio["categoria"] ?? "").toString();
    final String ubicacion = (servicio["ubicacion"] ?? "").toString();
    final presupuesto = servicio["presupuesto"];
    final String descripcion = (servicio["descripcion"] ?? "").toString();
    final String fecha = (servicio["createdAt"] ?? "").toString();

    // ✅ contador: cache primero; si no hay, intenta leer del servicio embebido; si no, 0
    final embedded = (servicio["postulaciones"] is List)
        ? (servicio["postulaciones"] as List).length
        : 0;
    final int count = _conteoPostulaciones[servicioId] ?? embedded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- TÍTULO + PRECIO ----------------
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                "\$ $presupuesto",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ---------------- BADGES ----------------
          Row(
            children: [
              _badge(
                categoria,
                background: const Color(0xFFEDE9FE),
                textColor: const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 8),
              _badge(
                "⏳ 24h activo",
                background: const Color(0xFFFFF7E0),
                textColor: const Color(0xFF92400E),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ---------------- UBICACIÓN ----------------
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                ubicacion,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ---------------- DESCRIPCIÓN ----------------
          Text(
            descripcion,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),

          const SizedBox(height: 12),

          Text(
            "Publicado: $fecha",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),

          const SizedBox(height: 16),

          // =================== 🔥 ACCIONES ===================
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final actualizado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarServicioScreen(servicio: servicio),
                    ),
                  );
                  if (actualizado == true) _cargarDatos();
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Editar"),
              ),

              // ✅ usa embebido/cache; si no existe, pide al backend
              ElevatedButton.icon(
                onPressed: () async {
                  List<Map<String, dynamic>> lista = [];

                  final raw = servicio["postulaciones"];
                  if (raw is List) {
                    lista = raw
                        .whereType<Map>()
                        .map<Map<String, dynamic>>(
                            (e) => Map<String, dynamic>.from(e))
                        .toList();

                    _cachePostulaciones[servicioId] = lista;
                    _conteoPostulaciones[servicioId] = lista.length;
                    if (mounted) setState(() {});
                  } else {
                    lista = await _cargarPostulacionesServicio(servicioId);
                  }

                  if (!mounted) return;

                  _verPostulaciones(
                    context: context,
                    servicioId: servicioId,
                    postulaciones: lista,
                  );
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: Text("Postulaciones ($count)"),
              ),

              ElevatedButton.icon(
                onPressed: () async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Eliminar servicio"),
                      content: const Text(
                          "¿Seguro deseas eliminar esta publicación?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Eliminar"),
                        ),
                      ],
                    ),
                  );

                  if (confirmar == true) {
                    final prov = context.read<MisServiciosProvider>();
                    final ok = await prov.eliminarServicio(servicioId);
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            ok ? "Servicio eliminado" : "No se pudo eliminar ❌"),
                        backgroundColor: ok ? Colors.red : Colors.black,
                      ),
                    );

                    if (ok) _cargarDatos();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text("Eliminar"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ CARGAR POSTULACIONES DEL SERVICIO (cache + contador)
  // ============================================================
  Future<List<Map<String, dynamic>>> _cargarPostulacionesServicio(
      int servicioId) async {
    if (_cachePostulaciones.containsKey(servicioId)) {
      return _cachePostulaciones[servicioId]!;
    }

    final postProv = context.read<PostulacionesProvider>();
    final lista = await postProv.obtenerPostulacionesServicio(servicioId);

    _cachePostulaciones[servicioId] = lista;
    _conteoPostulaciones[servicioId] = lista.length;

    if (mounted) setState(() {});
    return lista;
  }

  // ============================================================
  // 🔥 MODAL POSTULACIONES
  // ============================================================
  void _verPostulaciones({
    required BuildContext context,
    required int servicioId,
    required List postulaciones,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.70,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context2, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Postulaciones",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (postulaciones.isEmpty)
                    const Expanded(
                      child: Center(child: Text("Aún no hay postulaciones")),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: postulaciones.length,
                        itemBuilder: (_, i) {
                          final p = postulaciones[i] as Map<String, dynamic>;
                          return _cardPostulacion(
                            p,
                            onEstado: (estado) async {
                              final int postId = _toInt(p["id"]);
                              if (postId == 0) return;

                              await _cambiarEstado(postId: postId, estado: estado);

                              if (!mounted) return;
                              Navigator.pop(context2);

                              await _cargarDatos();
                              _cachePostulaciones.remove(servicioId);
                              _conteoPostulaciones.remove(servicioId);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ✅ Cambiar estado postulación (aceptar/rechazar)
  // ============================================================
  Future<void> _cambiarEstado({
    required int postId,
    required String estado,
  }) async {
    if (_postulacionesCargando.contains(postId)) return;

    setState(() => _postulacionesCargando.add(postId));

    try {
      final postProv = context.read<PostulacionesProvider>();

      final ok = await postProv.cambiarEstadoPostulacion(
        postulacionId: postId,
        estado: estado,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? "Postulación $estado ✅" : "No se pudo actualizar ❌"),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _postulacionesCargando.remove(postId));
    }
  }

  // ============================================================
  // 🔹 CARD POSTULACIÓN
  // ============================================================
  Widget _cardPostulacion(
    Map<String, dynamic> p, {
    required Future<void> Function(String estado) onEstado,
  }) {
    final int postId = _toInt(p["id"]);
    final String estado = (p["estado"] ?? "pendiente").toString();
    final bool loading = _postulacionesCargando.contains(postId);

    final postulante = p["postulante"] ?? {};
    final String nombre =
        (postulante["nombre"] ?? postulante["email"] ?? p["empresa"] ?? "Usuario")
            .toString();
    final String mensaje = (p["mensaje"] ?? "Sin mensaje").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              _estadoChip(estado),
            ],
          ),
          const SizedBox(height: 8),
          Text(mensaje),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: (loading || estado == "aceptado")
                    ? null
                    : () => onEstado("aceptado"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Aceptar"),
              ),
              ElevatedButton(
                onPressed: (loading || estado == "rechazado")
                    ? null
                    : () => onEstado("rechazado"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Rechazar"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _estadoChip(String estado) {
    Color bg;
    Color tx;

    switch (estado) {
      case "aceptado":
        bg = const Color(0xFFDCFCE7);
        tx = const Color(0xFF166534);
        break;
      case "rechazado":
        bg = const Color(0xFFFEE2E2);
        tx = const Color(0xFF991B1B);
        break;
      default:
        bg = const Color(0xFFFFF7E0);
        tx = const Color(0xFF92400E);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tx),
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================
  Widget _badge(
    String label, {
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  // helpers
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

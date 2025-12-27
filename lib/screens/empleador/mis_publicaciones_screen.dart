import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../providers/auth_provider.dart';
import 'ver_postulaciones_screen.dart';

// 👉 EMULADOR ANDROID
const String baseUrl = "http://10.0.2.2:4000";

class MisPublicacionesScreen extends StatefulWidget {
  const MisPublicacionesScreen({super.key});

  @override
  State<MisPublicacionesScreen> createState() => _MisPublicacionesScreenState();
}

// ✅ Item para lista con headers (fechas) + trabajos
class _ListItem {
  final String? header;
  final Map? trabajo;

  const _ListItem.header(this.header) : trabajo = null;
  const _ListItem.trabajo(this.trabajo) : header = null;

  bool get isHeader => header != null;
}

class _MisPublicacionesScreenState extends State<MisPublicacionesScreen> {
  List trabajos = [];
  bool loading = true;

  // ✅ AQUÍ CAMBIAS EL TIEMPO (1 = 24h)
  static const int diasExpiracion = 1;

  // ============================
  // HELPERS FECHA / EXPIRACIÓN
  // ============================
  DateTime? _createdLocal(Map t) {
    final createdStr = (t["createdAt"] ?? "").toString();
    final dt = DateTime.tryParse(createdStr);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  String _expiracionLabel(Map t) {
    // ✅ Si existe fecha límite (desde backend), se usa esa
    final flStr = (t["fechaLimite"] ?? "").toString().trim();
    if (flStr.isNotEmpty) {
      final fl = DateTime.tryParse(flStr);
      if (fl != null) {
        final vence = DateTime(fl.year, fl.month, fl.day, 23, 59, 59);
        final now = DateTime.now();
        final diff = vence.difference(now);

        if (diff.isNegative) return "⛔ Publicación vencida";

        if (diff.inHours >= 1) {
          final h = diff.inHours;
          final m = diff.inMinutes % 60;
          return "📅 Fecha límite $flStr · Quedan ${h}h ${m}m";
        } else {
          final m = diff.inMinutes;
          return "📅 Fecha límite $flStr · Quedan ${m}m";
        }
      }
      // si viene mal parseado, caemos a cálculo por createdAt
    }

    // Fallback: cálculo por createdAt (duración fija)
    final created = _createdLocal(t);
    if (created == null) return "⏳ Sin fecha (no puedo calcular)";

    final vence = created.add(Duration(days: diasExpiracion));
    final now = DateTime.now();
    final diff = vence.difference(now);

    // si ya venció (por si acaso)
    if (diff.isNegative) return "⛔ Publicación vencida";

    final duracionTxt = diasExpiracion == 1 ? "24h" : "${diasExpiracion}d";

    // mostrar restante bonito
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return "⏳ Duración $duracionTxt · Quedan ${h}h ${m}m";
    } else {
      final m = diff.inMinutes;
      return "⏳ Duración $duracionTxt · Quedan ${m}m";
    }
  }

  // ============================
  // CARGAR TRABAJOS DEL EMPLEADOR
  // ============================
  Future<void> cargarTrabajos() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final url = Uri.parse("$baseUrl/api/trabajos/mios/${auth.userId}");

      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      print("🟣 MIS TRABAJOS → ${resp.statusCode} | ${resp.body}");

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List lista = (data["trabajos"] ?? []) as List;

        final ahoraLocal = DateTime.now();
        final ahoraUtc = DateTime.now().toUtc();

        // ✅ 1) FILTRAR:
        // - Si viene fechaLimite (YYYY-MM-DD): ocultar si ya venció
        // - Si NO viene fechaLimite: fallback al filtro por createdAt (24h)
        final filtrados = lista.where((t) {
          final flStr = (t["fechaLimite"] ?? "").toString().trim();
          if (flStr.isNotEmpty) {
            final fl = DateTime.tryParse(flStr);
            if (fl != null) {
              final vence = DateTime(fl.year, fl.month, fl.day, 23, 59, 59);
              return DateTime.now().isBefore(vence);
            }
            // si viene mal parseado, no oculto
            return true;
          }

          final createdStr = (t["createdAt"] ?? "").toString();
          final created = DateTime.tryParse(createdStr);

          // Si no viene createdAt, NO lo oculto (para no perder publicaciones por un bug)
          if (created == null) return true;

          final ahora = created.isUtc ? ahoraUtc : ahoraLocal;

          // ✅ con diasExpiracion=1 => solo < 24h
          return ahora.difference(created).inDays < diasExpiracion;
        }).toList();

        // ✅ ordenar del más nuevo al más viejo por createdAt (si existe)
        filtrados.sort((a, b) {
          final da = DateTime.tryParse((a["createdAt"] ?? "").toString());
          final db = DateTime.tryParse((b["createdAt"] ?? "").toString());
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });

        if (!mounted) return;
        setState(() {
          trabajos = filtrados;
          loading = false;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error ${resp.statusCode}: ${resp.body}")),
        );
        setState(() => loading = false);
      }
    } catch (e) {
      print("❌ Error cargando trabajos: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
      setState(() => loading = false);
    }
  }

  // ============================
  // ELIMINAR TRABAJO
  // ============================
  Future<void> eliminarTrabajo(int id) async {
    final url = Uri.parse("$baseUrl/api/trabajos/$id");
    final resp = await http.delete(url);

    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Trabajo eliminado")));
      cargarTrabajos();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${resp.body}")));
    }
  }

  void confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar publicación"),
        content: const Text("¿Seguro que deseas eliminar este trabajo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              eliminarTrabajo(id);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ============================
  // EDITAR TRABAJO
  // ============================
  void editarTrabajo(Map trabajo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarTrabajoScreen(trabajo: trabajo),
      ),
    ).then((_) => cargarTrabajos());
  }

  // ============================
  // CAMBIAR ESTADO
  // ============================
  Future<void> cambiarEstado(int id, String estado) async {
    final url = Uri.parse("$baseUrl/api/trabajos/$id/estado");

    final resp = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"estado": estado}),
    );

    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Estado actualizado a $estado")),
      );
      cargarTrabajos();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${resp.body}")));
    }
  }

  @override
  void initState() {
    super.initState();
    cargarTrabajos();
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

  // ✅ CONSTRUIR LISTA CON HEADERS POR FECHA
  List<_ListItem> _buildItemsPorFecha(List lista) {
    final items = <_ListItem>[];
    String? lastKey;

    for (final t in lista) {
      final createdStr = (t["createdAt"] ?? "").toString();
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

      items.add(_ListItem.trabajo(t));
    }

    return items;
  }

  Widget _chipInfo(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF92400E),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btnStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      minimumSize: const Size(0, 34),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    final items = _buildItemsPorFecha(trabajos);

    return Scaffold(
      backgroundColor: const Color(0xffF3F0FF),
      appBar: AppBar(
        title: const Text("Mis Publicaciones"),
        backgroundColor: const Color(0xff6A4CE8),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : trabajos.isEmpty
              ? const Center(child: Text("No tienes publicaciones"))
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

                    final t = it.trabajo!;
                    final estado = (t["estado"] ?? "activo").toString();

                    Color colorEstado = estado == "finalizado"
                        ? Colors.green
                        : estado == "pausado"
                            ? Colors.orange
                            : Colors.blue;

                    // ✅ NUEVO: texto de expiración / tiempo restante
                    final expiraTxt = _expiracionLabel(t);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (t["titulo"] ?? "").toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorEstado.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  estado.toUpperCase(),
                                  style: TextStyle(
                                    color: colorEstado,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // ✅ NUEVO: CHIP CON DURACIÓN / RESTANTE
                          _chipInfo(expiraTxt),

                          const SizedBox(height: 10),

                          Text(
                            (t["descripcion"] ?? "").toString(),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.place,
                                  size: 16, color: Colors.deepPurple),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text((t["ubicacion"] ?? "").toString()),
                              ),
                              const SizedBox(width: 20),
                              const Icon(Icons.attach_money,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text("${t["salario"] ?? ""}"),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                TextButton(
                                  style: btnStyle,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VerPostulacionesScreen(
                                          trabajoId: t["id"],
                                          tituloTrabajo: t["titulo"] ?? "",
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Ver postulaciones"),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) => cambiarEstado(t["id"], v),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: "activo",
                                      child: Text("Marcar activo"),
                                    ),
                                    PopupMenuItem(
                                      value: "pausado",
                                      child: Text("Pausar publicación"),
                                    ),
                                    PopupMenuItem(
                                      value: "finalizado",
                                      child: Text("Marcar como finalizado"),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert),
                                ),
                                TextButton.icon(
                                  style: btnStyle,
                                  onPressed: () => editarTrabajo(t),
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue, size: 18),
                                  label: const Text(
                                    "Editar",
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                TextButton.icon(
                                  style: btnStyle,
                                  onPressed: () => confirmarEliminar(t["id"]),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 18),
                                  label: const Text(
                                    "Eliminar",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// =============================
// PANTALLA DE EDITAR TRABAJO
// =============================
class EditarTrabajoScreen extends StatefulWidget {
  final Map trabajo;

  const EditarTrabajoScreen({super.key, required this.trabajo});

  @override
  State<EditarTrabajoScreen> createState() => _EditarTrabajoScreenState();
}

class _EditarTrabajoScreenState extends State<EditarTrabajoScreen> {
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final ubicacionCtrl = TextEditingController();
  final salarioCtrl = TextEditingController();
  String categoria = "";

  DateTime? fechaLimite;

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  Future<void> _pickFechaLimite() async {
    final ahora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaLimite ?? ahora,
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: DateTime(ahora.year + 5),
    );
    if (picked != null) {
      setState(() => fechaLimite = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    tituloCtrl.text = widget.trabajo["titulo"] ?? "";
    descripcionCtrl.text = widget.trabajo["descripcion"] ?? "";
    ubicacionCtrl.text = widget.trabajo["ubicacion"] ?? "";
    salarioCtrl.text = (widget.trabajo["salario"] ?? "").toString();
    categoria = widget.trabajo["categoria"] ?? "";

    final flStr = (widget.trabajo["fechaLimite"] ?? "").toString();
    fechaLimite = DateTime.tryParse(flStr);
  }

  Future<void> actualizar() async {
    final url = Uri.parse("$baseUrl/api/trabajos/${widget.trabajo["id"]}");

    final body = {
      "titulo": tituloCtrl.text.trim(),
      "descripcion": descripcionCtrl.text.trim(),
      "salario": salarioCtrl.text.trim(),
      "ubicacion": ubicacionCtrl.text.trim(),
      "categoria": categoria,
      "fechaLimite": fechaLimite == null ? null : _fmtDate(fechaLimite!),
    };

    final resp = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trabajo actualizado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${resp.body}")),
      );
    }
  }

  Widget inputBox(String label, TextEditingController c, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: c,
            maxLines: maxLines,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F0FF),
      appBar: AppBar(
        title: const Text("Editar Trabajo"),
        backgroundColor: const Color(0xff6A4CE8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            inputBox("Título del trabajo", tituloCtrl),
            inputBox("Descripción detallada", descripcionCtrl, maxLines: 4),
            inputBox("Ubicación", ubicacionCtrl),
            inputBox("Presupuesto (\$)", salarioCtrl),

            // 📅 Fecha límite
            const Text(
              "Fecha límite",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickFechaLimite,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      fechaLimite == null
                          ? "Selecciona una fecha"
                          : _fmtDate(fechaLimite!),
                      style: TextStyle(
                        color: fechaLimite == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Categoría",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: categoria.isEmpty ? null : categoria,
                underline: const SizedBox(),
                items: const ["Electricidad", "Plomería", "Pintura", "Limpieza"]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => categoria = v ?? ""),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: actualizar,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    "Guardar Cambios",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

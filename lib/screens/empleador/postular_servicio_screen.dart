import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../providers/postulaciones_provider.dart';
import '../../providers/auth_provider.dart';

import 'ver_perfil_trabajador_screen.dart';

class PostularServicioScreen extends StatefulWidget {
  final int servicioId;

  final String titulo;
  final String categoria;
  final String empresa;
  final String ubicacion;
  final String salario;
  final String descripcion;

  // (opcional) si ya lo tienes desde la lista
  final int? trabajadorId;
  final String? trabajadorNombre;
  final String? trabajadorTelefono;

  const PostularServicioScreen({
    super.key,
    required this.servicioId,
    required this.titulo,
    required this.categoria,
    required this.empresa,
    required this.ubicacion,
    required this.salario,
    required this.descripcion,
    this.trabajadorId,
    this.trabajadorNombre,
    this.trabajadorTelefono,
  });

  @override
  State<PostularServicioScreen> createState() => _PostularServicioScreenState();
}

class _PostularServicioScreenState extends State<PostularServicioScreen> {
  static const _apiBase = "http://10.0.2.2:4000";

  final TextEditingController mensajeCtrl = TextEditingController();
  bool enviando = false;

  int? _trabajadorId;
  bool _cargandoTrabajadorId = false;

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  int? _extractTrabajadorId(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final m = Map<String, dynamic>.from(data);

      // ✅ soporta: { trabajadorId }, { userId }, { ownerId }, { creadorId }
      final direct = _toInt(m["trabajadorId"]) ??
          _toInt(m["userId"]) ??
          _toInt(m["ownerId"]) ??
          _toInt(m["creadorId"]);
      if (direct != null && direct > 0) return direct;

      // ✅ soporta: { servicio: { userId: ... } }
      if (m["servicio"] is Map) return _extractTrabajadorId(m["servicio"]);

      // ✅ soporta: { data: { ... } }
      if (m["data"] is Map) return _extractTrabajadorId(m["data"]);
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _trabajadorId = widget.trabajadorId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if ((_trabajadorId ?? 0) <= 0) {
        await _resolverTrabajadorIdPorServicio();
      }
    });
  }

  Future<void> _resolverTrabajadorIdPorServicio() async {
    if (widget.servicioId <= 0) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token; // ✅ puede ser null y NO pasa nada

    setState(() => _cargandoTrabajadorId = true);

    try {
      // ✅ IMPORTANTE: en tu backend NO existe /detalle ni /one
      // ✅ aquí dejamos SOLO las rutas que tú SÍ debes crear
      final paths = <String>[
        "/api/servicios/${widget.servicioId}",         // ✅ NUEVA ruta que vas a crear en backend
        "/api/servicios/debug/${widget.servicioId}",   // ✅ existe ya (debugById)
      ];

      for (final p in paths) {
        final uri = Uri.parse("$_apiBase$p");

        final resp = await http.get(
          uri,
          headers: {
            if (token != null) "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        debugPrint("🟣 GET $uri => ${resp.statusCode}");

        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          final id = _extractTrabajadorId(decoded);

          debugPrint("🟣 trabajadorId detectado => $id");

          if (id != null && id > 0) {
            if (!mounted) return;
            setState(() => _trabajadorId = id);
            break;
          }
        } else {
          debugPrint("🟣 body => ${resp.body}");
        }
      }
    } catch (e) {
      debugPrint("🔴 error resolviendo trabajadorId: $e");
    } finally {
      if (mounted) setState(() => _cargandoTrabajadorId = false);
    }
  }

  void _abrirPerfilTrabajador() {
    final id = _trabajadorId;

    if (_cargandoTrabajadorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cargando perfil..."),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo identificar el trabajador ❌"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerPerfilTrabajadorScreen(
          trabajadorId: id,
          nombreInicial: widget.trabajadorNombre,
          telefonoInicial: widget.trabajadorTelefono,
        ),
      ),
    );
  }

  @override
  void dispose() {
    mensajeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final postProv = context.read<PostulacionesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Detalles del Servicio",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Título + Ver perfil
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _abrirPerfilTrabajador,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xFFEDE9FE),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_cargandoTrabajadorId) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Text(
                        "Ver perfil",
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "Publicado por: ${widget.empresa}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.categoria,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Descripción del Servicio",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              widget.descripcion,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.ubicacion, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(Icons.attach_money, size: 20),
                const SizedBox(width: 4),
                Text(
                  widget.salario,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Mensaje al trabajador:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: mensajeCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        final userId = auth.userId;

                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Debes iniciar sesión primero"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (widget.servicioId <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ID de servicio inválido ❌"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final mensaje = mensajeCtrl.text.trim().isEmpty
                            ? "Estoy interesado en contratar tu servicio."
                            : mensajeCtrl.text.trim();

                        setState(() => enviando = true);

                        try {
                          final ok = await postProv.crearPostulacionServicio(
                            servicioId: widget.servicioId,
                            userId: userId,
                            mensaje: mensaje,
                          );

                          if (!mounted) return;

                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Postulación enviada a "${widget.titulo}"'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Error al enviar la postulación ❌"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => enviando = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Postular Ahora",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

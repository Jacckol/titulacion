import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mis_servicios_provider.dart';

class EditarServicioScreen extends StatefulWidget {
  final Map<String, dynamic> servicio;

  const EditarServicioScreen({super.key, required this.servicio});

  @override
  State<EditarServicioScreen> createState() => _EditarServicioScreenState();
}

class _EditarServicioScreenState extends State<EditarServicioScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController tituloCtrl;
  late TextEditingController categoriaCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController ubicacionCtrl;
  late TextEditingController presupuestoCtrl;

  @override
  void initState() {
    super.initState();

    tituloCtrl = TextEditingController(text: widget.servicio["titulo"]);
    categoriaCtrl = TextEditingController(text: widget.servicio["categoria"]);
    descripcionCtrl = TextEditingController(text: widget.servicio["descripcion"]);
    ubicacionCtrl = TextEditingController(text: widget.servicio["ubicacion"]);
    presupuestoCtrl =
        TextEditingController(text: widget.servicio["presupuesto"].toString());
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MisServiciosProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Servicio"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _campo("Título del servicio", tituloCtrl),
              const SizedBox(height: 12),

              _campo("Categoría", categoriaCtrl),
              const SizedBox(height: 12),

              _campoGrande("Descripción", descripcionCtrl),
              const SizedBox(height: 12),

              _campo("Ubicación", ubicacionCtrl),
              const SizedBox(height: 12),

              _campo("Presupuesto (\$)", presupuestoCtrl, numero: true),
              const SizedBox(height: 25),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final ok = await prov.editarServicio(
                    id: widget.servicio["id"],
                    titulo: tituloCtrl.text,
                    categoria: categoriaCtrl.text,
                    descripcion: descripcionCtrl.text,
                    ubicacion: ubicacionCtrl.text,
                    presupuesto:
                        double.tryParse(presupuestoCtrl.text) ?? 0,
                  );

                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Servicio actualizado correctamente"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error al actualizar el servicio"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  "Guardar Cambios",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Campo normal
  Widget _campo(String label, TextEditingController ctrl,
      {bool numero = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: numero ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          v == null || v.isEmpty ? "Este campo es obligatorio" : null,
    );
  }

  // 🔹 Campo grande (Descripción)
  Widget _campoGrande(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          v == null || v.isEmpty ? "Este campo es obligatorio" : null,
    );
  }
}

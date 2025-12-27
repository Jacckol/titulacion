import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterEmployerScreen extends StatefulWidget {
  const RegisterEmployerScreen({super.key});

  @override
  State<RegisterEmployerScreen> createState() => _RegisterEmployerScreenState();
}

class _RegisterEmployerScreenState extends State<RegisterEmployerScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final empresaController = TextEditingController();
  final rucController = TextEditingController();
  final responsableController = TextEditingController();
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();

  File? _fotoFile;
  File? _recordPolicialFile;
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  Future<void> _tomarFoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _fotoFile = File(picked.path));
    }
  }

  Future<void> _pickRecordPolicial() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _recordPolicialFile = File(result.files.single.path!));
    }
  }

  // ===============================================================
  // 🔥 PASO 1: Registrar usuario en /register (CON TODOS LOS DATOS)
  // ===============================================================
  Future<int?> _crearUsuario() async {
    final uri = Uri.parse("http://10.0.2.2:4000/api/register");

    print("📤 Enviando registro de USUARIO...");

    final resp = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombreController.text.trim(),
        "email": emailController.text.trim(),
        "password": passController.text.trim(),
        "rol": "empleador",

        // CAMPOS OBLIGATORIOS PARA EMPLEADOR
        "empresa": empresaController.text.trim(),
        "ruc": rucController.text.trim(),
        "responsable": responsableController.text.trim(),
        "telefono": telefonoController.text.trim(),
        "direccion": direccionController.text.trim(),
      }),
    );

    print("📥 RESPUESTA USUARIO => ${resp.statusCode} | ${resp.body}");

    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data["user"]["id"];
    }

    return null;
  }

  // ===============================================================
  // 🔥 PASO 2: Registrar datos del empleador con foto
  // ===============================================================
  Future<bool> _crearEmpleador(int userId) async {
    final uri = Uri.parse("http://10.0.2.2:4000/api/empleadores");

    print("📤 Enviando registro de EMPLEADOR...");

    final request = http.MultipartRequest("POST", uri);

    request.fields["userId"] = userId.toString();
    request.fields["empresa"] = empresaController.text.trim();
    request.fields["ruc"] = rucController.text.trim();
    request.fields["responsable"] = responsableController.text.trim();
    request.fields["telefono"] = telefonoController.text.trim();
    request.fields["direccion"] = direccionController.text.trim();

    request.files.add(await http.MultipartFile.fromPath("foto", _fotoFile!.path));

    // ✅ Récord policial opcional (PDF o imagen)
    if (_recordPolicialFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "recordPolicial",
          _recordPolicialFile!.path,
        ),
      );
    }

    final res = await request.send();
    final body = await res.stream.bytesToString();

    print("📥 RESPUESTA EMPLEADOR => ${res.statusCode} | $body");

    return res.statusCode == 201;
  }

  // ===============================================================
  // 🔥 CONTROLADOR PRINCIPAL
  // ===============================================================
  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes tomarte una foto")),
      );
      return;
    }

    // no obligamos el récord policial aquí (pero sí se puede subir)

    setState(() => _loading = true);

    // 1) crear usuario
    final userId = await _crearUsuario();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error creando usuario")),
      );
      setState(() => _loading = false);
      return;
    }

    // 2) crear datos del empleador
    final ok = await _crearEmpleador(userId);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Empleador registrado correctamente")),
      );

      Navigator.pushReplacementNamed(
        context,
        "/login",
        arguments: {"rol": "empleador"},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error guardando datos del empleador")),
      );
    }

    setState(() => _loading = false);
  }

  // ===============================================================
  // UI COMPLETO
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: size.width > 500 ? 420 : double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "REGISTRO EMPLEADOR",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B21B6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _input("Nombre completo", nombreController, Icons.person),
                  _input("Correo electrónico", emailController, Icons.email,
                      keyboard: TextInputType.emailAddress),
                  _input("Contraseña", passController, Icons.lock,
                      isPassword: true),

                  const SizedBox(height: 20),

                  const Text(
                    "Datos de la empresa",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  _input("Nombre de la empresa", empresaController, Icons.business),
                  _input("RUC", rucController, Icons.confirmation_number),
                  _input("Responsable", responsableController, Icons.person_pin),
                  _input("Teléfono", telefonoController, Icons.phone,
                      keyboard: TextInputType.number),
                  _input("Dirección", direccionController, Icons.location_on),

                  const SizedBox(height: 24),

                  const Text(
                    "Verificación de identidad",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _tomarFoto,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _fotoFile != null ? FileImage(_fotoFile!) : null,
                      child: _fotoFile == null
                          ? const Icon(Icons.camera_alt,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text("Tómate una foto para verificar tu identidad"),

                  const SizedBox(height: 18),

                  // =============================
                  // ✅ RÉCORD POLICIAL (PDF/IMG)
                  // =============================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "RÉCORD POLICIAL (opcional)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recordPolicialFile == null
                              ? "Puedes subir PDF o imagen. Si lo subes aquí, se mostrará luego en tu perfil."
                              : "Seleccionado: ${_recordPolicialFile!.path.split(Platform.pathSeparator).last}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _pickRecordPolicial,
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              _recordPolicialFile == null
                                  ? "Subir récord policial"
                                  : "Cambiar archivo",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Registrar empleador",
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "¿Ya tienes cuenta? Inicia sesión",
                      style: TextStyle(color: Color(0xFF8B5CF6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // INPUT REUTILIZABLE
  Widget _input(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? "Campo requerido" : null,
      ),
    );
  }
}
class TrabajadorModel {
  final int id;
  final String nombre;
  final String email;
  final String categoria;
  final String descripcion;
  final int experiencia;

  TrabajadorModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.categoria,
    required this.descripcion,
    required this.experiencia,
  });

  factory TrabajadorModel.fromJson(Map<String, dynamic> json) {
    final duenio = json['dueño'];

    return TrabajadorModel(
      id: json['id'],
      nombre: duenio?['nombre']?.toString() ?? 'Sin nombre',
      email: duenio?['email'] ?? 'Sin email',
      categoria: (json['categoria'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),

      // 🔥 CLAVE: experiencia viene como STRING
      experiencia: int.tryParse(json['experiencia']?.toString() ?? '0') ?? 0,
    );
  }
}

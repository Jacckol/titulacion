class Trabajo {
  final String titulo;
  final String categoria;
  final String descripcion;
  final String ubicacion;
  final String duracion;
  final double presupuesto;
  final int empleadorId;
  final String? fechaLimite; // YYYY-MM-DD

  Trabajo({
    required this.titulo,
    required this.categoria,
    required this.descripcion,
    required this.ubicacion,
    required this.duracion,
    required this.presupuesto,
    required this.empleadorId,
    this.fechaLimite,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'categoria': categoria,
        'descripcion': descripcion,
        'ubicacion': ubicacion,
        'duracion': duracion,
        'presupuesto': presupuesto,
        'empleadorId': empleadorId,
        'fechaLimite': fechaLimite,
      };
}

import 'package:flutter/material.dart';

class Movimiento {
  final String titulo;
  final String descripcion;
  final double monto;
  final DateTime fecha;

  Movimiento({
    required this.titulo,
    required this.descripcion,
    required this.monto,
    required this.fecha,
  });
}

class BilleteraProvider extends ChangeNotifier {
  double _total = 0;
  final List<Movimiento> _movimientos = [];

  double get total => _total;
  List<Movimiento> get movimientos => _movimientos;

  void agregarMovimiento({
    required String titulo,
    required String descripcion,
    required double monto,
  }) {
    _total += monto;

    _movimientos.insert(
      0,
      Movimiento(
        titulo: titulo,
        descripcion: descripcion,
        monto: monto,
        fecha: DateTime.now(),
      ),
    );

    notifyListeners();
  }
}

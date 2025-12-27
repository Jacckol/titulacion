import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transactions_provider.dart';

class HistorialTransaccionesScreen extends StatefulWidget {
  const HistorialTransaccionesScreen({super.key});

  @override
  State<HistorialTransaccionesScreen> createState() =>
      _HistorialTransaccionesScreenState();
}

class _HistorialTransaccionesScreenState
    extends State<HistorialTransaccionesScreen> with TickerProviderStateMixin {
  String filtroMes = "todos";

  List<String> meses = [
    "todos",
    "enero",
    "febrero",
    "marzo",
    "abril",
    "mayo",
    "junio",
    "julio",
    "agosto",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre"
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final transProv =
        Provider.of<TransactionsProvider>(context, listen: false);

    transProv.cargarTransacciones(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final transProv = Provider.of<TransactionsProvider>(context);
    List trans = transProv.transacciones;

    // FILTRO POR MES
    if (filtroMes != "todos") {
      trans = trans.where((t) {
        final fecha = DateTime.parse(t["createdAt"]);
        final nombreMes = meses[fecha.month].toLowerCase();
        return nombreMes == filtroMes;
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Historial de Transacciones"),
        backgroundColor: Colors.deepPurple,
      ),

      body: transProv.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),

                // FILTRO MES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: DropdownButtonFormField<String>(
                    value: filtroMes,
                    onChanged: (String? v) {
                      setState(() => filtroMes = v!);
                    },
                    items: meses
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: "Filtrar por mes",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // LISTA DE TRANSACCIONES
                Expanded(
                  child: trans.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay transacciones registradas",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: trans.length,
                          itemBuilder: (_, i) {
                            final t = trans[i];
                            final comprobanteUrl = t["comprobanteUrl"];

                            final fecha = DateFormat("yyyy-MM-dd")
                                .format(DateTime.parse(t["createdAt"]));

                            final double monto =
                                (t["monto"] as num).toDouble();

                            return _itemAnimado(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.wallet,
                                      color: Colors.deepPurple,
                                      size: 35,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t["descripcion"] ??
                                                "Transacción",
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Fecha: $fecha",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),

                                          if (comprobanteUrl != null &&
                                              comprobanteUrl
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton(
                                                onPressed: () {
                                                  final full = comprobanteUrl
                                                          .toString()
                                                          .startsWith("http")
                                                      ? comprobanteUrl.toString()
                                                      : "http://10.0.2.2:4000" +
                                                          comprobanteUrl
                                                              .toString();
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text(
                                                          "Comprobante de pago"),
                                                      content: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        child: Image.network(
                                                            full,
                                                            fit: BoxFit
                                                                .contain),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                              "Cerrar"),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                    "Ver comprobante"),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "-\$${monto.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
    );
  }

  /// ANIMACIÓN SUAVE DE APARICIÓN
  Widget _itemAnimado({required Widget child}) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();

    final animation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: controller,
      child: SlideTransition(
        position: animation,
        child: child,
      ),
    );
  }
}

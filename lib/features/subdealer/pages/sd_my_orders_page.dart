import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../orders/order_models.dart';

class SdMyOrdersPage extends StatefulWidget {
  const SdMyOrdersPage({super.key});

  @override
  State<SdMyOrdersPage> createState() => _SdMyOrdersPageState();
}

class _SdMyOrdersPageState extends State<SdMyOrdersPage> {
  bool loading = true;
  String? error;
  List<Order> orders = [];

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      orders = await ordersApi.myOrders();
    } catch (e) {
      error = "Failed to load orders: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PARTIAL':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : orders.isEmpty
                  ? const Center(child: Text("No orders yet"))
                  : RefreshIndicator(
                      onRefresh: load,
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final o = orders[index];
                          final totalReq = o.items.fold<double>(
                              0, (sum, it) => sum + it.requestedQty);
                          final totalAppr = o.items.fold<double>(
                              0, (sum, it) => sum + it.approvedQty);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Order #${o.id}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(o.status)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      o.status,
                                      style: TextStyle(
                                        color: _statusColor(o.status),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  "Items: ${o.items.length}  •  Requested: $totalReq  •  Approved: $totalAppr",
                                ),
                              ),
                              children: [
                                const Divider(height: 1),
                                for (final it in o.items)
                                  ListTile(
                                    title: Text(it.productName),
                                    subtitle: Text("${it.sku} • ${it.unit}"),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text("Req: ${it.requestedQty}"),
                                        Text(
                                          "Appr: ${it.approvedQty}",
                                          style: TextStyle(
                                            color: it.approvedQty > 0
                                                ? Colors.green
                                                : Colors.blueGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if ((o.note ?? "").trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    child: Text("Note: ${o.note}"),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

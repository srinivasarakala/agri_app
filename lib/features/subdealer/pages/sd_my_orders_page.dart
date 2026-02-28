import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../orders/order_models.dart';
import '../../orders/mark_sold_page.dart';

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
        return Colors.green;
    }
  }

  Widget _buildDeliveryStatusChip(String deliveryStatus) {
    Color color;
    IconData icon;
    String label;

    switch (deliveryStatus) {
      case 'PENDING_DELIVERY':
        color = Colors.orange;
        icon = Icons.pending;
        label = 'Pending Delivery';
        break;
      case 'IN_TRANSIT':
        color = Colors.green;
        icon = Icons.local_shipping;
        label = 'In Transit';
        break;
      case 'DELIVERED':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Delivered';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        label = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
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
                    0,
                    (sum, it) => sum + it.requestedQty,
                  );
                  final totalAppr = o.items.fold<double>(
                    0,
                    (sum, it) => sum + it.approvedQty,
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Order #${o.id}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(o.status).withOpacity(0.15),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Items: ${o.items.length}  •  Requested: $totalReq  •  Approved: $totalAppr",
                            ),
                            const SizedBox(height: 6),
                            _buildDeliveryStatusChip(o.deliveryStatus),
                          ],
                        ),
                      ),
                      children: [
                        const Divider(height: 1),
                        for (final it in o.items)
                          ListTile(
                            title: Text(it.productName),
                            subtitle: Text("${it.sku} • ${it.unit}"),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Req: ${it.requestedQty}"),
                                Text(
                                  "Appr: ${it.approvedQty}",
                                  style: TextStyle(
                                    color: it.approvedQty > 0
                                        ? Colors.green
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (o.shippedAt != null || o.deliveredAt != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                if (o.shippedAt != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_shipping,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Shipped: ${o.shippedAt!.toLocal().toString().substring(0, 16)}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                if (o.deliveredAt != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Delivered: ${o.deliveredAt!.toLocal().toString().substring(0, 16)}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        // Mark as Sold button for delivered orders
                        if (o.deliveryStatus == 'DELIVERED')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MarkSoldPage(order: o),
                                    ),
                                  );
                                  // Refresh if items were marked as sold
                                  if (result == true) {
                                    load();
                                  }
                                },
                                icon: const Icon(Icons.sell, size: 18),
                                label: const Text('Mark Items as Sold'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if ((o.note ?? "").trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

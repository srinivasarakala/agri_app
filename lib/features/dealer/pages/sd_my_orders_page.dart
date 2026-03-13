import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../orders/order_models.dart';
import '../../orders/mark_sold_page.dart';

class SdMyOrdersPage extends StatefulWidget {
  final int? initialOrderId;

  const SdMyOrdersPage({super.key, this.initialOrderId});

  @override
  State<SdMyOrdersPage> createState() => _SdMyOrdersPageState();
}

class _SdMyOrdersPageState extends State<SdMyOrdersPage> {
  bool loading = true;
  String? error;
  List<Order> orders = [];
  int? _pendingOrderId;

  Future<void> load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    List<Order>? nextOrders;
    String? nextError;

    try {
      nextOrders = await ordersApi.myOrders();
    } catch (e) {
      nextError = "Failed to load orders: $e";
    }

    if (!mounted) return;

    setState(() {
      if (nextOrders != null) {
        orders = nextOrders!;
      }
      error = nextError;
      loading = false;
    });
    _openOrderFromNotificationIfNeeded();
  }

  void _openOrderFromNotificationIfNeeded() {
    final orderId = _pendingOrderId;
    if (!mounted || orderId == null) return;

    _pendingOrderId = null;
    final match = orders.where((o) => o.id == orderId).toList();

    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order #$orderId not found")),
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showOrderDetailsDialog(match.first);
    });
  }

  Future<void> _showOrderDetailsDialog(Order o) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Order #${o.id}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Status: ${o.status}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildDeliveryStatusChip(o.deliveryStatus),
              const Divider(height: 20),
              ...o.items.map(
                (it) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text("- ${it.productName}: req ${it.requestedQty}, appr ${it.approvedQty}"),
                ),
              ),
              if ((o.note ?? '').trim().isNotEmpty) ...[
                const Divider(height: 20),
                Text("Note: ${o.note}"),
              ],
            ],
          ),
        ),
        actions: [
          if (o.deliveryStatus == 'DELIVERED')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MarkSoldPage(order: o)),
                );
                if (result == true && mounted) {
                  await load();
                }
              },
              child: const Text('Mark as Sold'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pendingOrderId = widget.initialOrderId;
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

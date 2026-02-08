import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../orders/order_models.dart';

final searchCtrl = TextEditingController();
bool pendingOnly = true;

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  bool loading = true;
  String? error;
  List<Order> orders = [];

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      orders = await ordersApi.adminOrders(
        status: pendingOnly ? 'PENDING' : null,
        q: searchCtrl.text,
      );
    } catch (e) {
      error = "Failed to load orders: $e";
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> approveDialog(Order o) async {
    // default approvals = requested qty (admin can edit)
    final controllers = <int, TextEditingController>{};
    for (final it in o.items) {
      controllers[it.id] = TextEditingController(
        text: it.requestedQty.toString(),
      );
    }
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Approve Order #${o.id} (${o.phone})"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final it in o.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${it.productName}\nReq: ${it.requestedQty} ${it.unit}",
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: controllers[it.id],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Approve",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: "Note (optional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // reject shortcut (no stock deduction)
              try {
                await ordersApi.adminReject(o.id);
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Reject failed: $e")));
                }
              }
            },
            child: const Text("Reject"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Approve"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final itemsPayload = o.items.map((it) {
      final v = double.tryParse(controllers[it.id]!.text.trim()) ?? 0;
      return {"item_id": it.id, "approved_qty": v};
    }).toList();

    try {
      await ordersApi.adminApprove(
        o.id,
        itemsPayload,
        note: noteCtrl.text.trim(),
      );
      if (!mounted) return;
      await load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Order updated")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Approve failed: $e")));
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
        color = Colors.blue;
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(Order o) {
    if (o.status == 'PENDING') {
      approveDialog(o);
    } else {
      _showDeliveryDialog(o);
    }
  }

  Future<void> _showDeliveryDialog(Order o) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Order #${o.id} - Delivery Tracking"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status: ${o.status}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDeliveryStatusChip(o.deliveryStatus),
              const Divider(height: 24),
              const Text(
                "Items:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...o.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    "• ${item.productName}: ${item.approvedQty} ${item.unit}",
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              if (o.deliveredAt != null) ...[
                const Divider(height: 24),
                Text(
                  "Delivered: ${o.deliveredAt!.toLocal().toString().substring(0, 16)}",
                ),
              ] else if (o.shippedAt != null) ...[
                const Divider(height: 24),
                Text(
                  "Shipped: ${o.shippedAt!.toLocal().toString().substring(0, 16)}",
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          if (o.status == 'APPROVED' || o.status == 'PARTIAL')
            ...['PENDING_DELIVERY', 'IN_TRANSIT', 'DELIVERED']
                .where((status) => status != o.deliveryStatus)
                .map(
                  (status) => TextButton(
                    onPressed: () => _updateDeliveryStatus(o, status),
                    child: Text(_getDeliveryActionLabel(status)),
                  ),
                ),
        ],
      ),
    );
  }

  String _getDeliveryActionLabel(String status) {
    switch (status) {
      case 'PENDING_DELIVERY':
        return 'Mark Pending';
      case 'IN_TRANSIT':
        return 'Mark Shipped';
      case 'DELIVERED':
        return 'Mark Delivered';
      default:
        return status;
    }
  }

  Future<void> _updateDeliveryStatus(Order o, String newStatus) async {
    Navigator.pop(context); // Close dialog first

    try {
      await ordersApi.adminUpdateDeliveryStatus(o.id, newStatus);
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Delivery status updated to ${_getDeliveryActionLabel(newStatus)}",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: pendingOnly ? 'Showing Pending' : 'Showing All',
            icon: Icon(pendingOnly ? Icons.filter_alt : Icons.filter_alt_off),
            onPressed: () {
              setState(() => pendingOnly = !pendingOnly);
              load();
            },
          ),
          IconButton(
            tooltip: 'Search phone',
            icon: const Icon(Icons.search),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Search by subdealer phone"),
                  content: TextField(
                    controller: searchCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: "eg: 9000"),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Apply"),
                    ),
                  ],
                ),
              );
              if (ok == true) load();
            },
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final o = orders[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text("Order #${o.id} • ${o.status}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("From: ${o.phone} • Items: ${o.items.length}"),
                          const SizedBox(height: 4),
                          _buildDeliveryStatusChip(o.deliveryStatus),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showOrderDetails(o),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

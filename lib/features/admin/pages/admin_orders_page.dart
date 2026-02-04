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
    setState(() { loading = true; error = null; });
    try {
      orders = await ordersApi.adminOrders(
        status: pendingOnly ? 'PENDING' : null,
        q: searchCtrl.text,
      );
    } catch (e) {
      error = "Failed to load orders: $e";
    } finally {
      setState(() { loading = false; });
    }
  }


  Future<void> approveDialog(Order o) async {
    // default approvals = requested qty (admin can edit)
    final controllers = <int, TextEditingController>{};
    for (final it in o.items) {
      controllers[it.id] = TextEditingController(text: it.requestedQty.toString());
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
                      Expanded(child: Text("${it.productName}\nReq: ${it.requestedQty} ${it.unit}", maxLines: 2)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: controllers[it.id],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Approve"),
                        ),
                      )
                    ],
                  ),
                ),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Note (optional)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              // reject shortcut (no stock deduction)
              try {
                await ordersApi.adminReject(o.id);
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reject failed: $e")));
                }
              }
            },
            child: const Text("Reject"),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Approve")),
        ],
      ),
    );

    if (ok != true) return;

    final itemsPayload = o.items.map((it) {
      final v = double.tryParse(controllers[it.id]!.text.trim()) ?? 0;
      return {"item_id": it.id, "approved_qty": v};
    }).toList();

    try {
      await ordersApi.adminApprove(o.id, itemsPayload, note: noteCtrl.text.trim());
      if (!mounted) return;
      await load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order updated")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Approve failed: $e")));
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
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Apply")),
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
                      return ListTile(
                        title: Text("Order #${o.id} • ${o.status}"),
                        subtitle: Text("From: ${o.phone} • Items: ${o.items.length}"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => approveDialog(o),
                      );
                    },
                  ),
                ),
    );
  }
}

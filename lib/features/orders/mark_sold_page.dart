import 'package:flutter/material.dart';
import '../../main.dart';
import 'order_models.dart';

class MarkSoldPage extends StatefulWidget {
  final Order order;

  const MarkSoldPage({super.key, required this.order});

  @override
  State<MarkSoldPage> createState() => _MarkSoldPageState();
}

class _MarkSoldPageState extends State<MarkSoldPage> {
  final Map<int, TextEditingController> _controllers = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current sold quantities
    for (var item in widget.order.items) {
      _controllers[item.id] = TextEditingController(
        text: item.soldQty > 0 ? item.soldQty.toStringAsFixed(2) : '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _markAsSold() async {
    setState(() => _loading = true);

    try {
      final items = <Map<String, dynamic>>[];
      final errors = <String>[];

      for (var item in widget.order.items) {
        final controller = _controllers[item.id]!;
        final soldQty = double.tryParse(controller.text) ?? 0;

        if (soldQty > 0) {
          // Validate sold qty doesn't exceed approved qty
          if (soldQty > item.approvedQty) {
            errors.add(
              '${item.productName}: Cannot mark $soldQty as sold (only ${item.approvedQty.toStringAsFixed(2)} approved)',
            );
          } else {
            items.add({'item_id': item.id, 'sold_qty': soldQty});
          }
        }
      }

      if (errors.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.join('\n')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      if (items.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one sold quantity'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      await ordersApi.markItemsSold(widget.order.id, items);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Items marked as sold successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate refresh needed
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalApprovedValue = widget.order.items.fold<double>(
      0,
      (sum, item) => sum + (item.approvedQty * item.price),
    );

    final currentSoldValue = widget.order.items.fold<double>(0, (sum, item) {
      final controller = _controllers[item.id];
      final soldQty = controller != null
          ? (double.tryParse(controller.text) ?? 0)
          : item.soldQty;
      return sum + (soldQty * item.price);
    });

    // Check if any item exceeds its approved quantity
    final hasInvalidQty = widget.order.items.any((item) {
      final controller = _controllers[item.id];
      final soldQty = controller != null
          ? (double.tryParse(controller.text) ?? 0)
          : 0;
      return soldQty > item.approvedQty;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Items Sold - Order #${widget.order.id}'),
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Order Value',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${totalApprovedValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Sold Value',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${currentSoldValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                final controller = _controllers[item.id]!;
                final soldQty = double.tryParse(controller.text) ?? 0;
                final exceedsLimit = soldQty > item.approvedQty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${item.sku}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Approved Qty',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.approvedQty.toStringAsFixed(2)} ${item.unit}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Quantity Sold to End Customer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  helperText: 'Max: ${item.approvedQty.toStringAsFixed(2)}',
                                  errorText: exceedsLimit ? 'Exceeds approved qty' : null,
                                  suffixText: item.unit,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Value',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '₹${((double.tryParse(controller.text) ?? 0) * item.price).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (item.soldAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Previously marked as sold: ${item.soldQty.toStringAsFixed(2)} ${item.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading || hasInvalidQty ? null : _markAsSold,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Sold Quantities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

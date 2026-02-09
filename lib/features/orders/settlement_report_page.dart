import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';

class SettlementReportPage extends StatefulWidget {
  const SettlementReportPage({super.key});

  @override
  State<SettlementReportPage> createState() => _SettlementReportPageState();
}

class _SettlementReportPageState extends State<SettlementReportPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ordersApi.getSettlementReport();
      setState(() {
        _reportData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement Report'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReport),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading report',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadReport,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _buildReport(),
    );
  }

  Widget _buildReport() {
    final summary = _reportData!['summary'] as Map<String, dynamic>;
    final settlements = _reportData!['settlements'] as List<dynamic>;

    if (settlements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No settlement data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary Card
        Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Orders',
                      summary['total_orders'].toString(),
                      Icons.shopping_bag,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Order Value',
                      '₹${(summary['total_order_value'] as num).toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Sold Value',
                      '₹${(summary['total_sold_value'] as num).toStringAsFixed(2)}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Pending',
                      '₹${(summary['total_pending'] as num).toStringAsFixed(2)}',
                      Icons.pending,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Settlements List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: settlements.length,
            itemBuilder: (context, index) {
              final settlement = settlements[index] as Map<String, dynamic>;
              return _buildSettlementCard(settlement);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> settlement) {
    final orderId = settlement['order_id'];
    final subdealerName = settlement['subdealer_name'];
    final subdealerPhone = settlement['subdealer_phone'];
    final orderTotal = (settlement['order_total'] as num).toDouble();
    final soldTotal = (settlement['sold_total'] as num).toDouble();
    final pendingAmount = (settlement['pending_amount'] as num).toDouble();
    final percentage = (settlement['settlement_percentage'] as num).toDouble();
    final deliveredAtStr = settlement['delivered_at'];
    final items = settlement['items'] as List<dynamic>;

    final deliveredAt = deliveredAtStr != null
        ? DateTime.tryParse(deliveredAtStr)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Order #$orderId - $subdealerName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Phone: $subdealerPhone'),
            if (deliveredAt != null)
              Text(
                'Delivered: ${DateFormat('MMM dd, yyyy').format(deliveredAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 100 ? Colors.green : Colors.orange,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: percentage >= 100 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Financial Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFinanceItem('Order Total', orderTotal, Colors.blue),
                    _buildFinanceItem('Sold', soldTotal, Colors.green),
                    _buildFinanceItem('Pending', pendingAmount, Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Items List
                const Text(
                  'Items:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final itemData = item as Map<String, dynamic>;
                  final productName = itemData['product_name'];
                  final sku = itemData['sku'];
                  final approvedQty = (itemData['approved_qty'] as num)
                      .toDouble();
                  final soldQty = (itemData['sold_qty'] as num).toDouble();
                  final soldValue = (itemData['sold_value'] as num).toDouble();
                  final soldAtStr = itemData['sold_at'];

                  final soldAt = soldAtStr != null
                      ? DateTime.tryParse(soldAtStr)
                      : null;

                  return Card(
                    color: Colors.grey.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: $sku',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Approved: ${approvedQty.toInt()}'),
                              Text(
                                'Sold: ${soldQty.toInt()}',
                                style: TextStyle(
                                  color: soldQty >= approvedQty
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₹${soldValue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (soldAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Sold on: ${DateFormat('MMM dd, yyyy hh:mm a').format(soldAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

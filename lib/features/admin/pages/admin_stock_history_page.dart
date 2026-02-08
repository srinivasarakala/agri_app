import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../stock/stock_history_models.dart';
import '../../../main.dart';

class AdminStockHistoryPage extends StatefulWidget {
  const AdminStockHistoryPage({super.key});

  @override
  State<AdminStockHistoryPage> createState() => _AdminStockHistoryPageState();
}

class _AdminStockHistoryPageState extends State<AdminStockHistoryPage> {
  List<StockHistoryEntry> _history = [];
  bool _loading = true;
  String? _error;

  String? _filterChangeType;
  final List<String> _changeTypes = [
    'MANUAL_ADJUSTMENT',
    'ORDER_APPROVED',
    'ORDER_CANCELLED',
    'INITIAL_STOCK',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final history = await stockHistoryApi.getStockHistory(
        changeType: _filterChangeType,
      );
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              leading: Radio<String?>(
                value: null,
                groupValue: _filterChangeType,
                onChanged: (value) {
                  setState(() => _filterChangeType = value);
                  Navigator.pop(context);
                  _loadHistory();
                },
              ),
            ),
            ..._changeTypes.map((type) {
              final displayName = StockHistoryEntry(
                id: 0,
                productId: 0,
                productSku: '',
                productName: '',
                productUnit: '',
                changeType: type,
                quantityChange: 0,
                stockBefore: 0,
                stockAfter: 0,
                createdAt: DateTime.now(),
              ).changeTypeDisplay;

              return ListTile(
                title: Text(displayName),
                leading: Radio<String?>(
                  value: type,
                  groupValue: _filterChangeType,
                  onChanged: (value) {
                    setState(() => _filterChangeType = value);
                    Navigator.pop(context);
                    _loadHistory();
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadHistory,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _history.isEmpty
          ? const Center(child: Text('No stock history found'))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final entry = _history[index];
                  return _StockHistoryCard(entry: entry);
                },
              ),
            ),
    );
  }
}

class _StockHistoryCard extends StatelessWidget {
  final StockHistoryEntry entry;

  const _StockHistoryCard({required this.entry});

  IconData get _icon {
    switch (entry.changeType) {
      case 'MANUAL_ADJUSTMENT':
        return Icons.edit;
      case 'ORDER_APPROVED':
        return Icons.shopping_cart;
      case 'ORDER_CANCELLED':
        return Icons.cancel;
      case 'INITIAL_STOCK':
        return Icons.inventory_2;
      default:
        return Icons.history;
    }
  }

  Color get _iconColor {
    if (entry.isIncrease) return Colors.green;
    if (entry.isDecrease) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: _iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'SKU: ${entry.productSku}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${entry.quantityChange > 0 ? '+' : ''}${entry.quantityChange} ${entry.productUnit}',
                  style: TextStyle(
                    color: _iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    entry.changeTypeDisplay,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _iconColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: _iconColor),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Spacer(),
                Text(
                  '${entry.stockBefore} → ${entry.stockAfter}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(entry.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (entry.createdByName != null)
                  Text(
                    'By: ${entry.createdByName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            if (entry.orderId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Order #${entry.orderId}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (entry.notes != null && entry.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Note: ${entry.notes}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

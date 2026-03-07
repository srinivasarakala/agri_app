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
  List<StockHistoryEntry> _allHistory = [];
  List<StockHistoryEntry> _filteredHistory = [];
  bool _loading = true;
  String? _error;

  String? _filterChangeType;
  final TextEditingController _searchController = TextEditingController();
  
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
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final history = await stockHistoryApi.getStockHistory();
      setState(() {
        _allHistory = history;
        _filterHistory();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filterHistory() {
    setState(() {
      _filteredHistory = _allHistory.where((entry) {
        // Filter by change type
        if (_filterChangeType != null && entry.changeType != _filterChangeType) {
          return false;
        }
        
        // Filter by search text
        final searchText = _searchController.text.toLowerCase();
        if (searchText.isNotEmpty) {
          return entry.productName.toLowerCase().contains(searchText) ||
                 entry.productSku.toLowerCase().contains(searchText);
        }
        
        return true;
      }).toList();
    });
  }

  void _setFilter(String? type) {
    setState(() => _filterChangeType = type);
    _filterHistory();
  }

  void _clearFilters() {
    setState(() {
      _filterChangeType = null;
      _searchController.clear();
    });
    _filterHistory();
  }

  Map<String, dynamic> _getStatistics() {
    double totalIncrease = 0;
    double totalDecrease = 0;
    int increases = 0;
    int decreases = 0;

    for (var entry in _filteredHistory) {
      if (entry.isIncrease) {
        totalIncrease += entry.quantityChange;
        increases++;
      } else if (entry.isDecrease) {
        totalDecrease += entry.quantityChange.abs();
        decreases++;
      }
    }

    return {
      'totalIncrease': totalIncrease,
      'totalDecrease': totalDecrease,
      'increases': increases,
      'decreases': decreases,
      'total': _filteredHistory.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStatistics();
    final hasActiveFilters = _filterChangeType != null || _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Stock History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Search Bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by product name or SKU...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),

                    // Filter Chips
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _filterChangeType == null,
                              onSelected: (_) => _setFilter(null),
                            ),
                            const SizedBox(width: 8),
                            ..._changeTypes.map((type) {
                              final displayName = _getDisplayName(type);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(displayName),
                                  selected: _filterChangeType == type,
                                  onSelected: (_) => _setFilter(type),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                    // Statistics Summary
                    if (_allHistory.isNotEmpty)
                      Container(
                        color: Colors.white,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Total',
                                value: '${stats['total']}',
                                icon: Icons.inventory_2,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Added',
                                value: '${stats['increases']}',
                                icon: Icons.add_circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Removed',
                                value: '${stats['decreases']}',
                                icon: Icons.remove_circle,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // History List
                    Expanded(
                      child: _filteredHistory.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadHistory,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 8, bottom: 16),
                                itemCount: _filteredHistory.length,
                                itemBuilder: (context, index) {
                                  final entry = _filteredHistory[index];
                                  return _StockHistoryCard(entry: entry);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _filterChangeType != null || _searchController.text.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching records' : 'No stock history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters'
                  : 'Stock movements will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDisplayName(String type) {
    switch (type) {
      case 'MANUAL_ADJUSTMENT':
        return 'Manual';
      case 'ORDER_APPROVED':
        return 'Order Approved';
      case 'ORDER_CANCELLED':
        return 'Order Cancelled';
      case 'INITIAL_STOCK':
        return 'Initial Stock';
      default:
        return type;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
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

  Color get _backgroundColor {
    if (entry.isIncrease) return Colors.green.withOpacity(0.05);
    if (entry.isDecrease) return Colors.red.withOpacity(0.05);
    return Colors.grey.withOpacity(0.05);
  }

  String _formatStock(double value) {
    return value.truncateToDouble() == value 
        ? value.toInt().toString() 
        : value.toStringAsFixed(2);
  }

  String _formatQuantity(double value) {
    return value.truncateToDouble() == value 
        ? value.toInt().toString() 
        : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    final fullDateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _iconColor.withOpacity(0.2), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _backgroundColor,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with icon and quantity
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icon, color: _iconColor, size: 22),
                  ),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${entry.productSku}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.quantityChange > 0 ? '+' : ''}${_formatQuantity(entry.quantityChange)} ${entry.productUnit}',
                      style: TextStyle(
                        color: _iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Type and Stock Change Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _iconColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      entry.changeTypeDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatStock(entry.stockBefore)} → ${_formatStock(entry.stockAfter)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              
              // Footer with time and user
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(entry.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (entry.createdByName != null)
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          entry.createdByName!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Order ID if present
              if (entry.orderId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Order #${entry.orderId}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Notes if present
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.notes!,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}

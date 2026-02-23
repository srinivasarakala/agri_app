import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../finance/ledger_models.dart';

class AdminLedgerPage extends StatefulWidget {
  const AdminLedgerPage({super.key});

  @override
  State<AdminLedgerPage> createState() => _AdminLedgerPageState();
}

class _AdminLedgerPageState extends State<AdminLedgerPage> {
  List<UserBalance> _balances = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final balances = await ledgerApi.getAllBalances();
      setState(() {
        _balances = balances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ledger - All Subdealers'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBalances),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBalances,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_balances.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No subdealers found'),
          ],
        ),
      );
    }

    // Calculate overall statistics
    final totalDebt = _balances.fold<double>(0, (sum, b) => sum + (b.balance > 0 ? b.balance : 0));
    final totalDelivered = _balances.fold<double>(0, (sum, b) => sum + b.totalDeliveredValue);
    final totalSold = _balances.fold<double>(0, (sum, b) => sum + b.totalSoldValue);
    final totalPending = _balances.fold<double>(0, (sum, b) => sum + b.pendingItemsValue);

    return Column(
      children: [
        // Summary Section
        Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Outstanding',
                      '₹${totalDebt.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Items Delivered',
                      '₹${totalDelivered.toStringAsFixed(2)}',
                      Icons.local_shipping,
                      Colors.orange.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Items Sold',
                      '₹${totalSold.toStringAsFixed(2)}',
                      Icons.shopping_cart,
                      Colors.green.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Pending Sale',
                      '₹${totalPending.toStringAsFixed(2)}',
                      Icons.pending_actions,
                      Colors.blue.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Balances List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBalances,
            child: ListView.builder(
              itemCount: _balances.length,
              itemBuilder: (context, index) {
                final balance = _balances[index];
                return _buildBalanceCard(balance);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(UserBalance balance) {
    final hasDebt = balance.balance > 0;
    final balanceColor = hasDebt ? Colors.red : Colors.green;
    final soldPercentage = balance.totalDeliveredValue > 0 
        ? (balance.totalSoldValue / balance.totalDeliveredValue * 100) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToUserLedger(balance),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: hasDebt
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      hasDebt ? Icons.account_balance_wallet : Icons.check_circle,
                      color: balanceColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          balance.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${balance.balance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                      Text(
                        hasDebt ? 'Owed' : 'Settled',
                        style: TextStyle(fontSize: 12, color: balanceColor),
                      ),
                    ],
                  ),
                ],
              ),
              if (balance.totalDeliveredValue > 0) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Delivered',
                        '₹${balance.totalDeliveredValue.toStringAsFixed(0)}',
                        Icons.local_shipping,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Sold',
                        '₹${balance.totalSoldValue.toStringAsFixed(0)}',
                        Icons.shopping_cart,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildMiniStat(
                        'Pending',
                        '₹${balance.pendingItemsValue.toStringAsFixed(0)}',
                        Icons.pending,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar showing sold percentage
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: soldPercentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            soldPercentage > 80 ? Colors.green : 
                            soldPercentage > 50 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${soldPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
              if (balance.lastTransactionDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Last activity: ${_formatDate(balance.lastTransactionDate!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToUserLedger(UserBalance balance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserLedgerDetailPage(
          userId: balance.userId,
          userName: balance.fullName,
          phone: balance.phone,
        ),
      ),
    ).then((_) => _loadBalances()); // Refresh when coming back
  }
}

class UserLedgerDetailPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String phone;

  const UserLedgerDetailPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phone,
  });

  @override
  State<UserLedgerDetailPage> createState() => _UserLedgerDetailPageState();
}

class _UserLedgerDetailPageState extends State<UserLedgerDetailPage> {
  List<LedgerTransaction> _transactions = [];
  UserBalance? _balance;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ledgerApi.getLedgerTransactions(userId: widget.userId),
        ledgerApi.getUserBalance(userId: widget.userId),
      ]);

      setState(() {
        _transactions = results[0] as List<LedgerTransaction>;
        _balance = results[1] as UserBalance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName),
            Text(widget.phone, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _balance != null && _balance!.balance > 0
          ? FloatingActionButton.extended(
              onPressed: _showRecordPaymentDialog,
              icon: const Icon(Icons.payment),
              label: const Text('Record Payment'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildBalanceSummary(),
        const Divider(height: 1),
        Expanded(
          child: _transactions.isEmpty
              ? const Center(child: Text('No transactions yet'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionTile(_transactions[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBalanceSummary() {
    if (_balance == null) return const SizedBox.shrink();

    final hasDebt = _balance!.balance > 0;
    final balanceColor = hasDebt ? Colors.red : Colors.green;
    final soldPercentage = _balance!.totalDeliveredValue > 0 
        ? (_balance!.totalSoldValue / _balance!.totalDeliveredValue * 100) 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            balanceColor.withOpacity(0.1),
            balanceColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Balance:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${_balance!.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
            ],
          ),
          if (_balance!.totalDeliveredValue > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Settlement Overview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailStat(
                    'Delivered Value',
                    '₹${_balance!.totalDeliveredValue.toStringAsFixed(2)}',
                    Icons.local_shipping,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailStat(
                    'Sold Value',
                    '₹${_balance!.totalSoldValue.toStringAsFixed(2)}',
                    Icons.shopping_cart,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailStat(
                    'Pending Items',
                    '₹${_balance!.pendingItemsValue.toStringAsFixed(2)}',
                    Icons.pending,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: soldPercentage / 100,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        soldPercentage > 80 ? Colors.green : 
                        soldPercentage > 50 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${soldPercentage.toStringAsFixed(1)}% sold',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(LedgerTransaction txn) {
    final isDebit = txn.isDebit;
    final iconData = txn.transactionType == 'ORDER_DELIVERED'
        ? Icons.shopping_bag
        : txn.transactionType == 'PAYMENT_RECEIVED'
        ? Icons.payment
        : Icons.edit;
    final iconColor = isDebit ? Colors.red : Colors.green;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(iconData, color: iconColor),
      ),
      title: Text(txn.transactionTypeDisplay),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (txn.description.isNotEmpty) Text(txn.description),
          if (txn.referenceNumber.isNotEmpty)
            Text(
              'Ref: ${txn.referenceNumber}',
              style: const TextStyle(fontSize: 12),
            ),
          Text(
            _formatDateTime(txn.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isDebit ? '+' : ''}₹${txn.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          Text(
            'Bal: ₹${txn.balance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showRecordPaymentDialog() {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number (optional)',
                  hintText: 'Cheque/UPI/Transaction ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Payment notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _recordPayment(
                amountController.text.trim(),
                referenceController.text.trim(),
                descriptionController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordPayment(
    String amountStr,
    String reference,
    String description,
  ) async {
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    try {
      await ledgerApi.recordPayment(
        RecordPaymentRequest(
          userId: widget.userId,
          amount: amount,
          referenceNumber: reference,
          description: description.isEmpty ? 'Payment received' : description,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to record payment: $e')));
      }
    }
  }
}

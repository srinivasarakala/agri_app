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
      appBar: AppBar(
        title: const Text('Ledger - All Subdealers'),
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

    return RefreshIndicator(
      onRefresh: _loadBalances,
      child: ListView.builder(
        itemCount: _balances.length,
        itemBuilder: (context, index) {
          final balance = _balances[index];
          return _buildBalanceCard(balance);
        },
      ),
    );
  }

  Widget _buildBalanceCard(UserBalance balance) {
    final hasDebt = balance.balance > 0;
    final balanceColor = hasDebt ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasDebt
              ? Colors.red.shade100
              : Colors.green.shade100,
          child: Icon(
            hasDebt ? Icons.account_balance_wallet : Icons.check_circle,
            color: balanceColor,
          ),
        ),
        title: Text(
          balance.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(balance.phone),
            if (balance.lastTransactionDate != null)
              Text(
                'Last activity: ${_formatDate(balance.lastTransactionDate!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
        onTap: () => _navigateToUserLedger(balance),
      ),
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName),
            Text(widget.phone, style: const TextStyle(fontSize: 12)),
          ],
        ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      color: balanceColor.withOpacity(0.1),
      child: Row(
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

import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../finance/ledger_models.dart';

class SdLedgerPage extends StatefulWidget {
  const SdLedgerPage({super.key});

  @override
  State<SdLedgerPage> createState() => _SdLedgerPageState();
}

class _SdLedgerPageState extends State<SdLedgerPage> {
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
        ledgerApi.getLedgerTransactions(),
        ledgerApi.getUserBalance(),
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
        title: const Text('My Ledger'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No transactions yet'),
                    ],
                  ),
                )
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasDebt
              ? [Colors.red.shade50, Colors.red.shade100]
              : [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Outstanding Balance',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Icon(
                hasDebt ? Icons.warning_amber : Icons.check_circle,
                color: balanceColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_balance!.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: balanceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasDebt ? 'Amount Owed' : 'Settled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_balance!.lastTransactionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last activity: ${_formatDateTime(_balance!.lastTransactionDate!)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          txn.transactionTypeDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (txn.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(txn.description),
              ),
            if (txn.referenceNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Ref: ${txn.referenceNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(txn.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Balance: ₹${txn.balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

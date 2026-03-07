import 'package:flutter/material.dart';
import '../../../main.dart' show dealerWhitelistApi;
import '../dealer_whitelist_service.dart';

class AdminDealersPage extends StatefulWidget {
  const AdminDealersPage({super.key});

  @override
  State<AdminDealersPage> createState() => _AdminDealersPageState();
}

class _AdminDealersPageState extends State<AdminDealersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  List<WhitelistEntry> _whitelist = [];
  List<DealerUser> _dealers = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _searchCtrl.text.trim();
      final results = await Future.wait([
        dealerWhitelistApi.listWhitelist(q: q),
        dealerWhitelistApi.listDealers(q: q),
      ]);
      _whitelist = results[0] as List<WhitelistEntry>;
      _dealers = results[1] as List<DealerUser>;
    } catch (e) {
      _error = 'Failed to load: $e';
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Snackbar helpers ────────────────────────────────────────────────────────

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : null,
    ));
  }

  // ── Add dealer dialog ───────────────────────────────────────────────────────

  Future<void> _showAddDialog() async {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Dealer to Whitelist'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  hintText: '+91XXXXXXXXXX',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name (optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await dealerWhitelistApi.addToWhitelist(
        phoneCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
      );
      _snack('Dealer added to whitelist.');
      await _load();
    } catch (e) {
      _snack('Failed to add: $e', isError: true);
    }
  }

  // ── Toggle block/unblock ────────────────────────────────────────────────────

  Future<void> _toggle(WhitelistEntry entry) async {
    final action = entry.isActive ? 'block' : 'unblock';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${entry.isActive ? 'Block' : 'Unblock'} Dealer?'),
        content: Text(
          '${entry.isActive ? 'Block' : 'Unblock'} ${entry.phone}${entry.name.isNotEmpty ? ' (${entry.name})' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: entry.isActive ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(entry.isActive ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await dealerWhitelistApi.toggleWhitelist(entry.id, isActive: !entry.isActive);
      _snack('Dealer ${action}ed.');
      await _load();
    } catch (e) {
      _snack('Failed to $action: $e', isError: true);
    }
  }

  // ── Remove from whitelist ───────────────────────────────────────────────────

  Future<void> _remove(WhitelistEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from Whitelist'),
        content: Text(
          'Remove ${entry.phone}${entry.name.isNotEmpty ? ' (${entry.name})' : ''} from the whitelist?\n\nThey will no longer be able to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await dealerWhitelistApi.removeFromWhitelist(entry.id);
      _snack('Dealer removed from whitelist.');
      await _load();
    } catch (e) {
      _snack('Failed to remove: $e', isError: true);
    }
  }

  // ── Add unregistered dealer to whitelist ───────────────────────────────────

  Future<void> _addDealerToWhitelist(DealerUser dealer) async {
    try {
      await dealerWhitelistApi.addToWhitelist(
        dealer.phone,
        name: dealer.name ?? '',
      );
      _snack('${dealer.phone} added to whitelist.');
      await _load();
    } catch (e) {
      _snack('Failed: $e', isError: true);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar + Add button row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search phone or name…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _load();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        // Tab bar
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, size: 16),
                  const SizedBox(width: 6),
                  Text('Whitelist (${_whitelist.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 6),
                  Text('All Dealers (${_dealers.length})'),
                ],
              ),
            ),
          ],
        ),
        // Tab content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _buildWhitelistTab(),
                        _buildDealersTab(),
                      ],
                    ),
        ),
      ],
    );
  }

  // ── Whitelist Tab ───────────────────────────────────────────────────────────

  Widget _buildWhitelistTab() {
    if (_whitelist.isEmpty) {
      return const Center(
        child: Text(
          'No whitelist entries yet.\nTap + to add a dealer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _whitelist.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = _whitelist[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: e.isActive ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(
                e.isActive ? Icons.check_circle : Icons.block,
                color: e.isActive ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(e.phone, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (e.name.isNotEmpty) Text(e.name),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: e.isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: e.isActive ? Colors.green.shade300 : Colors.red.shade300,
                        ),
                      ),
                      child: Text(
                        e.isActive ? 'Active' : 'Blocked',
                        style: TextStyle(
                          fontSize: 11,
                          color: e.isActive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                    if (e.createdAt != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(e.createdAt!),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'toggle') _toggle(e);
                if (v == 'remove') _remove(e);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        e.isActive ? Icons.block : Icons.check_circle,
                        color: e.isActive ? Colors.red : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(e.isActive ? 'Block' : 'Unblock'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── All Dealers Tab ─────────────────────────────────────────────────────────

  Widget _buildDealersTab() {
    if (_dealers.isEmpty) {
      return const Center(
        child: Text(
          'No registered dealers found.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _dealers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final d = _dealers[i];
          final statusColor = d.isWhitelisted
              ? (d.isActive ? Colors.green : Colors.red)
              : Colors.grey;
          final statusLabel = d.isWhitelisted
              ? (d.isActive ? 'Allowed' : 'Blocked')
              : 'Not whitelisted';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.15),
              child: Text(
                (d.name?.isNotEmpty == true ? d.name![0] : d.phone[0]).toUpperCase(),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              d.phone,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.name?.isNotEmpty == true) Text(d.name!),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 11, color: statusColor),
                      ),
                    ),
                    if (d.lastLogin != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Last: ${_formatDate(d.lastLogin!)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            isThreeLine: d.name?.isNotEmpty == true,
            trailing: d.isWhitelisted
                ? null
                : IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    tooltip: 'Add to whitelist',
                    onPressed: () => _addDealerToWhitelist(d),
                  ),
          );
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

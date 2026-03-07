import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/cart/cart_state.dart';
import '../admin/pages/admin_products_page.dart';
import '../admin/pages/admin_spare_parts_page.dart';
import '../admin/pages/admin_brands_page.dart';
import '../admin/pages/admin_product_videos_page.dart';
import '../admin/pages/admin_categories_page.dart';
import '../admin/pages/admin_brands_page.dart';
import '../admin/pages/admin_orders_page.dart';
import '../admin/pages/admin_stock_history_page.dart';
import '../admin/pages/admin_ledger_page.dart';
import '../admin/pages/admin_top_products_page.dart';
import '../admin/pages/admin_dealers_page.dart';
import '../orders/settlement_report_page.dart';
import '../dealer/pages/sd_my_orders_page.dart';
import '../dealer/pages/sd_ledger_page.dart';
import '../profile/profile_page.dart';
import '../../main.dart';

Widget _collapsibleGroup({
  required String title,
  required IconData icon,
  required List<Widget> children,
  bool initiallyExpanded = false,
}) =>
    Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(icon),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          initiallyExpanded: initiallyExpanded,
          childrenPadding: EdgeInsets.zero,
          children: children,
        ),
      ),
    );

class MenuPage extends StatelessWidget {
  final String role;
  const MenuPage({super.key, required this.role});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Do you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // Clear user session (clears in-memory cart/favorites without saving)
    clearUserSession();
    await appAuth.logout(); // Clear token storage
    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == "Admin";

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          color: Colors.white,
          child: const Text(
            "Menu",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        // ── Account info ───────────────────────────────────────────────────
        _collapsibleGroup(
          title: "Account",
          icon: Icons.person,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(currentSession?.phone ?? "No phone"),
              subtitle: Text(role),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text("My Profile"),
              subtitle: const Text("Update your personal information"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
            ),
          ],
        ),

        if (isAdmin) ...[
          // ── Catalog ──────────────────────────────────────────────────────
          _collapsibleGroup(
            title: "Catalog",
            icon: Icons.inventory_2,
            children: [
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text("Manage Brands"),
                subtitle: const Text("Add, edit, or delete brands and images"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBrandsPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text("Manage Products"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProductsPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text("Manage Spare Parts"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSparePartsPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text("Product Videos"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminProductVideosPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text("Categories"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminCategoriesPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text("Top Products"),
                subtitle: const Text("Manage home page featured products"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminTopProductsPage()),
                ),
              ),
            ],
          ),

          // ── Orders ───────────────────────────────────────────────────────
          _collapsibleGroup(
            title: "Orders",
            icon: Icons.list_alt,
            children: [
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text("Approve Orders"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
                ),
              ),
            ],
          ),

          // ── Finance ──────────────────────────────────────────────────────
          _collapsibleGroup(
            title: "Finance",
            icon: Icons.account_balance_wallet,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("Ledger & Settlements"),
                subtitle: const Text("Track balances, payments & sales"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLedgerPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text("Settlement Report"),
                subtitle: const Text("Track sold items for money settlement"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettlementReportPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Stock History"),
                subtitle: const Text("View stock movement audit trail"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminStockHistoryPage()),
                ),
              ),
            ],
          ),

          // ── Users ────────────────────────────────────────────────────────
          _collapsibleGroup(
            title: "Users",
            icon: Icons.manage_accounts,
            children: [
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text("Manage Dealers"),
                subtitle:
                    const Text("Whitelist, block or remove dealer access"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.white,
                      appBar: AppBar(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        title: const Text("Manage Dealers"),
                      ),
                      body: const AdminDealersPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // ── Sub-dealer: Orders ────────────────────────────────────────────
          _collapsibleGroup(
            title: "Orders",
            icon: Icons.list_alt,
            children: [
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text("My Orders"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SdMyOrdersPage()),
                ),
              ),
            ],
          ),

          // ── Sub-dealer: Finance ───────────────────────────────────────────
          _collapsibleGroup(
            title: "Finance",
            icon: Icons.account_balance_wallet,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("Ledger"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SdLedgerPage()),
                ),
              ),
            ],
          ),
        ],

        // ── Danger zone ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout",
                  style: TextStyle(color: Colors.red)),
              onTap: () => _logout(context),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

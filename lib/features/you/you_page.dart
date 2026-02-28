import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/cart/cart_state.dart';
import '../admin/pages/admin_products_page.dart';
import '../admin/pages/admin_product_videos_page.dart';
import '../admin/pages/admin_categories_page.dart';
import '../admin/pages/admin_brands_page.dart';
import '../admin/pages/admin_orders_page.dart';
import '../admin/pages/admin_stock_history_page.dart';
import '../admin/pages/admin_ledger_page.dart';
import '../admin/pages/admin_top_products_page.dart';
import '../orders/settlement_report_page.dart';
import '../subdealer/pages/sd_my_orders_page.dart';
import '../subdealer/pages/sd_ledger_page.dart';
import '../profile/profile_page.dart';
import '../../main.dart';
import '../shell/app_shell.dart';

class YouPage extends StatelessWidget {
  final String role;
  const YouPage({super.key, required this.role});

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
    final isAdmin = role == "DEALER_ADMIN";

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

        const SizedBox(height: 10),

        // ...existing code...

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(currentSession?.phone ?? "No phone"),
                  subtitle: Text(role),
                ),
                const Divider(height: 1),

                // User Profile
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
                const Divider(height: 1),

                if (isAdmin) ...[
                                    ListTile(
                                      leading: const Icon(Icons.store),
                                      title: const Text("Manage Brands"),
                                      subtitle: const Text("Add, edit, or delete brands and images"),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AdminBrandsPage(),
                                        ),
                                      ),
                                    ),
                  ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: const Text("Manage Products"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminProductsPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library),
                    title: const Text("Product Videos"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminProductVideosPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text("Categories"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminCategoriesPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text("Top Products"),
                    subtitle: const Text("Manage home page featured products"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminTopProductsPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt),
                    title: const Text("Approve Orders"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminOrdersPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text("Stock History"),
                    subtitle: const Text("View stock movement audit trail"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminStockHistoryPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text("Ledger & Settlements"),
                    subtitle: const Text("Track balances, payments & sales"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminLedgerPage(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.assessment),
                    title: const Text("Settlement Report"),
                    subtitle: const Text(
                      "Track sold items for money settlement",
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettlementReportPage(),
                      ),
                    ),
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.list_alt),
                    title: const Text("My Orders"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SdMyOrdersPage()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text("Ledger"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SdLedgerPage()),
                    ),
                  ),
                ],

                const Divider(height: 1),

                // ✅ Logout button
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

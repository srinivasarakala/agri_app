import 'package:flutter/material.dart';
import '../../core/widgets/top_banner.dart';
import '../../core/widgets/logout_button.dart';
import '../admin/pages/admin_products_page.dart';
import '../admin/pages/admin_product_videos_page.dart';
import '../admin/pages/admin_categories_page.dart';
import '../admin/pages/admin_orders_page.dart';
import '../admin/pages/admin_stock_history_page.dart';
import '../admin/pages/admin_ledger_page.dart';
import '../subdealer/pages/sd_my_orders_page.dart';
import '../subdealer/pages/sd_ledger_page.dart';
import '../profile/profile_page.dart';
import '../../main.dart';

class YouPage extends StatelessWidget {
  final String role;
  const YouPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == "DEALER_ADMIN";

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        TopBanner(subtitle: "You"),

        const SizedBox(height: 10),

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
                    subtitle: const Text("Track balances and payments"),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminLedgerPage(),
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

                // ✅ Logout inside You
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: LogoutButton(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

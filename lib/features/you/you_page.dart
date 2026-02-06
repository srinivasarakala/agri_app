import 'package:flutter/material.dart';
import '../../core/widgets/top_banner.dart';
import '../../core/widgets/logout_button.dart';
import '../admin/pages/admin_products_page.dart';
import '../admin/pages/admin_orders_page.dart';
import '../admin/pages/admin_stock_page.dart';
import '../subdealer/pages/sd_my_orders_page.dart';
import '../subdealer/pages/sd_stock_page.dart';
import '../subdealer/pages/sd_ledger_page.dart';

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
                  title: Text(isAdmin ? "Admin" : "Subdealer"),
                  subtitle: Text(role),
                ),
                const Divider(height: 1),

                if (isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: const Text("Manage Products"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsPage())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt),
                    title: const Text("Approve Orders"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersPage())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.warehouse),
                    title: const Text("Stock Management"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStockPage())),
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.list_alt),
                    title: const Text("My Orders"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SdMyOrdersPage())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory),
                    title: const Text("My Stock"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SdStockPage())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text("Ledger"),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SdLedgerPage())),
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
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

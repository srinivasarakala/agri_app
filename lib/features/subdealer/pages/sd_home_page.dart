import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';
import '../../catalog/widgets/product_card.dart';
import '../subdealer_shell.dart';


class SdHomePage extends StatefulWidget {
  const SdHomePage({super.key});

  @override
  State<SdHomePage> createState() => _SdHomePageState();
}

class _SdHomePageState extends State<SdHomePage> {
  final searchCtrl = TextEditingController();
  bool loading = true;
  String? error;

  List<Product> featured = [];
  List<Product> all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      all = await catalogApi.listProducts();
      featured = all.take(8).toList();
    } catch (e) {
      error = "Failed to load products";
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _openCatalogWithSearch(String q) {
    subdealerTabIndex.value = 1; // ✅ switch to Catalog tab
    catalogSearchBus.openCatalogWithSearch(q);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          children: [
            _BrandHeader(
              title: "HI-TECH Agro",
              subtitle: "B2B Inventory • Ordering • Tracking",
              onBell: () {},
            ),

            const SizedBox(height: 12),

            // ✅ Search Bar (readOnly; opens catalog instantly)
            GestureDetector(
              onTap: () => _openCatalogWithSearch(""),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 22, color: Colors.grey),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Text(
                        "Search products…",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // optional mic icon (Amazon style)
                    Icon(
                      Icons.mic_none,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 12),

            // ✅ Quick actions row (optional)
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.shopping_cart_checkout,
                    title: "Catalog",
                    subtitle: "Browse items",
                    onTap: () => _openCatalogWithSearch(""),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.receipt_long,
                    title: "My Orders",
                    subtitle: "Track status",
                    onTap: () {
                      subdealerTabIndex.value = 2; // ✅ My Orders tab
                    },

                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ✅ Categories chips (static now; later connect to backend)
            const Text("Categories", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CategoryChip(label: "Seeds", onTap: () => _openCatalogWithSearch("seed")),
                _CategoryChip(label: "Fertilizers", onTap: () => _openCatalogWithSearch("fert")),
                _CategoryChip(label: "Pesticides", onTap: () => _openCatalogWithSearch("pest")),
                _CategoryChip(label: "Sprayers", onTap: () => _openCatalogWithSearch("spray")),
                _CategoryChip(label: "Tools", onTap: () => _openCatalogWithSearch("tool")),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ Featured products
            Row(
              children: [
                const Text("Featured Products",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const Spacer(),
                TextButton(
                  onPressed: () => _openCatalogWithSearch(""),
                  child: const Text("See all"),
                )
              ],
            ),
            const SizedBox(height: 8),

            if (loading)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: featured.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (_, i) {
                  final p = featured[i];
                  return ProductCard(
                    p: p,
                    onTap: () {
                      // Optional: open catalog prefilled with this product name
                      _openCatalogWithSearch(p.name);
                    },
                    onAdd: () {
                      // Optional: take them to catalog so they can set qty
                      _openCatalogWithSearch(p.name);
                    },
                  );
                },
              ),

            const SizedBox(height: 16),

            // ✅ Simple “Deals / Info” banner block
            _InfoBanner(
              title: "Fast ordering for sub-dealers",
              subtitle: "Search → add qty → place order in seconds",
              onTap: () => _openCatalogWithSearch(""),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBell;

  const _BrandHeader({
    required this.title,
    required this.subtitle,
    required this.onBell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onBell,
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InfoBanner({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.lightGreen.shade50,
          border: Border.all(color: Colors.lightGreen.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';
import '../../catalog/widgets/product_card.dart';
import '../subdealer_shell.dart'; // for subdealerTabIndex


class SdHomePage extends StatefulWidget {
  const SdHomePage({super.key});

  @override
  State<SdHomePage> createState() => _SdHomePageState();
}

class _SdHomePageState extends State<SdHomePage> {
  final searchCtrl = TextEditingController();
  bool loading = true;
  String? error;

  List<Product> all = [];
  List<Product> top = [];

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      all = await catalogApi.listProducts();

      // “Top Products” logic (simple): highest stock first
      all.sort((a, b) => b.globalStock.compareTo(a.globalStock));
      top = all.take(6).toList();
    } catch (e) {
      error = "Failed to load products: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // Simple local categories (we can connect backend later)
  final categories = const [
    _Category("Seeds", Icons.grass),
    _Category("Fertilizers", Icons.science),
    _Category("Pesticides", Icons.bug_report),
    _Category("Tools", Icons.handyman),
    _Category("Sprayers", Icons.water_drop),
    _Category("Drip", Icons.water),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            children: [
              // Brand banner (like frame_08)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pavan HI-TECH Agro",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Dealer Inventory & Ordering",
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 12),

              TextField(
                controller: searchCtrl,
                readOnly: true,
                onTap: () {
                  catalogSearchBus.openCatalogWithSearch(searchCtrl.text);
                  subdealerTabIndex.value = 1; // open Catalog tab instantly
                },
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),




              const SizedBox(height: 18),

              // Shop by Category title row
              Row(
                children: [
                  const Text("Shop by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Categories can be connected later")),
                      );
                    },
                    child: const Text("See all"),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Category horizontal cards (like frame_08)
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return _CategoryCard(
                      title: c.title,
                      icon: c.icon,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Open ${c.title} (hook later)")),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Our Top Product (like frame_08)
              Row(
                children: [
                  const Text("Our Top Product", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Open Catalog tab for full list")),
                      );
                    },
                    child: const Text("View all"),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Center(child: Text(error!)),
                )
              else if (top.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Center(child: Text("No products available")),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, i) {
                    final p = top[i];
                    return ProductCard(
                      p: p,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Go to Catalog to add: ${p.name}")),
                        );
                      },
                      onAdd: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Add from Catalog (cart) for now")),
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: 8),

              // Optional: quick banner card like ecommerce
              Card(
                elevation: 0,
                color: Colors.green.withOpacity(0.10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Fast dispatch • Track your orders in My Orders",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      )
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

class _Category {
  final String title;
  final IconData icon;
  const _Category(this.title, this.icon);
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.green),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

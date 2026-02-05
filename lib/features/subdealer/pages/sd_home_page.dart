import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';
import '../../catalog/widgets/product_card.dart';

class SdHomePage extends StatefulWidget {
  const SdHomePage({super.key});

  @override
  State<SdHomePage> createState() => _SdHomePageState();
}

class _SdHomePageState extends State<SdHomePage> {
  final searchCtrl = TextEditingController();
  bool loading = true;
  List<Product> top = [];

  @override
  void initState() {
    super.initState();
    _loadTop();
  }

  Future<void> _loadTop() async {
    setState(() => loading = true);
    try {
      final all = await catalogApi.listProducts();
      // simple: take first 8 as "top"
      top = all.take(8).toList();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTop,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            // ✅ Brand banner (frame_08 vibe)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.green.shade800, Colors.green.shade500],
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
                    "Order • Stock • Delivery Tracking",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Search bar (tap opens catalog instantly)
            TextField(
              controller: searchCtrl,
              readOnly: true,
              onTap: () {
                // this is your existing bus -> it should switch to Catalog tab and focus search
                catalogSearchBus.openCatalogWithSearch("");
                // if you use a tab index notifier in subdealer shell, trigger it there as earlier
                // e.g. subdealerTabIndex.value = 1;
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

            const SizedBox(height: 16),

            const Text(
              "Top Products",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            if (loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: top.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (_, i) {
                  final p = top[i];
                  return ProductCard(
                    p: p,
                    onTap: () {
                      // open product details later if needed
                    },
                    onAdd: () {
                      // optionally: go to catalog with this product name
                      catalogSearchBus.openCatalogWithSearch(p.name);
                      // subdealerTabIndex.value = 1;
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

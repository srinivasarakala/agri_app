import 'package:flutter/material.dart';
import '../../main.dart';
import '../catalog/product.dart';
import '../catalog/widgets/product_card.dart';
import '../../core/widgets/top_banner.dart';
import '../subdealer/pages/sd_catalog_page.dart'; // reuse your existing catalog page

class HomePage extends StatefulWidget {
  final String role; // "DEALER_ADMIN" or "SUBDEALER"
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  String? error;
  List<Product> featured = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final all = await catalogApi.listProducts();
      featured = all.take(8).toList();
    } catch (e) {
      error = "Failed to load products";
    } finally {
      setState(() => loading = false);
    }
  }

  void openCatalog({String initialQuery = ""}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SdCatalogPage(initialQuery: initialQuery), // small change below
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.role == "DEALER_ADMIN"
        ? "Admin Dashboard"
        : "Subdealer Ordering";

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          TopBanner(subtitle: subtitle),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _SearchPill(
              onTap: () => openCatalog(initialQuery: ""),
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Text("Featured", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const Spacer(),
                TextButton(
                  onPressed: () => openCatalog(initialQuery: ""),
                  child: const Text("See all"),
                ),
              ],
            ),
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.builder(
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
                    onTap: () => openCatalog(initialQuery: p.name),
                    onAdd: () => openCatalog(initialQuery: p.name),
                  );
                },
              ),
            ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
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
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.mic_none, size: 20, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

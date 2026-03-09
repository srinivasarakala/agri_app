import 'package:flutter/material.dart';
import 'package:pavan_agro/core/theme/app_theme.dart';
import '../catalog/category.dart';
import '../category/categories_grid_page.dart';
import '../catalog/unified_products_page.dart';
import '../catalog/product.dart';
import '../../main.dart';
import '../profile/profile_page.dart';
import '../profile/user_profile.dart';

class CategoriesNavPage extends StatefulWidget {
  const CategoriesNavPage({Key? key}) : super(key: key);

  @override
  State<CategoriesNavPage> createState() => _CategoriesNavPageState();
}

class _CategoriesNavPageState extends State<CategoriesNavPage> {
  List<Category> categories = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // Load all products and filter spare parts
      final allProducts = await catalogApi.listProducts();
      final spareParts = allProducts.where((p) => p.isSparePart).toList();
      
      // Group spare parts by category
      final categoryMap = <int, List<Product>>{};
      for (final part in spareParts) {
        if (part.categoryId != null) {
          categoryMap.putIfAbsent(part.categoryId!, () => []).add(part);
        }
      }
      
      // Load all categories and create new category objects with spare parts counts
      final allCategories = await catalogApi.listCategories();
      categories = allCategories
          .where((cat) => categoryMap.containsKey(cat.id))
          .map((cat) {
            final sparePartsInCategory = categoryMap[cat.id]!;
            final sparePartImages = sparePartsInCategory
                .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
                .take(4)
                .map((p) => p.imageUrl!)
                .toList();
            
            // Create a new category with spare parts count and images
            return Category(
              id: cat.id,
              name: cat.name,
              description: cat.description,
              imageUrl: cat.imageUrl,
              productCount: sparePartsInCategory.length,
              productImages: sparePartImages,
              is_active: cat.is_active,
              isDynamic: cat.isDynamic,
            );
          })
          .toList();
    } catch (e) {
      error = "Failed to load spare parts categories";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _showProfileInfo(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<UserProfile>(
          future: profileApi.getProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading profile',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
            final profile = snapshot.data!;
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Information',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Profile',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileInfoTile(
                  icon: Icons.person,
                  label: 'Name',
                  value: profile.fullName.isNotEmpty
                      ? profile.fullName
                      : 'Not set',
                ),
                const SizedBox(height: 16),
                _ProfileInfoTile(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: profile.phone,
                ),
                const SizedBox(height: 16),
                _ProfileInfoTile(
                  icon: Icons.badge,
                  label: 'Role',
                  value: profile.role,
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Sticky Top Banner with Title and Profile Icon
        SliverAppBar(
          pinned: true,
          floating: false,
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          toolbarHeight: 100, // Adjusted height for banner (55) + title (45)
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Container(
              color: AppTheme.backgroundColor,
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 55,
                        alignment: Alignment.center,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Image.asset(
                            'assets/images/top_banner.png',
                            height: 55,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      Container(
                        height: 45,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text(
                          'Spare Parts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    top: 4,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showProfileInfo(context),
                        child: Container(
                          height: 52,
                          width: 52,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.account_circle,
                            size: 32,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Scrollable Content
        SliverFillRemaining(
          child: CategoriesGridPage(
            title: '',
            categories: categories,
            isLoading: loading,
            error: error,
            onCategoryTap: (category) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UnifiedProductsPage(
                    categoryId: category.id,
                    categoryName: category.name,
                    showOnlySpareParts: true,
                  ),
                ),
              );
            },
            onRefresh: _loadCategories,
          ),
        ),
      ],
    );
    
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


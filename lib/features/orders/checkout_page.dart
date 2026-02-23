import 'package:flutter/material.dart';
import '../../main.dart';
import '../profile/user_profile.dart';
import '../catalog/product.dart';
import '../../core/cart/cart_state.dart';
import '../shell/app_shell.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  UserProfile? profile;
  bool loading = true;
  bool placing = false;
  String? error;

  List<Product> allProducts = [];

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProducts();
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      profile = await profileApi.getProfile();

      // Pre-fill form with existing data
      firstNameCtrl.text = profile?.firstName ?? '';
      lastNameCtrl.text = profile?.lastName ?? '';
      addressCtrl.text = profile?.address ?? '';
      cityCtrl.text = profile?.city ?? '';
      stateCtrl.text = profile?.state ?? '';
      pincodeCtrl.text = profile?.pincode ?? '';
    } catch (e) {
      error = 'Failed to load profile: $e';
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      allProducts = await catalogApi.listProducts();
      setState(() {});
    } catch (e) {
      // Silent fail, products are for display only
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = {
        'first_name': firstNameCtrl.text.trim(),
        'last_name': lastNameCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'state': stateCtrl.text.trim(),
        'pincode': pincodeCtrl.text.trim(),
      };

      profile = await profileApi.updateProfile(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      error = 'Failed to update profile: $e';
    } finally {
      setState(() => loading = false);
    }
  }

  bool _isProfileComplete() {
    return firstNameCtrl.text.trim().isNotEmpty &&
        addressCtrl.text.trim().isNotEmpty &&
        cityCtrl.text.trim().isNotEmpty &&
        stateCtrl.text.trim().isNotEmpty &&
        pincodeCtrl.text.trim().isNotEmpty;
  }

  Future<void> _placeOrder() async {
    if (!_isProfileComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => placing = true);

    try {
      // Save profile first if there are unsaved changes
      await _updateProfile();

      // Place order
      final items = cartQty.value.entries
          .map((e) => {"product_id": e.key, "qty": e.value.toDouble()})
          .toList();

      await ordersApi.createOrder(items: items);

      if (!mounted) return;

      // Clear cart and navigate
      cartClear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to home
      Navigator.of(context).pop();
      appTabIndex.value = 0;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => placing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isProfileComplete()
                                  ? 'Your delivery information is complete. Review and place your order.'
                                  : 'Please complete your delivery information to place the order.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Form
                  const Text(
                    'Delivery Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: firstNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'First Name *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      errorText: firstNameCtrl.text.isEmpty ? 'Required' : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: lastNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Delivery Address *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                      errorText: addressCtrl.text.isEmpty ? 'Required' : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: cityCtrl,
                    decoration: InputDecoration(
                      labelText: 'City *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_city),
                      errorText: cityCtrl.text.isEmpty ? 'Required' : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: stateCtrl,
                    decoration: InputDecoration(
                      labelText: 'State *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.map),
                      errorText: stateCtrl.text.isEmpty ? 'Required' : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: pincodeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Pincode *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.pin_drop),
                      errorText: pincodeCtrl.text.isEmpty ? 'Required' : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // Order Summary
                  ValueListenableBuilder<Map<int, int>>(
                    valueListenable: cartQty,
                    builder: (_, cart, __) {
                      final cartProducts = allProducts
                          .where((p) => cart.containsKey(p.id))
                          .toList();

                      final totalAmount = cartProducts.fold<double>(0, (
                        sum,
                        p,
                      ) {
                        final qty = cart[p.id] ?? 0;
                        return sum + (p.sellingPrice * qty);
                      });

                      final totalItems = cart.values.fold<int>(
                        0,
                        (a, b) => a + b,
                      );

                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Items list
                              ...cartProducts.map((product) {
                                final qty = cart[product.id] ?? 0;
                                final itemTotal = product.sellingPrice * qty;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Qty: $qty × ₹${product.sellingPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${itemTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Total row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Items:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '$totalItems',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: loading || error != null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isProfileComplete())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '* All marked fields are required',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: placing
                          ? null
                          : (_isProfileComplete() ? _placeOrder : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey.shade300,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: placing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _isProfileComplete()
                                  ? 'Place Order'
                                  : 'Complete Required Fields to Place Order',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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

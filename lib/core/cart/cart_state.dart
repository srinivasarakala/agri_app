import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show cartApi, catalogApi;

/// productId -> qty (int)
final ValueNotifier<Map<int, int>> cartQty = ValueNotifier<Map<int, int>>({});

/// productId -> isFavorite (bool)
final ValueNotifier<Set<int>> favorites = ValueNotifier<Set<int>>({});

int get cartTotalQty => cartQty.value.values.fold(0, (a, b) => a + b);

String? _currentUserPhone;
SharedPreferences? _prefs;

// Initialize SharedPreferences once
Future<void> initCartStorage() async {
  try {
    _prefs = await SharedPreferences.getInstance();
    print('SharedPreferences initialized successfully');
  } catch (e) {
    print('Error initializing SharedPreferences: $e');
  }
}

// Load cart and favorites for a user
Future<void> loadUserCart(String phone) async {
  _currentUserPhone = phone;

  try {
    // First try to load from backend
    try {
      final backendCart = await cartApi.loadCart();
      cartQty.value = backendCart;
      print('Loaded cart from backend: $backendCart');

      // Save to local storage for offline access
      if (_prefs != null) {
        final cartMap = backendCart.map((k, v) => MapEntry(k.toString(), v));
        await _prefs!.setString('cart_$phone', json.encode(cartMap));
      }
    } catch (e) {
      print('Failed to load from backend, loading from local storage: $e');

      // Fallback to local storage
      if (_prefs == null) {
        await initCartStorage();
      }

      if (_prefs != null) {
        final cartJson = _prefs!.getString('cart_$phone');
        if (cartJson != null) {
          final Map<String, dynamic> decoded = json.decode(cartJson);
          cartQty.value = decoded.map(
            (k, v) => MapEntry(int.parse(k), v as int),
          );
          print('Loaded cart from local storage: ${cartQty.value}');
        } else {
          cartQty.value = {};
        }
      } else {
        cartQty.value = {};
      }
    }

    // Load favorites from backend first, fallback to local storage
    try {
      final backendFavorites = await catalogApi.getFavorites();
      favorites.value = backendFavorites.toSet();
      print('Loaded favorites from backend: $backendFavorites');

      // Save to local storage for offline access
      if (_prefs != null) {
        await _prefs!.setString('favs_$phone', json.encode(backendFavorites));
      }
    } catch (e) {
      print(
        'Failed to load favorites from backend, loading from local storage: $e',
      );

      // Fallback to local storage
      if (_prefs == null) {
        await initCartStorage();
      }

      if (_prefs != null) {
        final favsJson = _prefs!.getString('favs_$phone');
        if (favsJson != null) {
          final List<dynamic> decoded = json.decode(favsJson);
          favorites.value = decoded.cast<int>().toSet();
          print('Loaded favorites from local storage: ${favorites.value}');
        } else {
          favorites.value = {};
        }
      } else {
        favorites.value = {};
      }
    }
  } catch (e) {
    print('Error loading cart: $e');
    cartQty.value = {};
    favorites.value = {};
  }
}

// Save cart to SharedPreferences and backend (fire-and-forget)
void _saveCart() {
  if (_currentUserPhone == null) {
    print('Cannot save cart: no user phone');
    return;
  }

  // Save to backend
  cartApi
      .syncCart(cartQty.value)
      .then((_) {
        print('Cart synced to backend: ${cartQty.value}');
      })
      .catchError((e) {
        print('Error syncing cart to backend: $e');
      });

  // Ensure _prefs is initialized before saving to local storage
  if (_prefs == null) {
    print('Initializing SharedPreferences for cart save...');
    initCartStorage().then((_) {
      if (_prefs != null) {
        _saveCart(); // Retry after initialization
      }
    });
    return;
  }

  try {
    final cartMap = cartQty.value.map((k, v) => MapEntry(k.toString(), v));
    final jsonStr = json.encode(cartMap);
    _prefs!
        .setString('cart_$_currentUserPhone', jsonStr)
        .then((_) {
          print('Saved cart locally for $_currentUserPhone: $jsonStr');
        })
        .catchError((e) {
          print('Error saving cart locally: $e');
        });
  } catch (e) {
    print('Error saving cart locally: $e');
  }
}

// Save favorites to SharedPreferences (fire-and-forget)
void _saveFavorites() {
  if (_currentUserPhone == null) {
    print('Cannot save favorites: no user phone');
    return;
  }

  // Ensure _prefs is initialized before saving
  if (_prefs == null) {
    print('Initializing SharedPreferences for favorites save...');
    initCartStorage().then((_) {
      if (_prefs != null) {
        _saveFavorites(); // Retry after initialization
      }
    });
    return;
  }

  try {
    final jsonStr = json.encode(favorites.value.toList());
    _prefs!
        .setString('favs_$_currentUserPhone', jsonStr)
        .then((_) {
          print('Saved favorites for $_currentUserPhone: $jsonStr');
        })
        .catchError((e) {
          print('Error saving favorites: $e');
        });
  } catch (e) {
    print('Error saving favorites: $e');
  }
}

void cartSetQty(int productId, int qty) {
  final m = Map<int, int>.from(cartQty.value);
  if (qty <= 0) {
    m.remove(productId);
  } else {
    m[productId] = qty;
  }
  cartQty.value = UnmodifiableMapView(m);
  _saveCart();
}

// Version of cartSetQty that returns errors for UI feedback
Future<String?> cartSetQtyWithValidation(int productId, int qty) async {
  try {
    // Try to update on backend first to validate stock
    await cartApi.updateCartItem(productId, qty);

    // If successful, update local state
    final m = Map<int, int>.from(cartQty.value);
    if (qty <= 0) {
      m.remove(productId);
    } else {
      m[productId] = qty;
    }
    cartQty.value = UnmodifiableMapView(m);
    return null; // No error
  } catch (e) {
    print('Error updating cart: $e');
    // Extract error message from exception
    final errorMsg = e.toString();
    if (errorMsg.contains('out of stock')) {
      return 'Product is out of stock';
    } else if (errorMsg.contains('available in stock')) {
      // Extract number from error message
      return errorMsg.split('error: ').last;
    }
    return 'Failed to add to cart';
  }
}

void cartClear() {
  cartQty.value = const {};
  _saveCart();
}

void setFavorites(List<int> favoriteIds) {
  favorites.value = Set<int>.from(favoriteIds);
  _saveFavorites();
}

// Clear user session (call on logout)
void clearUserSession() {
  print('Clearing user session. Current user: $_currentUserPhone');
  print('Current cart: ${cartQty.value}');
  print('Current favorites: ${favorites.value}');
  _currentUserPhone = null;
  cartQty.value = const {};
  favorites.value = const {};
  print('Session cleared');
}

void toggleFavorite(int productId) {
  final fav = Set<int>.from(favorites.value);
  if (fav.contains(productId)) {
    fav.remove(productId);
  } else {
    fav.add(productId);
  }
  favorites.value = fav;
  _saveFavorites();
}

bool isFavorite(int productId) {
  return favorites.value.contains(productId);
}

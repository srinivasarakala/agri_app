import 'dart:collection';

import 'package:flutter/material.dart';

/// productId -> qty (int)
final ValueNotifier<Map<int, int>> cartQty = ValueNotifier<Map<int, int>>({});

int get cartTotalQty => cartQty.value.values.fold(0, (a, b) => a + b);

void cartSetQty(int productId, int qty) {
  final m = Map<int, int>.from(cartQty.value);
  if (qty <= 0) {
    m.remove(productId);
  } else {
    m[productId] = qty;
  }
  cartQty.value = UnmodifiableMapView(m);
}

void cartClear() {
  cartQty.value = const {};
}

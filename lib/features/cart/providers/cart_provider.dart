import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/cart_item.dart';

/// Riverpod state for the shopping cart. Persists to SharedPreferences so the
/// cart survives app restarts. Kept deliberately simple (JSON list) — swap for
/// Hive if you need richer offline querying later.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []) {
    _load();
  }

  static const _storageKey = 'ayshamart_cart_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = (jsonDecode(raw) as List)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = decoded;
    } catch (_) {
      // Corrupt cache — start clean.
      state = const [];
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void add(CartItem item) {
    final existing = state.indexWhere((e) => e.key == item.key);
    if (existing >= 0) {
      final current = state[existing];
      final next = _clampQty(current.quantity + item.quantity, current.maxStock);
      state = [...state]..[existing] = current.copyWith(quantity: next);
    } else {
      state = [...state, item];
    }
    _persist();
  }

  void setQuantity(String key, int quantity) {
    if (quantity <= 0) {
      remove(key);
      return;
    }
    state = [
      for (final item in state)
        if (item.key == key)
          item.copyWith(quantity: _clampQty(quantity, item.maxStock))
        else
          item,
    ];
    _persist();
  }

  void increment(String key) {
    final item = state.firstWhere((e) => e.key == key);
    setQuantity(key, item.quantity + 1);
  }

  void decrement(String key) {
    final item = state.firstWhere((e) => e.key == key);
    setQuantity(key, item.quantity - 1);
  }

  void remove(String key) {
    state = state.where((e) => e.key != key).toList();
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  int _clampQty(int qty, int? max) {
    if (qty < 1) return 1;
    if (max != null && max > 0 && qty > max) return max;
    return qty;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

/// Total number of units in the cart (for the badge).
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold<int>(0, (sum, i) => sum + i.quantity);
});

/// Cart subtotal (sum of line totals) as a double.
final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold<double>(0, (sum, i) => sum + i.lineTotal);
});

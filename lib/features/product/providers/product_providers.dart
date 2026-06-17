import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../data/models/product_variation.dart';
import '../../../providers/core_providers.dart';

/// Full product detail (re-fetched to get description, all images, etc.).
final productDetailProvider =
    FutureProvider.autoDispose.family<Product, int>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).product(id);
});

/// Variations for a `variable` product. Empty for simple products.
final productVariationsProvider =
    FutureProvider.autoDispose.family<List<ProductVariation>, int>(
        (ref, id) async {
  return ref.watch(catalogRepositoryProvider).variations(id);
});

/// Derives `attributeName -> ordered unique options` from a variation list,
/// so the UI can render one selector row per attribute.
Map<String, List<String>> deriveAttributeOptions(
    List<ProductVariation> variations) {
  final map = <String, List<String>>{};
  for (final v in variations) {
    v.attributes.forEach((name, option) {
      final list = map.putIfAbsent(name, () => <String>[]);
      if (option.isNotEmpty && !list.contains(option)) list.add(option);
    });
  }
  return map;
}

/// Finds the variation matching the user's full selection (or null).
ProductVariation? matchVariation(
  List<ProductVariation> variations,
  Map<String, String> selection,
) {
  for (final v in variations) {
    final matches = v.attributes.entries.every(
      (e) => selection[e.key] == e.value,
    );
    if (matches && v.attributes.length == selection.length) return v;
  }
  return null;
}

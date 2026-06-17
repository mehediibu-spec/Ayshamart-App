import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_variation.dart';
import '../../../providers/core_providers.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/product_providers.dart';

/// Product detail with image gallery, price, rating, variation selector and a
/// sticky add-to-cart bar. Works for both simple and variable products.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final Map<String, String> _selection = {};
  int _quantity = 1;
  int _galleryIndex = 0;

  Product get _product => widget.product;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeCodeProvider);
    final cartCount = ref.watch(cartCountProvider);
    final variationsAsync = _product.hasVariations
        ? ref.watch(productVariationsProvider(_product.id))
        : const AsyncValue<List<ProductVariation>>.data([]);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          _CartButton(
            count: cartCount,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: variationsAsync.when(
        loading: () => _body(locale, const [], loadingVariations: true),
        error: (_, __) => _body(locale, const []),
        data: (variations) => _body(locale, variations),
      ),
    );
  }

  Widget _body(String locale, List<ProductVariation> variations,
      {bool loadingVariations = false}) {
    final selected = matchVariation(variations, _selection);
    final attributeOptions = deriveAttributeOptions(variations);

    final priceSource = selected ?? _product;
    final price = selected?.price ?? _product.price;
    final regular = selected?.regularPrice ?? _product.regularPrice;
    final discount = selected?.discountPercent ?? _product.discountPercent;
    final inStock = selected?.inStock ?? _product.inStock;
    final needsSelection =
        _product.hasVariations && variations.isNotEmpty && selected == null;

    final images = _product.images.isNotEmpty
        ? _product.images
        : [if (_product.primaryImage.isNotEmpty) _product.primaryImage];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Gallery
              if (images.isNotEmpty) ...[
                AspectRatio(
                  aspectRatio: 1,
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _galleryIndex = i),
                    itemBuilder: (_, i) => Container(
                      color: Colors.white,
                      child: AppNetworkImage(url: images[i], fit: BoxFit.contain),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _galleryIndex ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _galleryIndex
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(_product.averageRating.toStringAsFixed(1)),
                        Text('  (${_product.ratingCount} reviews)',
                            style: const TextStyle(color: AppColors.textMuted)),
                        const Spacer(),
                        _StockChip(inStock: inStock),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Taka.formatForLocale(price, locale),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (discount > 0) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              Taka.formatForLocale(regular, locale),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.sale.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Save $discount%',
                              style: const TextStyle(
                                color: AppColors.sale,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Variation selectors
              if (loadingVariations)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (attributeOptions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in attributeOptions.entries) ...[
                        Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.value.map((option) {
                            final isSelected = _selection[entry.key] == option;
                            return ChoiceChip(
                              label: Text(option),
                              selected: isSelected,
                              onSelected: (_) => setState(() {
                                _selection[entry.key] = option;
                              }),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),

              // Description
              if (_descriptionText.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        _descriptionText,
                        style: const TextStyle(
                            height: 1.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Sticky add-to-cart bar
        _AddToCartBar(
          quantity: _quantity,
          enabled: inStock && !needsSelection,
          hint: needsSelection ? 'Select options' : null,
          onQtyChanged: (q) => setState(() => _quantity = q),
          onAdd: () => _addToCart(priceSource, selected),
        ),
      ],
    );
  }

  String get _descriptionText {
    final raw = _product.shortDescription.isNotEmpty
        ? _product.shortDescription
        : _product.description;
    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  void _addToCart(dynamic priceSource, ProductVariation? variation) {
    final item = CartItem(
      productId: _product.id,
      variationId: variation?.id,
      name: _product.name,
      image: variation?.image ?? _product.primaryImage,
      price: variation?.price ?? _product.price,
      variationLabel: variation?.label,
      quantity: _quantity,
      maxStock: variation?.stockQuantity ?? _product.stockQuantity,
    );
    ref.read(cartProvider.notifier).add(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${_product.name} added to cart'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: AppColors.accent,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
  }
}

class _StockChip extends StatelessWidget {
  final bool inStock;
  const _StockChip({required this.inStock});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (inStock ? AppColors.success : AppColors.danger)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        inStock ? 'In stock' : 'Out of stock',
        style: TextStyle(
          color: inStock ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CartButton({required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
            onPressed: onTap, icon: const Icon(Icons.shopping_bag_outlined)),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.sale, shape: BoxShape.circle),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  final int quantity;
  final bool enabled;
  final String? hint;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onAdd;

  const _AddToCartBar({
    required this.quantity,
    required this.enabled,
    required this.hint,
    required this.onQtyChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed:
                      quantity > 1 ? () => onQtyChanged(quantity - 1) : null,
                  icon: const Icon(Icons.remove_rounded),
                  visualDensity: VisualDensity.compact,
                ),
                Text('$quantity',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                IconButton(
                  onPressed: () => onQtyChanged(quantity + 1),
                  icon: const Icon(Icons.add_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.shopping_cart_rounded, size: 20),
              label: Text(hint ?? 'Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}

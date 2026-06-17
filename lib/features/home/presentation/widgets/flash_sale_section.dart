import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/product.dart';
import 'product_card.dart';

/// Flash-sale band with a bold gradient header, a live countdown timer and a
/// horizontally scrolling list of discounted products.
class FlashSaleSection extends StatefulWidget {
  final List<Product> products;
  final DateTime endsAt;
  final ValueChanged<Product>? onProductTap;
  final ValueChanged<Product>? onAddToCart;

  const FlashSaleSection({
    super.key,
    required this.products,
    required this.endsAt,
    this.onProductTap,
    this.onAddToCart,
  });

  @override
  State<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<FlashSaleSection> {
  late Duration _remaining;
  late final Stream<void> _ticker;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endsAt.difference(DateTime.now());
    _ticker = Stream.periodic(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(gradient: AppColors.saleGradient),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 6),
                const Text(
                  'Flash Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                StreamBuilder<void>(
                  stream: _ticker,
                  builder: (context, _) {
                    _remaining = widget.endsAt.difference(DateTime.now());
                    if (_remaining.isNegative) _remaining = Duration.zero;
                    return _CountdownPill(remaining: _remaining);
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 296,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final p = widget.products[i];
                return ProductCard(
                  product: p,
                  width: 168,
                  onTap: () => widget.onProductTap?.call(p),
                  onAddToCart: () => widget.onAddToCart?.call(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  final Duration remaining;
  const _CountdownPill({required this.remaining});

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _two(remaining.inHours);
    final m = _two(remaining.inMinutes.remainder(60));
    final s = _two(remaining.inSeconds.remainder(60));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            'Ends in $h:$m:$s',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

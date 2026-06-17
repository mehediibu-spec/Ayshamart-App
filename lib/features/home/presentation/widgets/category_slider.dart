import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../data/models/category.dart';

/// Horizontally scrolling category chips with circular imagery — a familiar,
/// premium pattern for gadget storefronts.
class CategorySlider extends StatelessWidget {
  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory>? onTap;

  const CategorySlider({super.key, required this.categories, this.onTap});

  // Fallback icons by slug keyword when a category has no image set in Woo.
  static const Map<String, IconData> _iconBySlug = {
    'phone': Icons.smartphone_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'earbud': Icons.earbuds_rounded,
    'watch': Icons.watch_rounded,
    'accessor': Icons.cable_rounded,
    'power': Icons.battery_charging_full_rounded,
  };

  IconData _iconFor(ProductCategory c) {
    for (final entry in _iconBySlug.entries) {
      if (c.slug.contains(entry.key) ||
          c.name.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final c = categories[i];
          return GestureDetector(
            onTap: () => onTap?.call(c),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (c.image != null && c.image!.isNotEmpty)
                        ? AppNetworkImage(url: c.image!, fit: BoxFit.cover)
                        : Icon(_iconFor(c),
                            color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

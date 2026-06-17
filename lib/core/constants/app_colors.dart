import 'package:flutter/material.dart';

/// Brand palette for a premium gadget storefront — deep indigo primary with a
/// warm gold accent for promotions and a clean neutral surface system.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF1A1B41); // deep indigo / near-navy
  static const Color primaryLight = Color(0xFF2E3074);
  static const Color accent = Color(0xFFF5A623); // premium gold
  static const Color accentDark = Color(0xFFD98A0B);

  // Semantic
  static const Color success = Color(0xFF1FAA59);
  static const Color danger = Color(0xFFE53935);
  static const Color sale = Color(0xFFE53935); // flash-sale red
  static const Color info = Color(0xFF2D9CDB);

  // Neutrals (light)
  static const Color scaffold = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7E9EF);
  static const Color textPrimary = Color(0xFF14151A);
  static const Color textSecondary = Color(0xFF6B6F7B);
  static const Color textMuted = Color(0xFF9AA0AE);
  static const Color shimmerBase = Color(0xFFE9ECF2);
  static const Color shimmerHighlight = Color(0xFFF7F8FB);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient saleGradient = LinearGradient(
    colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';

/// Cached, lazily-loaded image with a shimmer placeholder and graceful error
/// fallback. Used everywhere product imagery appears so caching + memory
/// down-sizing is consistent across the app.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      // Decode at display size to keep memory low and scrolling smooth.
      memCacheWidth: width != null && width!.isFinite
          ? (width! * MediaQuery.of(context).devicePixelRatio).round()
          : 800,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(width: width, height: height, color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppColors.shimmerBase,
        child: const Icon(Icons.image_not_supported_outlined,
            color: AppColors.textMuted),
      ),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

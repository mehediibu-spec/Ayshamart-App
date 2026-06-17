import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../data/models/promo_banner.dart';

/// Auto-playing promotional banner carousel with a dot indicator and a subtle
/// gradient scrim so overlaid text stays legible on any image.
class PromoBannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  final ValueChanged<PromoBanner>? onTap;

  const PromoBannerCarousel({super.key, required this.banners, this.onTap});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.banners.length,
          options: CarouselOptions(
            height: 175,
            viewportFraction: 0.9,
            autoPlay: widget.banners.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayCurve: Curves.easeOutCubic,
            enlargeCenterPage: true,
            enlargeFactor: 0.18,
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          itemBuilder: (context, i, _) {
            final banner = widget.banners[i];
            return GestureDetector(
              onTap: () => widget.onTap?.call(banner),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      url: banner.imageUrl,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.black.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                    if (banner.title != null)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            if (banner.subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                banner.subtitle!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedSmoothIndicator(
          activeIndex: _index,
          count: widget.banners.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 3,
            activeDotColor: AppColors.primary,
            dotColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}

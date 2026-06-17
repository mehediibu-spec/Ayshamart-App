/// A home-screen promotional banner. In production, source these from a
/// WordPress endpoint (ACF options / a custom `ayshamart/v1/banners` route)
/// so marketing can update them without an app release.
class PromoBanner {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? deepLink; // e.g. category:3, product:101, url:https://...

  const PromoBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.deepLink,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
        id: json['id']?.toString() ?? '',
        imageUrl: json['image']?.toString() ?? '',
        title: json['title']?.toString(),
        subtitle: json['subtitle']?.toString(),
        deepLink: json['link']?.toString(),
      );
}

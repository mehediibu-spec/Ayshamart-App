/// The signed-in customer. `id` is the WordPress/WooCommerce user id, which
/// doubles as the WooCommerce `customer_id` when creating orders.
class AppUser {
  final int id;
  final String email;
  final String displayName;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.firstName = '',
    this.lastName = '',
    this.avatarUrl,
  });

  /// From the WordPress `wp/v2/users/me` response.
  factory AppUser.fromWpUser(Map<String, dynamic> json) {
    final avatars = json['avatar_urls'];
    return AppUser(
      id: json['id'] as int? ?? 0,
      email: json['email']?.toString() ?? '',
      displayName: json['name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      avatarUrl: avatars is Map ? avatars['96']?.toString() : null,
    );
  }

  /// From the WooCommerce `wc/v3/customers` response.
  factory AppUser.fromWooCustomer(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int? ?? 0,
        email: json['email']?.toString() ?? '',
        displayName: (('${json['first_name'] ?? ''} '
                '${json['last_name'] ?? ''}')
            .trim()),
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        avatarUrl: json['avatar_url']?.toString(),
      );

  String get initials {
    final source = displayName.isNotEmpty ? displayName : email;
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source.isNotEmpty ? source[0].toUpperCase() : '?';
  }
}

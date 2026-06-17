import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/core_providers.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';

/// Account hub. Shows a sign-in prompt for guests and a profile + menu for
/// signed-in customers. Includes the app-wide language toggle (English /
/// বাংলা) which drives ৳ digit rendering across the app.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final locale = ref.watch(localeCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context, ref, auth),
          const SizedBox(height: 16),
          _card([
            _tile(Icons.receipt_long_outlined, 'My Orders',
                enabled: auth.isLoggedIn,
                subtitle: auth.isLoggedIn ? null : 'Sign in to view orders'),
            _divider(),
            _tile(Icons.favorite_border_rounded, 'Wishlist'),
            _divider(),
            _tile(Icons.location_on_outlined, 'Saved Addresses',
                enabled: auth.isLoggedIn),
          ]),
          const SizedBox(height: 16),
          _card([
            // Language toggle
            SwitchListTile(
              value: locale == 'bn',
              onChanged: (bn) => ref
                  .read(localeCodeProvider.notifier)
                  .state = bn ? 'bn' : 'en',
              activeColor: AppColors.primary,
              secondary: const Icon(Icons.translate_rounded,
                  color: AppColors.primary),
              title: const Text('বাংলা / Bengali'),
              subtitle: Text(locale == 'bn'
                  ? 'মূল্য বাংলা সংখ্যায় (৳১,৪৯৯)'
                  : 'Prices in English numerals (৳1,499)'),
            ),
            _divider(),
            _tile(Icons.headset_mic_outlined, 'Help & Support'),
            _divider(),
            _tile(Icons.info_outline_rounded, 'About Ayshamart'),
          ]),
          const SizedBox(height: 16),
          if (auth.isLoggedIn)
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out'),
            ),
          const SizedBox(height: 24),
          const Center(
            child: Text('Ayshamart • v1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, AuthState auth) {
    if (auth.status == AuthStatus.unknown) {
      return const SizedBox(
          height: 96, child: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome to Ayshamart',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Sign in to track orders and check out faster.',
                style: TextStyle(color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(160, 44),
              ),
              child: const Text('Sign In / Register'),
            ),
          ],
        ),
      );
    }

    final user = auth.user!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(user.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.isNotEmpty
                      ? user.displayName
                      : user.email,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _tile(IconData icon, String title,
      {String? subtitle, bool enabled = true}) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted),
      onTap: enabled ? () {} : null,
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              Navigator.pop(ctx);
            },
            child: const Text('Log Out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

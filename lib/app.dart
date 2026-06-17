import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/cart/presentation/cart_screen.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/home/presentation/home_screen.dart';
import 'providers/core_providers.dart';

/// Root widget. Wires the theme, localization delegates (English + Bengali)
/// and the primary navigation shell.
class AyshamartApp extends ConsumerWidget {
  const AyshamartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeCodeProvider);

    return MaterialApp(
      title: 'Ayshamart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: Locale(localeCode),
      supportedLocales: const [Locale('en'), Locale('bn')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootShell(),
    );
  }
}

/// Bottom-navigation shell hosting the five primary tabs. Home and Cart are
/// live; the rest are stubbed and meant to be filled out feature-by-feature.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeScreen(),
    _Placeholder(label: 'Categories'),
    CartScreen(),
    _Placeholder(label: 'Wishlist'),
    _Placeholder(label: 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withOpacity(0.10),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home'),
            const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Categories'),
            NavigationDestination(
                icon: Badge.count(
                  count: cartCount,
                  isLabelVisible: cartCount > 0,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                selectedIcon: Badge.count(
                  count: cartCount,
                  isLabelVisible: cartCount > 0,
                  child: const Icon(Icons.shopping_bag_rounded),
                ),
                label: 'Cart'),
            const NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Wishlist'),
            const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Account'),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text('$label — coming soon',
            style: const TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}

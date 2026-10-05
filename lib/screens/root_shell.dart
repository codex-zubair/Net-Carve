import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'ipv6_screen.dart';
import 'vlsm_screen.dart';

/// Top-level shell holding the five primary destinations.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _destinations = <_Destination>[
    _Destination(
      'Calculator',
      Icons.calculate_outlined,
      Icons.calculate_rounded,
    ),
    _Destination('VLSM', Icons.grid_view_outlined, Icons.grid_view_rounded),
    _Destination('IPv6', Icons.language_outlined, Icons.language_rounded),
    _Destination('History', Icons.history_outlined, Icons.history_rounded),
    _Destination('About', Icons.info_outline_rounded, Icons.info_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      VlsmScreen(),
      Ipv6Screen(),
      HistoryScreen(),
      AboutScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.bgDeep,
          indicatorColor: AppColors.accent.withValues(alpha: 0.16),
          height: 66,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon, color: AppColors.textFaint, size: 22),
                selectedIcon: Icon(
                  d.selectedIcon,
                  color: AppColors.accent,
                  size: 23,
                ),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Destination(this.label, this.icon, this.selectedIcon);
}

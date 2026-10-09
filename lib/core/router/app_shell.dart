// AppShell (S05): the 4-tab shell — 홈 · 플래너 · 타임테이블 · 통계. Settings is
// not a tab (home header gear → /settings). Phones get a bottom bar; tablets
// (≥ 600 dp) a left rail (prototype: 사이드바, 탭바 숨김).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/lucide_icon.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const List<({IconData icon, String label})> tabs = <({IconData icon, String label})>[
    (icon: LucideIcons.house, label: CommonStrings.tabHome),
    (icon: LucideIcons.calendarDays, label: CommonStrings.tabPlanner),
    (icon: LucideIcons.table, label: CommonStrings.tabTimetable),
    (icon: LucideIcons.chartColumn, label: CommonStrings.tabStats),
  ];

  void _go(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tablet = MediaQuery.sizeOf(context).width >= AppLayout.tabletBreakpoint;
    if (tablet) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              backgroundColor: c.surface,
              indicatorColor: c.priWeak,
              selectedIconTheme: IconThemeData(color: c.priTx, size: AppIcon.size),
              unselectedIconTheme: IconThemeData(color: c.tx3, size: AppIcon.size),
              selectedLabelTextStyle:
                  AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.priTx),
              unselectedLabelTextStyle: AppTypography.caption.copyWith(color: c.tx3),
              destinations: <NavigationRailDestination>[
                for (final t in tabs)
                  NavigationRailDestination(
                    icon: LucideIcon(t.icon),
                    label: Text(t.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, thickness: 1, color: c.line),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        backgroundColor: c.surface,
        indicatorColor: c.priWeak,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <Widget>[
          for (final t in tabs)
            NavigationDestination(
              icon: LucideIcon(t.icon, color: c.tx3),
              selectedIcon: LucideIcon(t.icon, color: c.priTx),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

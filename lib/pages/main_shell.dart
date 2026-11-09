import 'package:flutter/material.dart';

import '../store/ledger_store.dart';
import '../theme.dart';
import '../widgets/glass_box.dart';
import 'bill_page.dart';
import 'bookkeeping_page.dart';
import 'stats_page.dart';

/// 主壳：3 个页面 + 悬浮「长条圆」玻璃导航。
///
/// 底部导航不再贴边铺满，而是离底悬浮、两端全圆的胶囊条；
/// 选中项本身也是一个更小的圆胶囊。整条用液态玻璃材质。
/// extendBody: true 让背景光斑延伸到导航下方，毛玻璃才透得出内容。
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: LedgerStore.I,
        builder: (BuildContext context, Widget? child) {
          final int current = LedgerStore.I.tabIndex;
          final List<Widget> pages = <Widget>[
            const BookkeepingPage(),
            const BillPage(),
            const StatsPage(),
          ];
          return Scaffold(
            extendBody: true,
            body: Stack(
              children: <Widget>[
                const GlassBackground(),
                SafeArea(bottom: false, child: pages[current]),
              ],
            ),
            bottomNavigationBar: _buildNav(current),
          );
        },
      );

  Widget _buildNav(int current) => SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: GlassBox(
          radius: 30,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          opacity: 0.55,
          blur: 22,
          child: Row(
            children: <Widget>[
              _navItem(0, '记账', Icons.chat_bubble_outline, current),
              _navItem(1, '账单', Icons.receipt_long_outlined, current),
              _navItem(2, '统计', Icons.bar_chart_rounded, current),
            ],
          ),
        ),
      );

  Widget _navItem(int index, String label, IconData icon, int current) {
    final bool selected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => LedgerStore.I.goToTab(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brand.withOpacity(0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: selected
                ? Border.all(
                    color: Colors.white.withOpacity(0.85), width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.brand : AppColors.hint,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppColors.brand : AppColors.hint,
                  fontWeight:
                      selected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

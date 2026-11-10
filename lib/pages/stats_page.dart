import 'package:flutter/material.dart';

import '../services/stats.dart';
import '../store/ledger_store.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/amount_card.dart';
import '../widgets/category_bar.dart';
import '../widgets/glass_box.dart';

/// 页面 3 · 统计
/// 玻璃日均主卡（含环比）+ 分类占比 + 近 6 个月趋势。
/// 点某个分类 → 跳账单页并只显示该分类流水。
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: LedgerStore.I,
        builder: (BuildContext context, Widget? child) {
          final LedgerStore s = LedgerStore.I;
          final DateTime now = DateTime.now();
          final double total = sumOf(s.monthExpenses);
          // 用户确认的口径：按当月已过天数
          final double avg = dailyAverage(total, s.month, now: now);
          final double prevAvg =
              previousMonthAverage(s.trendExpenses, s.month);
          final double diff = avg - prevAvg;
          final String badge = prevAvg <= 0
              ? '上月暂无数据，继续记就能对比'
              : diff >= 0
                  ? '↑ 比上月日均多 ${money(diff.abs())}'
                  : '↓ 比上月日均少 ${money(diff.abs())}';

          final List<CategoryShare> shares = categoryShares(s.monthExpenses);
          final List<MonthPoint> points =
              monthPoints(s.trendExpenses, s.month);

          return SingleChildScrollView(
            // 按手机实际底部高度留白，避免最后一组柱子被导航盖住
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, navReservedHeight(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(s),
                const SizedBox(height: 12),
                AmountCard(
                  label: '本月日均消费',
                  amount: money(avg),
                  badge: badge,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    '本月合计 ${money(total)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '钱花在哪',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 11),
                if (shares.isEmpty)
                  const Text(
                    '这个月还没有记录',
                    style: TextStyle(fontSize: 12, color: AppColors.hint),
                  )
                else
                  ...shares.map(
                    (CategoryShare sh) => ShareBar(
                      share: sh,
                      onTap: () => s.goToBillsFiltered(sh.category),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  '近 6 个月',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                MonthBars(points: points, anchor: s.month),
              ],
            ),
          );
        },
      );

  Widget _header(LedgerStore s) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Text(
            '统计',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          GlassBox(
            radius: 16,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            opacity: 0.6,
            blur: 14,
            child: Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () => s.shiftFocusMonth(-1),
                  child: const Text('‹',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.brand)),
                ),
                Text(
                  '　${monthLabel(s.month)}　',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.ink),
                ),
                GestureDetector(
                  onTap: () => s.shiftFocusMonth(1),
                  child: const Text('›',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.brand)),
                ),
              ],
            ),
          ),
        ],
      );
}

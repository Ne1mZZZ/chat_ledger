import 'package:flutter/material.dart';

import '../services/stats.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'glass_box.dart';

/// 统计页「钱花在哪」的一行：分类名 + 彩色占比条 + 百分比/金额。
/// 底槽用轻量玻璃（半透明白 + 高光描边），不开模糊，滑动不卡。
/// 点一下会跳到账单页并只显示这个分类。
class ShareBar extends StatelessWidget {
  const ShareBar({super.key, required this.share, required this.onTap});

  final CategoryShare share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 30,
                child: Text(share.category,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted)),
              ),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: lightGlassDecoration(radius: 4),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: share.ratio.clamp(0.0, 1.0).toDouble(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: styleOf(share.category).color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 66,
                child: Text(
                  '${(share.ratio * 100).round()}% ${moneyShort(share.amount)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// 近 6 个月柱状趋势：当前月用实心靛蓝高亮，其余用半透明浅蓝玻璃。
/// 纯 Container 自绘，没有引入图表库。
class MonthBars extends StatelessWidget {
  const MonthBars({
    super.key,
    required this.points,
    required this.anchor,
  });

  final List<MonthPoint> points;
  final DateTime anchor;

  @override
  Widget build(BuildContext context) {
    final double max = points.fold<double>(
      1.0,
      (double m, MonthPoint p) => p.total > m ? p.total : m,
    );
    return SizedBox(
      height: 78,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((MonthPoint p) {
          final bool isCurrent =
              p.month.year == anchor.year && p.month.month == anchor.month;
          final double height = 12 + 42 * (p.total / max);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    height: height,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.brand
                          : Colors.white.withOpacity(0.55),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.85),
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${p.month.month}月',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent ? AppColors.brand : AppColors.muted,
                      fontWeight:
                          isCurrent ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

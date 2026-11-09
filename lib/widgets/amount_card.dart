import 'package:flutter/material.dart';

import '../theme.dart';
import 'glass_box.dart';

/// 【靛蓝冷白 · 视觉焦点】整张 App 唯一的实心主卡，现在改成液态玻璃材质：
/// 半透明靛蓝渐变 + 背景模糊 + 白色高光描边，能隐约透出底下的彩色光斑。
/// 记账页显示「本月支出」+ 日均/今日两栏；统计页显示「日均」+ 环比胶囊。
class AmountCard extends StatelessWidget {
  const AmountCard({
    super.key,
    required this.label,
    required this.amount,
    this.leftLabel,
    this.leftValue,
    this.rightLabel,
    this.rightValue,
    this.badge,
    this.onAmountTap,
    this.onLeftTap,
    this.onRightTap,
  });

  final String label;
  final String amount;
  final String? leftLabel;
  final String? leftValue;
  final String? rightLabel;
  final String? rightValue;
  final String? badge;
  final VoidCallback? onAmountTap;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;

  @override
  Widget build(BuildContext context) => GlassBox(
        radius: 18,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        tint: AppColors.brand,
        opacity: 0.86,
        blur: 20,
        highlight: 0.5,
        solidColor: AppColors.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              onTap: onAmountTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
                height: 0.5,
                width: double.infinity,
                color: Colors.white30),
            if (leftLabel != null)
              _buildSplitRow()
            else if (badge != null)
              _buildBadge(),
          ],
        ),
      );

  Widget _buildSplitRow() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: onLeftTap,
                behavior: HitTestBehavior.opaque,
                child: _Metric(label: leftLabel!, value: leftValue ?? ''),
              ),
            ),
            Container(width: 1, height: 26, color: Colors.white30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: GestureDetector(
                  onTap: onRightTap,
                  behavior: HitTestBehavior.opaque,
                  child: _Metric(
                      label: rightLabel ?? '', value: rightValue ?? ''),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBadge() => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            border: Border.all(
                color: Colors.white.withOpacity(0.35), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge!,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      );
}

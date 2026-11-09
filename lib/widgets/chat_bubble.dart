import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'glass_box.dart';

/// 用户发出的原话：半透明靛蓝渐变 + 高光描边，右下角切一个小直角。
/// 气泡尺寸小、模糊收益低，这里用渐变+描边做轻量玻璃感，不开 BackdropFilter。
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 240),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xE6185FA5), Color(0xCC0C447C)],
            ),
            border:
                Border.all(color: Colors.white.withOpacity(0.35), width: 1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      );
}

/// App 的确认卡片：液态玻璃 + 左侧 3px 靛蓝色条 + 「改一下 / 撤销」
class ConfirmCard extends StatelessWidget {
  const ConfirmCard({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String notePart = expense.note.isEmpty ? '' : ' · ${expense.note}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBox(
        radius: 12,
        padding: EdgeInsets.zero,
        opacity: 0.55,
        blur: 14,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(color: AppColors.brand),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 9, 12, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '已记一笔$notePart · ${chatTimeLabel(expense.date, DateTime.now())}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Text(
                          expense.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          money(expense.amount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.brand,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onEdit,
                          behavior: HitTestBehavior.opaque,
                          child: const Text('改一下',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.brand)),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onDelete,
                          behavior: HitTestBehavior.opaque,
                          child: const Text('撤销',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.brand)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 关键词没认出分类时的兜底：淡琥珀玻璃卡，点一下就归好
class CategoryPickerCard extends StatefulWidget {
  const CategoryPickerCard({
    super.key,
    required this.amount,
    required this.onPick,
  });

  final double amount;
  final ValueChanged<String> onPick;

  @override
  State<CategoryPickerCard> createState() => _CategoryPickerCardState();
}

class _CategoryPickerCardState extends State<CategoryPickerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final List<String> shown =
        _expanded ? kCategories : kCategories.take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBox(
        radius: 12,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
        tint: AppColors.accent,
        opacity: 0.16,
        blur: 14,
        solidColor: AppColors.accentSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '记下 ${money(widget.amount)} 了，这是哪一类？',
              style: const TextStyle(fontSize: 11, color: AppColors.accent),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                ...shown.map((String c) => _pill(c, () => widget.onPick(c))),
                if (!_expanded)
                  _pill('更多', () => setState(() => _expanded = true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border.all(
                color: Colors.white.withOpacity(0.9), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppColors.accent),
          ),
        ),
      );
}

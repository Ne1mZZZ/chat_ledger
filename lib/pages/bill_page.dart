import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/stats.dart';
import '../store/ledger_store.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/expense_editor.dart';
import '../widgets/glass_box.dart';

/// 页面 2 · 账单
/// 玻璃月份胶囊 + 玻璃合计卡 + 按天分组的流水；点任一条弹编辑层。
/// 流水行用「轻量玻璃」（半透明白 + 高光边，不开模糊），列表滑动才不卡。
/// 从统计页点分类进来时，顶部多一个「只看 XX」的筛选标记。
class BillPage extends StatelessWidget {
  const BillPage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: LedgerStore.I,
        builder: (BuildContext context, Widget? child) {
          final LedgerStore s = LedgerStore.I;
          final List<Expense> list = s.billFilter == null
              ? s.monthExpenses
              : s.monthExpenses
                  .where((Expense e) => e.category == s.billFilter)
                  .toList();

          // Dart 的普通 Map 保序，正好按流水倒序自然分组
          final Map<String, List<Expense>> groups = <String, List<Expense>>{};
          for (final Expense e in list) {
            final String key = '${dayLabel(e.date)} ${weekdayLabel(e.date)}';
            groups.putIfAbsent(key, () => <Expense>[]).add(e);
          }

          return Column(
            children: <Widget>[
              _header(s),
              _summary(list),
              if (s.billFilter != null) _filterChip(s),
              Expanded(
                child: groups.isEmpty
                    ? const Center(
                        child: Text(
                          '这个月还没有记录',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.hint),
                        ),
                      )
                    : ListView.builder(
                        // 底部留 96px，避免最后一条被悬浮长条圆导航盖住
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: groups.length,
                        itemBuilder: (BuildContext ctx, int i) {
                          final String key = groups.keys.elementAt(i);
                          return _group(context, key, groups[key]!);
                        },
                      ),
              ),
            ],
          );
        },
      );

  Widget _header(LedgerStore s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              '账单',
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
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.ink),
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
        ),
      );

  Widget _summary(List<Expense> list) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: GlassBox(
          radius: 14,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          tint: AppColors.brand,
          opacity: 0.14,
          blur: 16,
          solidColor: AppColors.brandSoft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('本月合计',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.muted)),
                  Text(
                    money(sumOf(list)),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brandDeep,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.9), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '共 ${list.length} 笔',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.brand),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _filterChip(LedgerStore s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: s.clearBillFilter,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                border: Border.all(
                    color: Colors.white.withOpacity(0.9), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '只看${s.billFilter}　×',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.brand),
              ),
            ),
          ),
        ),
      );

  Widget _group(BuildContext context, String title, List<Expense> items) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 7),
            child: Row(
              children: <Widget>[
                Text(title,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted)),
                const Spacer(),
                Text(money(sumOf(items)),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          ...items.map((Expense e) => _row(context, e)),
        ],
      );

  Widget _row(BuildContext context, Expense e) {
    final CategoryStyle st = e.style;
    return GestureDetector(
      onTap: () => showExpenseEditor(context, e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
        decoration: lightGlassDecoration(),
        child: Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: st.soft,
                border: Border.all(
                    color: Colors.white.withOpacity(0.9), width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(st.icon,
                  style: TextStyle(fontSize: 12, color: st.color)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    e.category,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  if (e.note.isNotEmpty)
                    Text(e.note,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            Text(
              '− ${money(e.amount)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

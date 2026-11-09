import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense.dart';
import '../store/ledger_store.dart';
import '../theme.dart';
import 'glass_box.dart';

/// 编辑弹层：液态玻璃材质，透出底下被压暗的页面和光斑。
/// 点一笔账 → 改金额 / 改分类 / 改备注 / 删除；保存后三页数字同步刷新。
Future<void> showExpenseEditor(BuildContext context, Expense expense) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: ExpenseEditorSheet(expense: expense),
    ),
  );
}

class ExpenseEditorSheet extends StatefulWidget {
  const ExpenseEditorSheet({super.key, required this.expense});

  final Expense expense;

  @override
  State<ExpenseEditorSheet> createState() => _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends State<ExpenseEditorSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late String _category;

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _noteCtrl = TextEditingController(text: widget.expense.note);
    _category = widget.expense.category;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.62),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.hint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(0.85), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(0.85), width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) => GlassBox(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        opacity: 0.78,
        blur: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '改一下这笔',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              decoration: _decoration('金额'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategories.map((String c) {
                final bool selected = c == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brand
                          : Colors.white.withOpacity(0.58),
                      border: Border.all(
                        color: selected
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white.withOpacity(0.85),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: _decoration('备注（可留空）'),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                    final int? id = widget.expense.id;
                    if (id != null) await LedgerStore.I.remove(id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text(
                    '删除这笔',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final double? amount =
                        double.tryParse(_amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入正确的金额')),
                      );
                      return;
                    }
                    await LedgerStore.I.save(widget.expense.copyWith(
                      amount: amount,
                      category: _category,
                      note: _noteCtrl.text.trim(),
                    ));
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/classifier.dart';
import '../services/stats.dart';
import '../store/ledger_store.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/amount_card.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/expense_editor.dart';
import '../widgets/glass_box.dart';

/// 页面 1 · 记账（默认首页）
/// 顶部玻璃主卡 + 中部对话流 + 底部玻璃输入框。
/// 一句话可以记多笔：Classifier.parseAll 会把句子拆成一到多笔，
/// 认不出分类的那些笔排进队列，逐张弹分类卡片让用户点选。
/// 最底下按手机实际底部高度给悬浮长条圆导航留白。
/// 跳转：本月支出 / 日均消费 → 统计页；今日支出 / 查看全部 → 账单页。
class BookkeepingPage extends StatefulWidget {
  const BookkeepingPage({super.key});

  @override
  State<BookkeepingPage> createState() => _BookkeepingPageState();
}

class _BookkeepingPageState extends State<BookkeepingPage> {
  final TextEditingController _ctrl = TextEditingController();

  /// 关键词没认出分类的笔，排队等用户逐张点选，不直接丢弃
  final List<ParseResult> _pendingQueue = <ParseResult>[];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _send() async {
    final String text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final List<ParseResult> results = Classifier.parseAll(text);
    _ctrl.clear();

    // 整句都没金额（没拆出多笔时才会是这一种情况）
    if (results.length == 1 && !results.first.hasAmount) {
      _snack(results.first.hint ?? '没看懂金额');
      return;
    }

    int committed = 0;
    for (final ParseResult r in results) {
      if (!r.hasAmount) continue;
      if (r.needsCategory) {
        _pendingQueue.add(r);
      } else {
        await _commitOne(r);
        committed++;
      }
    }

    if (mounted && (_pendingQueue.isNotEmpty || committed > 1)) {
      setState(() {});
    }
    if (committed > 1) {
      _snack('已记 $committed 笔');
    } else if (_pendingQueue.isNotEmpty) {
      _snack('还有 ${_pendingQueue.length} 笔要点选分类');
    }
  }

  /// 点选分类：提交队列最前面那一笔，然后自动显示下一张
  void _pickCategory(String c) {
    if (_pendingQueue.isEmpty) return;
    final ParseResult picked =
        _pendingQueue.removeAt(0).withCategory(c);
    if (mounted) setState(() {});
    _commitOne(picked);
  }

  Future<void> _commitOne(ParseResult result) async {
    // 句子里写了日期（含「昨天/前天/3天前」）就记到那一天；没写才用当前时间。
    // 补上当前的时分，确认卡片上会显示「11月20日 13:52」而不是 00:00。
    final DateTime? picked = result.date;
    final DateTime now = DateTime.now();
    final DateTime date = picked == null
        ? now
        : DateTime(picked.year, picked.month, picked.day, now.hour, now.minute);
    final Expense e = Expense(
      amount: result.amount!,
      category: result.category ?? '其他',
      note: result.note,
      rawText: result.rawText,
      date: date,
    );
    await LedgerStore.I.add(e);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: LedgerStore.I,
        builder: (BuildContext context, Widget? child) {
          final LedgerStore s = LedgerStore.I;
          final DateTime now = DateTime.now();
          final double monthTotal = sumOf(s.monthExpenses);
          final double todayTotal = sumOf(s.monthExpenses.where(
            (Expense e) =>
                e.date.year == now.year &&
                e.date.month == now.month &&
                e.date.day == now.day,
          ));
          final double avg = dailyAverage(monthTotal, s.month, now: now);

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: <Widget>[
                    _greeting(now),
                    const SizedBox(height: 14),
                    AmountCard(
                      label: '本月支出',
                      amount: money(monthTotal),
                      leftLabel: '日均消费',
                      leftValue: money(avg),
                      rightLabel: '今日支出',
                      rightValue: money(todayTotal),
                      onAmountTap: () => s.goToTab(2),
                      onLeftTap: () => s.goToTab(2),
                      onRightTap: () => s.goToTab(1),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: <Widget>[
                    const Text(
                      '最近记录',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => s.goToTab(1),
                      child: const Text(
                        '查看全部 ›',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.brand),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildConversation(s)),
              _buildComposer(),
              // 按手机实际底部高度给悬浮导航留白，输入框才不会和导航叠在一起
              SizedBox(height: navReservedHeight(context)),
            ],
          );
        },
      );

  Widget _greeting(DateTime now) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${dayLabel(now)} ${weekdayLabel(now)}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              const Text(
                '你好，今天记一笔吧',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          GlassBox(
            radius: 15,
            width: 30,
            height: 30,
            padding: EdgeInsets.zero,
            opacity: 0.5,
            blur: 12,
            child: const Center(
              child: Text(
                '记',
                style: TextStyle(fontSize: 12, color: AppColors.brand),
              ),
            ),
          ),
        ],
      );

  Widget _buildConversation(LedgerStore s) {
    if (s.recent.isEmpty && _pendingQueue.isEmpty) {
      return const Center(
        child: Text(
          '还没有记录，发一句话试试',
          style: TextStyle(fontSize: 13, color: AppColors.hint),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: <Widget>[
        if (_pendingQueue.isNotEmpty) ...<Widget>[
          UserBubble(text: _pendingQueue.first.rawText),
          CategoryPickerCard(
            amount: _pendingQueue.first.amount!,
            onPick: _pickCategory,
          ),
          if (_pendingQueue.length > 1)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                '还有其它笔待选分类',
                style: TextStyle(fontSize: 11, color: AppColors.hint),
              ),
            ),
        ],
        // 最新的排在最上面，和「最近记录」的语义一致
        ...s.recent.map((Expense e) => _record(e, s)),
      ],
    );
  }

  Widget _record(Expense e, LedgerStore s) => Column(
        children: <Widget>[
          UserBubble(
            text: e.rawText.isEmpty
                ? '${e.category} ${money(e.amount)}'
                : e.rawText,
          ),
          ConfirmCard(
            expense: e,
            onEdit: () => showExpenseEditor(context, e),
            onDelete: () async {
              final int? id = e.id;
              if (id != null) await s.remove(id);
            },
          ),
        ],
      );

  Widget _buildComposer() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: GlassBox(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                opacity: 0.62,
                blur: 16,
                shadow: false, // 别让输入框投影和导航投影叠在一起发糊
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.ink),
                  decoration: const InputDecoration(
                    hintText: '一句话可记多笔，如「午饭 35 打车 20」',
                    hintStyle:
                        TextStyle(fontSize: 11, color: AppColors.hint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xE6185FA5), Color(0xCC0C447C)],
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.arrow_upward,
                    size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}

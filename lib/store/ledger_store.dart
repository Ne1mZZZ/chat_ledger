import 'package:flutter/foundation.dart';

import '../data/expense_db.dart';
import '../models/expense.dart';
import '../services/stats.dart';

/// 全局状态：用 Flutter 自带的 ChangeNotifier，不引入 provider / riverpod 等库。
/// 任何一笔账增删改后调 refresh()，三个页面的数字和列表会一起刷新。
/// 跨页跳转（首页点数字、统计点分类）也放这里，避免页面之间互相传值。
class LedgerStore extends ChangeNotifier {
  LedgerStore._();
  static final LedgerStore I = LedgerStore._();

  final ExpenseDb _db = ExpenseDb.instance;

  /// 对话页显示的最近 30 条
  List<Expense> recent = <Expense>[];

  /// 账单页 / 统计页：当前选中月份的数据
  List<Expense> monthExpenses = <Expense>[];

  /// 统计页「近 6 个月」用的数据（一次查 6 个月，不用查全表）
  List<Expense> trendExpenses = <Expense>[];

  int tabIndex = 0; // 0 记账 / 1 账单 / 2 统计
  String? billFilter; // 从统计页点分类过来时，账单页只显示这一类
  DateTime month = monthStart(DateTime.now());

  Future<void> init() => refresh();

  Future<void> refresh() async {
    // 从 5 个月前的月初，查到下个月月初
    final DateTime from = shiftMonth(month, -5);
    final DateTime to = nextMonthStart(month);
    recent = await _db.queryRecent();
    monthExpenses = await _db.queryRange(monthStart(month), to);
    trendExpenses = await _db.queryRange(from, to);
    notifyListeners();
  }

  Future<void> add(Expense e) async {
    await _db.insert(e);
    await refresh();
  }

  Future<void> save(Expense e) async {
    await _db.update(e);
    await refresh();
  }

  Future<void> remove(int id) async {
    await _db.delete(id);
    await refresh();
  }

  void goToTab(int index) {
    tabIndex = index;
    if (index != 1) billFilter = null;
    notifyListeners();
  }

  /// 统计页点某个分类 → 跳账单页并只显示这一类
  void goToBillsFiltered(String category) {
    billFilter = category;
    tabIndex = 1;
    notifyListeners();
  }

  void clearBillFilter() {
    billFilter = null;
    notifyListeners();
  }

  Future<void> shiftFocusMonth(int delta) async {
    month = shiftMonth(month, delta);
    billFilter = null;
    await refresh();
  }
}

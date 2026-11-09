import '../models/expense.dart';

/// 统计业务逻辑层：只做纯计算，不碰界面、不碰数据库。
/// 这样口径改起来只要改这一个文件。

DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// 下个月 1 号。用 DateTime(year, month + 1, 1) 会自动跨年，不用担心 12 月
DateTime nextMonthStart(DateTime d) => DateTime(d.year, d.month + 1, 1);

DateTime shiftMonth(DateTime d, int delta) =>
    DateTime(d.year, d.month + delta, 1);

/// 某个月总天数：下个月 1 号往前退 0 天 = 本月最后一天
int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

double sumOf(Iterable<Expense> items) =>
    items.fold<double>(0.0, (double sum, Expense e) => sum + e.amount);

/// 【用户确认的口径】日均消费 = 当月总支出 ÷ 当月已过天数。
/// - 看的是「当前月」：已过天数 = 今天几号（含今天），
///   例：11 月 9 号花了 384 元 → 384 ÷ 9 = 42.67，月初不会被 30 天摊薄。
/// - 看的是「历史月份」：用该月完整天数（30/31/28/29）。
double dailyAverage(double total, DateTime month, {DateTime? now}) {
  final DateTime today = now ?? DateTime.now();
  final bool isCurrentMonth =
      today.year == month.year && today.month == month.month;
  final int days = isCurrentMonth ? today.day : daysInMonth(month);
  return total / (days < 1 ? 1 : days);
}

/// 上月日均，用于统计页那句「比上月日均少 ¥6.20」
double previousMonthAverage(List<Expense> all, DateTime anchor) {
  final DateTime prev = shiftMonth(monthStart(anchor), -1);
  final double total = sumOf(all.where(
    (Expense e) => e.date.year == prev.year && e.date.month == prev.month,
  ));
  return total / daysInMonth(prev);
}

class CategoryShare {
  final String category;
  final double amount;
  final double ratio; // 0~1

  const CategoryShare({
    required this.category,
    required this.amount,
    required this.ratio,
  });
}

/// 分类占比，从高到低排序
List<CategoryShare> categoryShares(List<Expense> items) {
  if (items.isEmpty) return <CategoryShare>[];
  final Map<String, double> totals = <String, double>{};
  for (final Expense e in items) {
    totals[e.category] = (totals[e.category] ?? 0.0) + e.amount;
  }
  final double total =
      totals.values.fold<double>(0.0, (double a, double b) => a + b);
  if (total <= 0) return <CategoryShare>[];

  final List<CategoryShare> list = totals.entries
      .map((MapEntry<String, double> en) => CategoryShare(
            category: en.key,
            amount: en.value,
            ratio: en.value / total,
          ))
      .toList();
  list.sort((CategoryShare a, CategoryShare b) => b.amount.compareTo(a.amount));
  return list;
}

class MonthPoint {
  final DateTime month;
  final double total;

  const MonthPoint(this.month, this.total);
}

/// 近 6 个月趋势。没记账的月份补 0，柱子上会显示为很矮的一根
List<MonthPoint> monthPoints(
  List<Expense> items,
  DateTime anchor, {
  int count = 6,
}) {
  final Map<int, double> bucket = <int, double>{};
  for (final Expense e in items) {
    final int key = e.date.year * 12 + e.date.month;
    bucket[key] = (bucket[key] ?? 0.0) + e.amount;
  }
  final List<MonthPoint> result = <MonthPoint>[];
  for (int i = count - 1; i >= 0; i--) {
    final DateTime m = shiftMonth(monthStart(anchor), -i);
    final int key = m.year * 12 + m.month;
    result.add(MonthPoint(m, bucket[key] ?? 0.0));
  }
  return result;
}

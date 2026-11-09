import '../theme.dart';

/// V1 固定的 6 个消费分类。用户选了「本地关键词规则」，
/// 所以分类是写死的；V2 做自定义分类时再改成从数据库读。
const List<String> kCategories = <String>[
  '餐饮', '交通', '购物', '娱乐', '居住', '其他'
];

/// 一笔账。
/// rawText 存用户当时发的原话，这样重开 App 对话气泡还在，
/// 不需要额外再建一张「聊天消息表」，省空间也省代码。
class Expense {
  final int? id;
  final double amount;
  final String category;
  final String note;
  final String rawText;
  final DateTime date;

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.rawText,
    required this.date,
  });

  /// 分类对应的颜色/图标，页面层直接取用
  CategoryStyle get style => styleOf(category);

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'raw_text': rawText,
        // 日期存成整数毫秒，方便做「某月区间」查询
        'date': date.millisecondsSinceEpoch,
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?,
        amount: (m['amount'] as num).toDouble(),
        category: (m['category'] as String?) ?? '其他',
        note: (m['note'] as String?) ?? '',
        rawText: (m['raw_text'] as String?) ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
      );

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? note,
    String? rawText,
    DateTime? date,
  }) =>
      Expense(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        note: note ?? this.note,
        rawText: rawText ?? this.rawText,
        date: date ?? this.date,
      );
}

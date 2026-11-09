/// 日期、金额格式化小工具。
/// 故意不引入 intl 包（它会带一份语言数据包，增加体积），
/// 本项目只处理中文，自己写几个函数就够了。

String money(double v) => '¥${v.toStringAsFixed(2)}';

String moneyShort(double v) => '¥${v.toStringAsFixed(0)}';

String monthLabel(DateTime d) => '${d.year}年${d.month}月';

String dayLabel(DateTime d) => '${d.month}月${d.day}日';

const List<String> _weekdays = <String>[
  '周一', '周二', '周三', '周四', '周五', '周六', '周日'
];

String weekdayLabel(DateTime d) => _weekdays[d.weekday - 1];

String timeLabel(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// 对话卡片上的时间：今天只显示时分，更早的显示月日
String chatTimeLabel(DateTime d, DateTime now) {
  final bool sameDay =
      d.year == now.year && d.month == now.month && d.day == now.day;
  return sameDay
      ? '今天 ${timeLabel(d)}'
      : '${dayLabel(d)} ${timeLabel(d)}';
}

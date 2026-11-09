/// 【V1 核心】本地关键词规则分类器。
///
/// 用户已确认：V1 用「本地关键词规则」，不接云端大模型。
/// 好处：完全离线、零费用、零第三方 SDK、包体最小、聊天内容不外传。
/// 代价：只认常见说法；认不出的会请用户点一下分类（见 needsCategory）。
///
/// 以后想升级成云端 AI（V2），只要换掉 Classifier.parse 的实现，
/// 页面层和数据层完全不用改 —— 这里特意留成了唯一入口。

/// 一句话解析的结果
class ParseResult {
  final double? amount;
  final String? category;
  final String note;
  final String rawText;
  final String? hint;

  const ParseResult({
    this.amount,
    this.category,
    required this.note,
    required this.rawText,
    this.hint,
  });

  bool get hasAmount => amount != null;

  /// 金额认出来了，但分类没认出来 → 界面弹分类按钮让用户点一下
  bool get needsCategory => hasAmount && category == null;

  ParseResult withCategory(String picked) => ParseResult(
        amount: amount,
        category: picked,
        note: note,
        rawText: rawText,
      );
}

/// 分类关键词词典。Map 是有序的，命中多个时按下面的先后顺序取第一个。
/// 【AI建议】V2 会让用户自己增删关键词，让分类越用越准。
const Map<String, List<String>> kKeywords = <String, List<String>>{
  '餐饮': <String>[
    '午饭', '午餐', '早饭', '早餐', '晚饭', '晚餐', '夜宵', '外卖',
    '咖啡', '奶茶', '食堂', '餐厅', '火锅', '面包', '零食', '饮料',
    '水果', '吃饭', '星巴克', '麦当劳', '肯德基', '菜', '饭', '吃',
  ],
  '交通': <String>[
    '打车', '出租', '滴滴', '地铁', '公交', '高铁', '火车', '机票',
    '飞机', '加油', '油费', '停车', '过路费', '单车', '车费', '车票',
  ],
  '购物': <String>[
    '超市', '淘宝', '京东', '拼多多', '网购', '商城', '快递', '衣服',
    '鞋', '日用品', '化妆品', '洗发水', '纸巾', '买',
  ],
  '娱乐': <String>[
    '电影', '游戏', '唱歌', 'KTV', '门票', '旅游', '健身', '会员',
    '视频', '音乐', '演出', '桌游', '门票',
  ],
  '居住': <String>[
    '房租', '水电', '电费', '水费', '燃气', '物业', '宽带', '网费',
    '房贷', '家具', '家电', '租金',
  ],
};

class Classifier {
  /// 从任意一句话里抠出第一个数字（支持小数，如 35 / 35.5 / 35.50）
  /// 例：「打车20去公司」→ 20；「午饭 ¥35」→ 35；「35块」→ 35
  static final RegExp _amountRe = RegExp(r'(\d+(?:\.\d{1,2})?)');

  static ParseResult parse(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) {
      return const ParseResult(
        note: '',
        rawText: '',
        hint: '先发一句话吧，例如「午饭 35」',
      );
    }

    final RegExpMatch? match = _amountRe.firstMatch(text);
    if (match == null) {
      return ParseResult(
        note: '',
        rawText: text,
        hint: '没找到金额，试试带上数字，例如「打车 20」',
      );
    }

    final double? amount = double.tryParse(match.group(1)!);
    if (amount == null || amount <= 0) {
      return ParseResult(
        note: '',
        rawText: text,
        hint: '金额看不懂，试试「午饭 35」',
      );
    }

    // 备注 = 原话去掉金额数字，再去掉「元/块/¥」等零碎字符。
    // V1 遵循「一句话 = 一笔账」，句子里有多个数字时只取第一个。
    final String note = text
        .replaceFirst(match.group(0)!, '')
        .replaceAll(RegExp(r'[¥￥元块\s,，。.!！?？、]+'), '')
        .trim();

    String? category;
    for (final MapEntry<String, List<String>> entry in kKeywords.entries) {
      if (entry.value.any((String keyword) => text.contains(keyword))) {
        category = entry.key;
        break;
      }
    }

    return ParseResult(
      amount: amount,
      category: category,
      note: note,
      rawText: text,
    );
  }
}

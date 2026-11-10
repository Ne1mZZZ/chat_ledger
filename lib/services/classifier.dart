/// 【V1 核心】本地关键词规则分类器。
///
/// 用户已确认：V1 用「本地关键词规则」，不接云端大模型。
/// 好处：完全离线、零费用、零第三方 SDK、包体最小、聊天内容不外传。
/// 代价：只认常见说法；认不出的会请用户点一下分类（见 needsCategory）。
///
/// 解析顺序（重要）：
///   1. 先把整句的日期摘出来（11月20 / 2026-11-20 / 20号 / 昨天 / 3天前）
///   2. 把剩下的文字按「金额结构」切成若干段，一段就是一笔
///   3. 每段单独找金额、单独匹配分类关键词（避免「午饭35 打车20」互相串类）
///   4. 段里没写日期就继承整句的日期；段里自带日期则以段内为准
///
/// 这样：
///   「11月20购物花了70」      → 一笔：11/20、70 元、购物
///   「昨天午饭35 打车20」     → 两笔：都是昨天，餐饮 35 / 交通 20
///   「昨天午饭35，前天地铁6」 → 两笔：分别记昨天 / 前天
///
/// 以后想升级成云端 AI（V2），只要换掉 Classifier.parseAll 的实现，
/// 页面层和数据层完全不用改 —— 这里特意留成了唯一入口。

/// 一句话里某一笔的解析结果
class ParseResult {
  final double? amount;
  final String? category;
  final String note;
  final String rawText;
  final String? hint;

  /// 这一笔该记到哪天；没写日期则为 null（页面会退回「今天」）
  final DateTime? date;

  const ParseResult({
    this.amount,
    this.category,
    required this.note,
    required this.rawText,
    this.hint,
    this.date,
  });

  bool get hasAmount => amount != null;

  /// 金额认出来了，但分类没认出来 → 界面弹分类按钮让用户点一下
  bool get needsCategory => hasAmount && category == null;

  ParseResult withCategory(String picked) => ParseResult(
        amount: amount,
        category: picked,
        note: note,
        rawText: rawText,
        hint: hint,
        date: date,
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
    '超市', '淘宝', '京东', '拼多多', '网购', '商城', '购物', '快递', '衣服',
    '鞋', '日用品', '化妆品', '洗发水', '纸巾', '买',
  ],
  '娱乐': <String>[
    '电影', '游戏', '唱歌', 'KTV', '门票', '旅游', '健身', '会员',
    '视频', '音乐', '演出', '桌游',
  ],
  '居住': <String>[
    '房租', '水电', '电费', '水费', '燃气', '物业', '宽带', '网费',
    '房贷', '家具', '家电', '租金',
  ],
};

/// 日期命中结果：日期本身 + 原句里被摘掉的那段文字
class _DateHit {
  final DateTime date;
  final String matched;

  const _DateHit(this.date, this.matched);
}

/// 金额命中结果：金额 + 被认定为金额的那个数字串（用于从备注里剔除）
class _AmountHit {
  final double amount;
  final String matched;

  const _AmountHit(this.amount, this.matched);
}

class Classifier {
  static final RegExp _num = RegExp(r'(\d+(?:\.\d{1,2})?)');
  static final RegExp _hasDigit = RegExp(r'\d');

  // 日期：先长后短，避免 2026-11-20 被「11-20」误拆
  static final RegExp _dateFull = RegExp(
      r'(\d{4})\s*[年\-/\.]\s*(\d{1,2})\s*[月\-/\.]\s*(\d{1,2})\s*[日号]?');
  static final RegExp _dateMonthDay =
      RegExp(r'(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]?');
  static final RegExp _dateSlash = RegExp(r'(\d{1,2})\s*[/\-]\s*(\d{1,2})');
  static final RegExp _dateDay = RegExp(r'(\d{1,2})\s*[日号]');

  // 中文相对日期：值是「往前推几天」。取最靠前的一个词，长词在同位置时优先。
  static const Map<String, int> _relativeDays = <String, int>{
    '大前天': 3,
    '前天': 2, '前日': 2,
    '昨天': 1, '昨日': 1, '昨儿': 1,
    '今天': 0, '今日': 0, '今儿': 0, '当天': 0, '当日': 0,
  };
  static final RegExp _daysAgo = RegExp(r'(\d{1,3})\s*天前');

  // 金额线索：货币符号 > 数字+单位 > 提示词+数字 > 兜底取最后一个数字
  static final RegExp _moneySymbol =
      RegExp(r'[¥￥]\s*(\d+(?:\.\d{1,2})?)');
  static final RegExp _moneyUnit =
      RegExp(r'(\d+(?:\.\d{1,2})?)\s*(?:块钱|元|块|人民币)');
  static final RegExp _moneyHint = RegExp(
      r'(?:花了|花掉|花|用了|用|付了|付|消费|共计|共|合计|计|支出|一共|总共)\s*[¥￥]?\s*(\d+(?:\.\d{1,2})?)');

  // 一句话写多笔时的分隔符：标点、换行、中文连接词
  static final RegExp _hardSplit = RegExp(
      r'[\s]*[,，;；。!！?？\n]+[\s]*|(?:还有|另外|然后|以及|加上|顺手)|\s+和\s+');

  static bool _validDate(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return false;
    final DateTime dt = DateTime(y, m, d);
    // DateTime 会把 2月30日 自动溢到 3月，用回读判断合法性
    return dt.year == y && dt.month == m && dt.day == d;
  }

  /// 从句子里摘出日期。优先绝对日期，其次中文相对日期。
  /// 只写月日时年份取今年；只写「20号」时取本月。
  static _DateHit? _extractDate(String text, DateTime today) {
    final RegExpMatch? f = _dateFull.firstMatch(text);
    if (f != null) {
      final int y = int.parse(f.group(1)!);
      final int m = int.parse(f.group(2)!);
      final int d = int.parse(f.group(3)!);
      if (_validDate(y, m, d)) {
        return _DateHit(DateTime(y, m, d), f.group(0)!);
      }
    }

    final RegExpMatch? md = _dateMonthDay.firstMatch(text);
    if (md != null) {
      final int m = int.parse(md.group(1)!);
      final int d = int.parse(md.group(2)!);
      if (_validDate(today.year, m, d)) {
        return _DateHit(DateTime(today.year, m, d), md.group(0)!);
      }
    }

    final RegExpMatch? sl = _dateSlash.firstMatch(text);
    if (sl != null) {
      final int m = int.parse(sl.group(1)!);
      final int d = int.parse(sl.group(2)!);
      if (_validDate(today.year, m, d)) {
        return _DateHit(DateTime(today.year, m, d), sl.group(0)!);
      }
    }

    final RegExpMatch? dd = _dateDay.firstMatch(text);
    if (dd != null) {
      final int d = int.parse(dd.group(1)!);
      if (_validDate(today.year, today.month, d)) {
        return _DateHit(DateTime(today.year, today.month, d), dd.group(0)!);
      }
    }

    // 相对日期：取出现位置最靠前的那个词；同位置时取更长的词
    // （「大前天」不能被「前天」抢先，「前天打车20」也不能盖掉句首的「昨天」）
    int bestStart = 1 << 30;
    String bestWord = '';
    int bestDays = 0;
    for (final MapEntry<String, int> e in _relativeDays.entries) {
      final int idx = text.indexOf(e.key);
      if (idx < 0) continue;
      if (idx < bestStart ||
          (idx == bestStart && e.key.length > bestWord.length)) {
        bestStart = idx;
        bestWord = e.key;
        bestDays = e.value;
      }
    }
    final RegExpMatch? ago = _daysAgo.firstMatch(text);
    if (ago != null) {
      final int n = int.parse(ago.group(1)!);
      final String word = ago.group(0)!;
      if (n > 0 &&
          n <= 365 &&
          (ago.start < bestStart ||
              (ago.start == bestStart && word.length > bestWord.length))) {
        bestStart = ago.start;
        bestWord = word;
        bestDays = n;
      }
    }
    if (bestWord.isNotEmpty) {
      // DateTime 支持 day 为 0 / 负数，会自动回退到上个月，跨月也正确
      return _DateHit(
          DateTime(today.year, today.month, today.day - bestDays), bestWord);
    }
    return null;
  }

  static double? _toAmount(String? s) {
    final double? v = double.tryParse(s ?? '');
    return (v == null || v <= 0) ? null : v;
  }

  /// 在「已去掉日期」的文字里找金额。
  /// 兜底取最后一个数字而不是第一个：口语里金额通常压在句尾。
  static _AmountHit? _extractAmount(String clean) {
    final RegExpMatch? a = _moneySymbol.firstMatch(clean);
    final double? va = _toAmount(a?.group(1));
    if (a != null && va != null) return _AmountHit(va, a.group(1)!);

    final RegExpMatch? b = _moneyUnit.firstMatch(clean);
    final double? vb = _toAmount(b?.group(1));
    if (b != null && vb != null) return _AmountHit(vb, b.group(1)!);

    final RegExpMatch? c = _moneyHint.firstMatch(clean);
    final double? vc = _toAmount(c?.group(1));
    if (c != null && vc != null) return _AmountHit(vc, c.group(1)!);

    final List<RegExpMatch> all = _num.allMatches(clean).toList();
    if (all.isNotEmpty) {
      final String last = all.last.group(1)!;
      final double? v = _toAmount(last);
      if (v != null) return _AmountHit(v, last);
    }
    return null;
  }

  /// 一个片段内按「描述词 → 金额」切成若干笔。
  /// 中文口语的常见形态：
  ///   午饭 35 打车 20   → ["午饭 35", "打车 20"]
  ///   午饭35 打车20     → ["午饭35", "打车20"]
  ///   ¥35 咖啡 ¥20 奶茶 → ["¥35 咖啡", "¥20 奶茶"]（金额在前时允许后置描述）
  /// 关键规则：一段收到金额后，下一个 token 就开新段；只有「¥/元/块」开头的
  /// 金额才允许后面再跟一个纯文字描述，否则「午饭 35 打车 20」会被切错。
  static List<String> _splitByAmountTokens(String chunk) {
    final List<String> tokens = chunk
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();
    if (tokens.length < 2) return <String>[chunk];

    final List<String> out = <String>[];
    final List<String> cur = <String>[];
    bool pendingCut = false; // 当前段刚收到金额
    bool amountLeading = false; // 这个金额是「¥35 / 35元」这种前置形式

    for (final String t in tokens) {
      final bool hasNum = _hasDigit.hasMatch(t);
      if (pendingCut) {
        if (!hasNum && amountLeading) {
          // 前置金额后面跟的描述词，并进同一笔
          cur.add(t);
          out.add(cur.join(' '));
        } else {
          out.add(cur.join(' '));
          cur.clear();
          cur.add(t);
          amountLeading = false;
          pendingCut = hasNum;
          if (hasNum) {
            amountLeading = _moneySymbol.hasMatch(t) || _moneyUnit.hasMatch(t);
          }
          continue;
        }
        cur.clear();
        pendingCut = false;
        amountLeading = false;
        continue;
      }
      cur.add(t);
      if (hasNum) {
        pendingCut = true;
        amountLeading = _moneySymbol.hasMatch(t) || _moneyUnit.hasMatch(t);
      }
    }
    if (cur.isNotEmpty) out.add(cur.join(' '));
    return out.isEmpty ? <String>[chunk] : out;
  }

  /// 把整句切成若干笔。先按标点/连接词切，再在每个片段内按金额结构切。
  /// 没有数字的碎片（如「去公司」「和」）合并到相邻段，不单独成笔。
  static List<String> _splitSegments(String body) {
    final List<String> chunks = body
        .split(_hardSplit)
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();

    final List<String> rawSegs = <String>[];
    for (final String chunk in chunks) {
      rawSegs.addAll(_splitByAmountTokens(chunk));
    }

    final List<String> segs = <String>[];
    String carry = '';
    for (final String seg in rawSegs) {
      if (!_hasDigit.hasMatch(seg)) {
        carry = carry.isEmpty ? seg : '$carry $seg';
        continue;
      }
      segs.add(carry.isEmpty ? seg : '$carry $seg');
      carry = '';
    }
    if (carry.isNotEmpty && segs.isNotEmpty) {
      segs[segs.length - 1] = '${segs.last} $carry';
    }
    return segs.isEmpty ? <String>[body.trim()] : segs;
  }

  /// 解析单笔（一个片段）。
  static ParseResult _parseOne(
    String segment, {
    required String rawText,
    DateTime? inherited,
    required DateTime now,
  }) {
    final String seg = segment.trim();
    final _DateHit? local = _extractDate(seg, now);
    final DateTime? date = local?.date ?? inherited;
    final String clean =
        local == null ? seg : seg.replaceFirst(local.matched, ' ');

    final _AmountHit? amountHit = _extractAmount(clean);
    if (amountHit == null) {
      return ParseResult(
        note: '',
        rawText: rawText,
        date: date,
        hint: '没找到金额，试试带上数字，例如「打车 20」',
      );
    }

    // 备注：去掉金额数字、货币单位、金额提示词和标点
    String note = clean.replaceFirst(amountHit.matched, ' ');
    note = note.replaceAll(
        RegExp(r'[¥￥]|块钱|人民币|元|块|花了|花掉|用了|付了|一共|总共|共计|合计|消费|支出|花|用|付|共'),
        ' ');
    // 注意不要把「月/日/号」当脏字删掉，否则「这个月房租」会被削成「这个房租」
    note = note.replaceAll(RegExp(r'[\s,，。.!！?？、:：;；/\-]+'), '').trim();
    // 「35块的咖啡」这类助词，只清首尾，不动词中间
    note = note.replaceAll(RegExp(r'^的+|的+$'), '');

    // 分类只在这笔自己的文字里匹配，避免多笔之间互相串类
    String? category;
    for (final MapEntry<String, List<String>> entry in kKeywords.entries) {
      if (entry.value.any((String keyword) => clean.contains(keyword))) {
        category = entry.key;
        break;
      }
    }

    return ParseResult(
      amount: amountHit.amount,
      category: category,
      note: note,
      rawText: rawText,
      date: date,
    );
  }

  /// 主入口：一句话 → 一到多笔。
  /// 只有「切出来的每一段都认出了金额」才认作多笔；否则退回整句单笔，
  /// 避免把「3个人吃饭花了210」这类句子误拆成两笔。
  static List<ParseResult> parseAll(String raw, {DateTime? now}) {
    final String text = raw.trim();
    final DateTime today = now ?? DateTime.now();
    if (text.isEmpty) {
      return <ParseResult>[
        const ParseResult(
          note: '',
          rawText: '',
          hint: '先发一句话吧，例如「午饭 35」',
        ),
      ];
    }

    final _DateHit? global = _extractDate(text, today);
    final String body =
        global == null ? text : text.replaceFirst(global.matched, ' ');
    final List<String> segs = _splitSegments(body);
    final List<ParseResult> results = <ParseResult>[];
    for (final String seg in segs) {
      results.add(_parseOne(
        seg,
        rawText: seg,
        inherited: global?.date,
        now: today,
      ));
    }

    if (results.length > 1 &&
        results.any((ParseResult r) => !r.hasAmount)) {
      return <ParseResult>[
        _parseOne(body, rawText: text, inherited: global?.date, now: today),
      ];
    }
    return results;
  }

  /// 兼容旧调用：只取第一笔。页面已改用 parseAll。
  static ParseResult parse(String raw, {DateTime? now}) =>
      parseAll(raw, now: now).first;
}

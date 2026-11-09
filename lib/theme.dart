import 'package:flutter/material.dart';

/// 【UI 定稿 · 靛蓝冷白】全 App 唯一定义颜色的地方。
/// 想换配色只改这里，页面代码一行都不用动。
class AppColors {
  static const Color brand = Color(0xFF185FA5); // 主色：靛蓝
  static const Color brandDeep = Color(0xFF0C447C); // 深靛蓝：强调数字
  static const Color brandSoft = Color(0xFFE6F1FB); // 浅蓝底：小结卡
  static const Color accent = Color(0xFFBA7517); // 点缀：暖琥珀
  static const Color accentSoft = Color(0xFFFAEEDA); // 浅琥珀底：兜底提示
  static const Color screen = Color(0xFFF6F9FC); // 屏幕底色：冷白
  static const Color card = Colors.white;
  static const Color ink = Color(0xFF2C2C2A); // 主要文字
  static const Color muted = Color(0xFF5F5E5A); // 次要文字
  static const Color hint = Color(0xFF888780); // 占位提示
  static const Color line = Color(0xFFE6EAF0); // 细分隔线
  static const Color track = Color(0xFFF1EFE8); // 进度条底槽
}

/// 每个消费分类的「主色 + 浅底 + 汉字图标」，纯代码绘制，零图片资源
class CategoryStyle {
  final Color color;
  final Color soft;
  final String icon;

  const CategoryStyle(this.color, this.soft, this.icon);
}

const Map<String, CategoryStyle> kCategoryStyles = <String, CategoryStyle>{
  '餐饮': CategoryStyle(Color(0xFFEF9F27), Color(0xFFFAEEDA), '食'),
  '交通': CategoryStyle(Color(0xFF378ADD), Color(0xFFE6F1FB), '行'),
  '购物': CategoryStyle(Color(0xFF7F77DD), Color(0xFFEEEDFE), '购'),
  '娱乐': CategoryStyle(Color(0xFFD4537E), Color(0xFFFBEAF0), '玩'),
  '居住': CategoryStyle(Color(0xFF1D9E75), Color(0xFFE1F5EE), '住'),
  '其他': CategoryStyle(Color(0xFF888780), Color(0xFFF1EFE8), '·'),
};

/// 取分类样式；遇到未知分类自动落到「其他」，不会崩
CategoryStyle styleOf(String category) =>
    kCategoryStyles[category] ?? kCategoryStyles['其他']!;

class AppTheme {
  /// 【液态玻璃总开关】低端机如果滑动掉帧，把这里改成 false，
  /// 全 App 会一键降级成纯色扁平卡片（模糊层完全不创建）。
  static const bool useGlass = true;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.screen,
        primaryColor: AppColors.brand,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
        // 页面内所有组件都显式用 AppColors，不依赖系统默认配色，
        // 这样 Android / iOS 两端看起来完全一致
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.screen,
          foregroundColor: AppColors.ink,
          elevation: 0,
        ),
      );
}

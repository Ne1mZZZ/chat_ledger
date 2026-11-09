import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// 【液态玻璃】毛玻璃容器。
///
/// 原理：先对背后的画面做高斯模糊（BackdropFilter + ImageFilter.blur），
/// 再叠一层半透明渐变，最后加 1px 白色高光描边和一层很淡的投影。
/// 全部用 Flutter 自带能力，零第三方包、零图片资源，不增加安装包体积。
///
/// 前提：底下要有东西可透。MainShell 会在整页最底层铺 GlassBackground 的
/// 柔和彩色光斑，玻璃才有「液态」的通透感。
///
/// 性能取舍：模糊是 GPU 实时计算，低端机列表快速滑动时可能掉帧。
/// 所以只给「主卡 / 导航 / 小结卡 / 弹层 / 输入框」这种少量大块加真玻璃；
/// 列表里的每一行改用「半透明白 + 高光描边」的轻量玻璃感，不额外开模糊。
/// 想整机降级，把 AppTheme.useGlass 改成 false 即可，一处开关全局生效。
class GlassBox extends StatelessWidget {
  const GlassBox({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(14),
    this.tint = Colors.white,
    this.opacity = 0.42,
    this.blur = 18,
    this.highlight = 0.7,
    this.shadow = true,
    this.width,
    this.height,
    this.solidColor,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color tint;
  final double opacity;
  final double blur;
  final double highlight;
  final bool shadow;
  final double? width;
  final double? height;

  /// 关闭玻璃时用的纯色；不传就用白色
  final Color? solidColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = BorderRadius.circular(radius);

    final BoxDecoration decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          tint.withOpacity(opacity),
          tint.withOpacity((opacity * 0.35).clamp(0.0, 1.0).toDouble()),
        ],
      ),
      borderRadius: r,
      border: Border.all(
        color: Colors.white.withOpacity(highlight),
        width: 1,
      ),
    );

    final Widget card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: AppTheme.useGlass
          ? decoration
          : BoxDecoration(
              color: solidColor ?? Colors.white,
              borderRadius: r,
              border: Border.all(color: AppColors.line, width: 0.5),
            ),
      child: child,
    );

    // 降级模式：直接返回纯色卡片，完全不创建 BackdropFilter
    if (!AppTheme.useGlass) return card;

    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: shadow
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0x1A0C447C),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      // 阴影放外层，避免被 ClipRRect 裁掉
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: card,
        ),
      ),
    );
  }
}

/// 玻璃背后的彩色光斑：4 个径向渐变的大圆，纯代码绘制。
/// 没有光斑就没有可透视的内容，毛玻璃看起来会跟普通半透明色块没区别。
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          Container(color: AppColors.screen),
          Positioned(
            top: -70,
            left: -60,
            child: _blob(240, AppColors.brand.withOpacity(0.34)),
          ),
          Positioned(
            top: 170,
            right: -90,
            child: _blob(250, const Color(0xFF7F77DD).withOpacity(0.26)),
          ),
          Positioned(
            bottom: 70,
            left: -70,
            child: _blob(230, const Color(0xFF5DCAA5).withOpacity(0.24)),
          ),
          Positioned(
            top: 400,
            left: 100,
            child: _blob(170, const Color(0xFFEF9F27).withOpacity(0.18)),
          ),
        ],
      );

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withOpacity(0)],
          ),
        ),
      );
}

/// 轻量玻璃感：半透明白 + 高光描边，不开模糊。
/// 给账单列表这种会反复重建的行用，滑动不卡。
BoxDecoration lightGlassDecoration({double radius = 12}) => BoxDecoration(
      color: Colors.white.withOpacity(0.52),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
    );

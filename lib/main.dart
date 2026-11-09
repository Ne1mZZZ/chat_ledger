import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/main_shell.dart';
import 'store/ledger_store.dart';
import 'theme.dart';

Future<void> main() async {
  // sqflite 是原生插件，用之前必须先确保 Flutter 引擎绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  // V1 只做竖屏，界面更简单，也少一套横屏适配
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  // 打开本地数据库并读第一屏数据，之后才显示界面
  await LedgerStore.I.init();
  runApp(const ChatLedgerApp());
}

class ChatLedgerApp extends StatelessWidget {
  const ChatLedgerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '一句话记账',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainShell(),
      );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app.dart';
import 'providers/game_provider.dart';
import 'providers/player_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/score_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => ScoreProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const WordChainBattleApp(),
    ),
  );
}

class WordChainBattleApp extends StatelessWidget {
  const WordChainBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // 모바일 기준 디자인 사이즈
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return const MyApp();
          },
        );
      },
    );
  }
}

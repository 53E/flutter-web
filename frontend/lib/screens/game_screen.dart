import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 실제 게임은 홈 화면에서 처리되므로 홈으로 리다이렉트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/');
    });
    
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF50E3C2),
        ),
      ),
    );
  }
}

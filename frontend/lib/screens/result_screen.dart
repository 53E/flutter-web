import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/score_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _nameSubmitted = false;
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scoreProvider = Provider.of<ScoreProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 게임 오버 메시지
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 1000.ms).scale(begin: const Offset(0.5, 0.5)),
              
              const SizedBox(height: 30),
              
              // 점수 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF50E3C2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF50E3C2).withOpacity(0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'FINAL SCORE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '1,500', // 실제 점수는 scoreProvider에서 가져올 예정
                      style: const TextStyle(
                        color: Color(0xFF50E3C2),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 800.ms).slideY(begin: 0.3),
              
              const SizedBox(height: 40),
              
              // 이름 입력 또는 완료 메시지
              if (!_nameSubmitted) ...[
                const Text(
                  '랭킹에 등록할 이름을 입력하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ).animate().fadeIn(delay: 1000.ms),
                
                const SizedBox(height: 20),
                
                // 이름 입력창
                SizedBox(
                  width: size.width * 0.3,
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: '이름을 입력하세요',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF16213E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Color(0xFF50E3C2), width: 2),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms, duration: 800.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 30),
                
                // 등록 버튼
                ElevatedButton(
                  onPressed: _submitName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50E3C2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  child: const Text(
                    '랭킹 등록',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ).animate().fadeIn(delay: 1400.ms, duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),
              ] else ...[
                // 등록 완료 메시지
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Color(0xFF50E3C2),
                    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.3, 0.3)),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      '랭킹에 등록되었습니다!',
                      style: TextStyle(
                        color: Color(0xFF50E3C2),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    
                    const SizedBox(height: 30),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('다시 하기'),
                        ),
                        
                        const SizedBox(width: 20),
                        
                        ElevatedButton(
                          onPressed: () {
                            // 랭킹 화면으로 이동 (추후 구현)
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF50E3C2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('랭킹 보기'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms, duration: 800.ms).slideY(begin: 0.3),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _submitName() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름을 입력해주세요'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }
    
    setState(() {
      _nameSubmitted = true;
    });
    
    // 실제로는 여기서 랭킹에 점수와 이름을 저장
    // scoreProvider.submitScore(_nameController.text.trim());
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

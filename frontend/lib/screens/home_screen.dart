import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _gameStarted = false;
  bool _gameOver = false;
  bool _showRanking = false;
  bool _showDictionary = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wordController = TextEditingController();
  final FocusNode _wordFocusNode = FocusNode();
  bool _nameSubmitted = false;
  
  late AnimationController _timerController;
  late AnimationController _wordSlideController;
  
  List<String> _wordHistory = [];
  int _totalWordsSubmitted = 0;
  
  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(seconds: 5), // 테스트용 5초로 단축
      vsync: this,
    );
    _wordSlideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // 타이머 완료 시 게임 오버 리스너 등록
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && _gameStarted && !_gameOver) {
        setState(() {
          _gameOver = true;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // 배경 그라디언트
          Container(
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
          ),
          
          // 메인 UI
          if (_showRanking)
            _buildRankingUI(size)
          else if (_showDictionary)
            _buildDictionaryUI(size)
          else if (!_gameStarted) 
            _buildMainMenu(size) 
          else if (_gameOver) 
            _buildGameOverUI(size)
          else 
            _buildGameUI(size),
        ],
      ),
    );
  }
  
  Widget _buildMainMenu(Size size) {
    return Stack(
      children: [
        // 타이틀
        if (!_showRanking && !_showDictionary)
          Positioned(
            top: size.height * 0.15,
            left: 0,
            right: 0,
            child: Text(
              '끝말잇기 대전',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width < 600 ? 32 : 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 1000.ms).slideY(begin: -0.5, end: 0),
          ),
        
        // 플레이어 캐릭터 (왼쪽에서 등장)
        if (!_showRanking && !_showDictionary)
          Positioned(
            left: size.width * 0.05,
            top: size.height * 0.3,
            child: Container(
              width: size.width < 600 ? 150 : 200,
              height: size.width < 600 ? 180 : 250,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: size.width < 600 ? 60 : 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PLAYER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 600 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().slideX(
              begin: _showRanking || _showDictionary ? -2.0 : -2.0,
              end: _showRanking || _showDictionary ? -2.0 : 0,
              duration: 1500.ms,
              curve: Curves.elasticOut,
            ).fadeIn(duration: _showRanking || _showDictionary ? 0.ms : 800.ms),
          ),
        
        // 적 캐릭터 (오른쪽에서 등장)
        if (!_showRanking && !_showDictionary)
          Positioned(
            right: size.width * 0.05,
            top: size.height * 0.3,
            child: Container(
              width: size.width < 600 ? 150 : 200,
              height: size.width < 600 ? 180 : 250,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      size: size.width < 600 ? 60 : 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'AI ENEMY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 600 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().slideX(
              begin: _showRanking || _showDictionary ? 2.0 : 2.0,
              end: _showRanking || _showDictionary ? 2.0 : 0,
              duration: 1500.ms,
              curve: Curves.elasticOut,
            ).fadeIn(duration: _showRanking || _showDictionary ? 0.ms : 800.ms),
          ),
        
        // 중앙 버튼들
        if (!_showRanking && !_showDictionary)
          Positioned(
            left: 0,
            right: 0,
            top: size.height * 0.7,
            child: Column(
              children: [
                // 시작 버튼
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50E3C2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width < 600 ? 30 : 50, 
                      vertical: 15
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  child: Text(
                    '게임 시작',
                    style: TextStyle(
                      fontSize: size.width < 600 ? 20 : 24, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ).animate().fadeIn(delay: 2000.ms, duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),
                
                const SizedBox(height: 20),
                
                // 랭킹 버튼
                ElevatedButton(
                  onPressed: _showRankingScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width < 600 ? 30 : 50, 
                      vertical: 15
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  child: Text(
                    '랭킹 보기',
                    style: TextStyle(
                      fontSize: size.width < 600 ? 20 : 24, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ).animate().fadeIn(delay: 2200.ms, duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),
                
                const SizedBox(height: 20),
                
                // 도감 버튼
                ElevatedButton(
                  onPressed: _showDictionaryScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width < 600 ? 30 : 50, 
                      vertical: 15
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  child: Text(
                    '적 도감',
                    style: TextStyle(
                      fontSize: size.width < 600 ? 20 : 24, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ).animate().fadeIn(delay: 2400.ms, duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildGameUI(Size size) {
    return Stack(
      children: [
        // 플레이어 캐릭터 (왼쪽 하단)
        Positioned(
          left: size.width * 0.03,
          bottom: size.height * 0.15,
          child: Container(
            width: size.width < 600 ? 100 : 120,
            height: size.width < 600 ? 120 : 150,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person, 
                    size: size.width < 600 ? 40 : 50, 
                    color: Colors.white
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'PLAYER',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: size.width < 600 ? 10 : 12, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ).animate().slideY(
            begin: -1.5, 
            end: 0,
            duration: 1200.ms, 
            curve: Curves.elasticOut
          ).fadeIn(duration: 800.ms),
        ),
        
        // 적 캐릭터 (오른쪽 하단)
        Positioned(
          right: size.width * 0.03,
          bottom: size.height * 0.15,
          child: Container(
            width: size.width < 600 ? 100 : 120,
            height: size.width < 600 ? 120 : 150,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_toy, 
                    size: size.width < 600 ? 40 : 50, 
                    color: Colors.white
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: size.width < 600 ? 10 : 12, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ).animate().slideY(
            begin: -1.5, 
            end: 0,
            duration: 1200.ms, 
            curve: Curves.elasticOut
          ).fadeIn(duration: 800.ms),
        ),
        
        // 타이머 바 (중앙 상단)
        Positioned(
          top: size.height * 0.08,
          left: size.width * 0.1,
          right: size.width * 0.1,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnimatedBuilder(
                animation: _timerController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: 1.0 - _timerController.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timerController.value < 0.3 
                        ? const Color(0xFF50E3C2)
                        : _timerController.value < 0.7
                          ? Colors.orange
                          : const Color(0xFFFF6B6B),
                    ),
                  );
                },
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 800.ms).slideY(begin: -0.5),
        ),
        
        // 점수 (우상단)
        Positioned(
          top: size.height * 0.12,
          right: size.width * 0.03,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width < 600 ? 15 : 20, 
              vertical: size.width < 600 ? 8 : 10
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Text(
              'SCORE: 1500',
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width < 600 ? 14 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 800.ms).slideX(begin: 1.0),
        ),
        
        // 단어 표시 영역 (중앙)
        Positioned(
          top: size.height * 0.25,
          left: size.width * 0.1,
          right: size.width * 0.1,
          child: AnimatedBuilder(
            animation: _wordSlideController,
            builder: (context, child) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: size.width < 600 ? 8 : 15,
                children: _buildWordSlots(size),
              );
            },
          ).animate().fadeIn(delay: 900.ms, duration: 800.ms).slideY(begin: -0.3),
        ),
        
        // 입력창 (중앙 하단)
        Positioned(
          bottom: size.height * 0.05,
          left: size.width * 0.1,
          right: size.width * 0.1,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width < 600 ? 15 : 20, 
              vertical: size.width < 600 ? 12 : 15
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFF50E3C2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF50E3C2).withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: TextField(
              controller: _wordController,
              focusNode: _wordFocusNode,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white, 
                fontSize: size.width < 600 ? 16 : 18
              ),
              decoration: InputDecoration(
                hintText: '단어를 입력하세요...',
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.send, 
                    color: const Color(0xFF50E3C2),
                    size: size.width < 600 ? 20 : 24,
                  ),
                  onPressed: _submitWord,
                ),
              ),
              onSubmitted: (_) => _submitWord(),
            ),
          ).animate().fadeIn(delay: 1100.ms, duration: 800.ms).slideY(begin: 1.0),
        ),
      ],
    );
  }
  
  Widget _buildWordBlock(String word, bool isCurrent, Size size) {
    bool isEmpty = word.isEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.symmetric(
        horizontal: size.width < 600 ? 12 : 20, 
        vertical: size.width < 600 ? 10 : 15
      ),
      decoration: BoxDecoration(
        color: isEmpty 
          ? Colors.transparent 
          : isCurrent 
            ? const Color(0xFF50E3C2) 
            : const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isEmpty 
            ? Colors.white24 
            : isCurrent 
              ? Colors.white 
              : Colors.white24,
          width: 2,
          style: isEmpty ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: !isEmpty && isCurrent ? [
          BoxShadow(
            color: const Color(0xFF50E3C2).withOpacity(0.3),
            blurRadius: 15,
          ),
        ] : null,
      ),
      child: Text(
        isEmpty ? '···' : word,
        style: TextStyle(
          color: isEmpty ? Colors.white38 : Colors.white,
          fontSize: size.width < 600 ? 14 : 18,
          fontWeight: isEmpty 
            ? FontWeight.normal 
            : isCurrent 
              ? FontWeight.bold 
              : FontWeight.normal,
        ),
      ),
    );
  }
  
  Widget _buildRankingUI(Size size) {
    // 더미 랭킹 데이터
    final List<Map<String, dynamic>> rankingData = [
      {'rank': 1, 'name': '테스트1', 'score': 3500},
      {'rank': 2, 'name': '테스트2', 'score': 2800},
      {'rank': 3, 'name': '테스트3', 'score': 2400},
      {'rank': 4, 'name': '테스트4', 'score': 2100},
      {'rank': 5, 'name': '테스트5', 'score': 1900},
      {'rank': 6, 'name': '테스트6', 'score': 1700},
      {'rank': 7, 'name': '테스트7', 'score': 1500},
      {'rank': 8, 'name': '테스트8', 'score': 1300},
      {'rank': 9, 'name': '테스트9', 'score': 1100},
      {'rank': 10, 'name': '테스트10', 'score': 900},
    ];
    
    return Stack(
      children: [
        // 랭킹 리스트
        Positioned(
          top: size.height * 0.12,
          left: size.width * 0.1,
          right: size.width * 0.1,
          bottom: size.height * 0.15,
          child: Column(
            children: [
              // 랭킹 타이틀
              Text(
                '🏆 플레이어 랭킹',
                style: TextStyle(
                  fontSize: size.width < 600 ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5),
              
              const SizedBox(height: 30),
              
              // 랭킹 리스트
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF50E3C2), width: 2),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: rankingData.length,
                    itemBuilder: (context, index) {
                      final item = rankingData[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width < 600 ? 15 : 20,
                          vertical: size.width < 600 ? 12 : 15,
                        ),
                        decoration: BoxDecoration(
                          color: item['rank'] <= 3 
                            ? [
                                const Color(0xFFFFD700), // 1등 금색
                                const Color(0xFFC0C0C0), // 2등 은색
                                const Color(0xFFCD7F32), // 3등 동색
                              ][item['rank'] - 1].withOpacity(0.2)
                            : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: item['rank'] <= 3 
                              ? [
                                  const Color(0xFFFFD700),
                                  const Color(0xFFC0C0C0),
                                  const Color(0xFFCD7F32),
                                ][item['rank'] - 1]
                              : Colors.white24,
                            width: item['rank'] <= 3 ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 순위
                            Container(
                              width: size.width < 600 ? 35 : 45,
                              height: size.width < 600 ? 35 : 45,
                              decoration: BoxDecoration(
                                color: item['rank'] <= 3 
                                  ? [
                                      const Color(0xFFFFD700),
                                      const Color(0xFFC0C0C0),
                                      const Color(0xFFCD7F32),
                                    ][item['rank'] - 1]
                                  : const Color(0xFF6C63FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: item['rank'] <= 3
                                  ? Icon(
                                      Icons.emoji_events,
                                      color: Colors.white,
                                      size: size.width < 600 ? 20 : 24,
                                    )
                                  : Text(
                                      '${item['rank']}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: size.width < 600 ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              ),
                            ),
                            
                            const SizedBox(width: 20),
                            
                            // 이름
                            Expanded(
                              child: Text(
                                item['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width < 600 ? 16 : 18,
                                  fontWeight: item['rank'] <= 3 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                ),
                              ),
                            ),
                            
                            // 점수
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width < 600 ? 12 : 15,
                                vertical: size.width < 600 ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF50E3C2).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF50E3C2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${item['score'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: TextStyle(
                                  color: const Color(0xFF50E3C2),
                                  fontSize: size.width < 600 ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideY(begin: 0.3),
            ],
          ),
        ),
        
        // 뒤로가기 버튼
        Positioned(
          bottom: size.height * 0.05,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _backToMain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 600 ? 30 : 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
              ),
              child: Text(
                '메인 화면으로',
                style: TextStyle(
                  fontSize: size.width < 600 ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 800.ms).slideY(begin: 1.0),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDictionaryUI(Size size) {
    // 더미 적 데이터
    final List<Map<String, dynamic>> enemyData = [
      {
        'level': 1,
        'name': '테스트 적 1',
        'description': '테스트용 적 설명 1\n응답률: 95%',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.school,
      },
      {
        'level': 2,
        'name': '테스트 적 2',
        'description': '테스트용 적 설명 2\n응답률: 90%',
        'color': const Color(0xFF2196F3),
        'icon': Icons.book,
      },
      {
        'level': 3,
        'name': '테스트 적 3',
        'description': '테스트용 적 설명 3\n응답률: 85%',
        'color': const Color(0xFFFF9800),
        'icon': Icons.psychology,
      },
      {
        'level': 4,
        'name': '테스트 적 4',
        'description': '테스트용 적 설명 4\n응답률: 80%',
        'color': const Color(0xFF9C27B0),
        'icon': Icons.auto_awesome,
      },
      {
        'level': 5,
        'name': '테스트 적 5',
        'description': '테스트용 적 설명 5\n응답률: 75%',
        'color': const Color(0xFFE91E63),
        'icon': Icons.emoji_events,
      },
      {
        'level': 6,
        'name': '테스트 적 6',
        'description': '테스트용 적 설명 6\n응답률: 70%',
        'color': const Color(0xFFFF5722),
        'icon': Icons.local_fire_department,
      },
      {
        'level': 7,
        'name': '테스트 적 7',
        'description': '테스트용 적 설명 7\n응답률: 65%',
        'color': const Color(0xFF795548),
        'icon': Icons.diamond,
      },
      {
        'level': 8,
        'name': '테스트 적 8',
        'description': '테스트용 적 설명 8\n응답률: 60%',
        'color': const Color(0xFF607D8B),
        'icon': Icons.star,
      },
    ];
    
    return Stack(
      children: [
        // 도감 리스트
        Positioned(
          top: size.height * 0.12,
          left: size.width * 0.05,
          right: size.width * 0.05,
          bottom: size.height * 0.15,
          child: Column(
            children: [
              // 도감 타이틀
              Text(
                '🧾 적 도감',
                style: TextStyle(
                  fontSize: size.width < 600 ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5),
              
              const SizedBox(height: 30),
              
              // 적 리스트
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: enemyData.length,
                    itemBuilder: (context, index) {
                      final enemy = enemyData[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(size.width < 600 ? 15 : 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: enemy['color'],
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: enemy['color'].withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 적 이미지/아이콘
                            Container(
                              width: size.width < 600 ? 70 : 90,
                              height: size.width < 600 ? 70 : 90,
                              decoration: BoxDecoration(
                                color: enemy['color'],
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: enemy['color'].withOpacity(0.4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    enemy['icon'],
                                    color: Colors.white,
                                    size: size.width < 600 ? 30 : 40,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Lv.${enemy['level']}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width < 600 ? 10 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 20),
                            
                            // 적 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 이름
                                  Text(
                                    enemy['name'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width < 600 ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // 설명
                                  Text(
                                    enemy['description'],
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: size.width < 600 ? 12 : 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 레벨 배지
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width < 600 ? 8 : 12,
                                vertical: size.width < 600 ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: enemy['color'].withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: enemy['color'],
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'LEVEL ${enemy['level']}',
                                style: TextStyle(
                                  color: enemy['color'],
                                  fontSize: size.width < 600 ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideY(begin: 0.3),
            ],
          ),
        ),
        
        // 뒤로가기 버튼
        Positioned(
          bottom: size.height * 0.05,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _backToMain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 600 ? 30 : 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
              ),
              child: Text(
                '메인 화면으로',
                style: TextStyle(
                  fontSize: size.width < 600 ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 800.ms).slideY(begin: 1.0),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGameOverUI(Size size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 게임 오버 메시지
            Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: size.width < 600 ? 36 : 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B6B),
                shadows: const [
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
              padding: EdgeInsets.symmetric(
                horizontal: size.width < 600 ? 25 : 40, 
                vertical: size.width < 600 ? 15 : 20
              ),
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
                  Text(
                    'FINAL SCORE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: size.width < 600 ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '1,500',
                    style: TextStyle(
                      color: const Color(0xFF50E3C2),
                      fontSize: size.width < 600 ? 28 : 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 800.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 40),
            
            // 이름 입력 또는 완료 메시지
            if (!_nameSubmitted) ...[
              Text(
                '랭킹에 등록할 이름을 입력하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width < 600 ? 16 : 18,
                ),
              ).animate().fadeIn(delay: 1000.ms),
              
              const SizedBox(height: 20),
              
              // 이름 입력창
              SizedBox(
                width: size.width < 600 ? size.width * 0.8 : size.width * 0.3,
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: size.width < 600 ? 16 : 18
                  ),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width < 600 ? 30 : 40, 
                    vertical: 15
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
                child: Text(
                  '랭킹 등록',
                  style: TextStyle(
                    fontSize: size.width < 600 ? 16 : 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ).animate().fadeIn(delay: 1400.ms, duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),
            ] else ...[
              // 등록 완료 메시지
              Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: size.width < 600 ? 60 : 80,
                    color: const Color(0xFF50E3C2),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.3, 0.3)),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    '랭킹에 등록되었습니다!',
                    style: TextStyle(
                      color: const Color(0xFF50E3C2),
                      fontSize: size.width < 600 ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 30),
                  
                  size.width < 600 
                    ? Column(
                        children: [
                          ElevatedButton(
                            onPressed: _restartGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('다시 하기'),
                          ),
                          
                          const SizedBox(height: 15),
                          
                          ElevatedButton(
                            onPressed: _showRankingScreen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF50E3C2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('랭킹 보기'),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _restartGame,
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
                            onPressed: _showRankingScreen,
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
    );
  }
  
  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _nameSubmitted = false;
      _showRanking = false;
    });
    
    // 게임 프로바이더에 게임 시작 알림
    Provider.of<GameProvider>(context, listen: false).startGame();
    
    // 타이머 리셋 후 시작
    _timerController.reset();
    _timerController.forward();
  }
  
  void _submitWord() {
    String word = _wordController.text.trim();
    if (word.isEmpty) return;
    
    // 단어 제출 로직 (추후 구현)
    setState(() {
      _wordHistory.add(word);
      _totalWordsSubmitted++;
      
      // 3개 이상일 때는 가장 오래된 단어 제거 (슬라이딩 효과)
      if (_wordHistory.length > 3) {
        _wordHistory.removeAt(0);
      }
    });
    
    // 입력창 클리어
    _wordController.clear();
    
    // 포커스 유지
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _wordFocusNode.requestFocus();
      }
    });
    
    // 단어 슬라이드 애니메이션
    _wordSlideController.forward().then((_) {
      _wordSlideController.reset();
    });
    
    // 타이머 리셋
    _timerController.reset();
    _timerController.forward();
    
    print('단어 제출: $word');
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
  }
  
  void _showRankingScreen() {
    setState(() {
      _showRanking = true;
    });
  }
  
  void _showDictionaryScreen() {
    setState(() {
      _showDictionary = true;
    });
  }
  
  void _backToMain() {
    setState(() {
      _showRanking = false;
      _showDictionary = false;
    });
  }
  
  // 3개 슬롯을 동적으로 생성하는 함수
  List<Widget> _buildWordSlots(Size size) {
    List<Widget> slots = [];
    
    for (int i = 0; i < 3; i++) {
      String word = '';
      bool isCurrent = false;
      
      if (i < _wordHistory.length) {
        // 이미 입력된 단어들 표시
        word = _wordHistory[i];
        isCurrent = false;
      } else if (i == _wordHistory.length && _wordHistory.length < 3) {
        // 다음에 입력할 슬롯 (현재 활성 슬롯)
        word = '';
        isCurrent = true;
      } else {
        // 아직 사용되지 않은 슬롯
        word = '';
        isCurrent = false;
      }
      
      slots.add(_buildWordBlock(word, isCurrent, size));
    }
    
    return slots;
  }
  
  void _restartGame() {
    setState(() {
      _gameStarted = false;
      _gameOver = false;
      _nameSubmitted = false;
      _showRanking = false;
      _showDictionary = false;
      _wordHistory = [];
      _totalWordsSubmitted = 0;
    });
    _nameController.clear();
    _wordController.clear();
    _timerController.reset();
    _wordSlideController.reset();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _wordController.dispose();
    _wordFocusNode.dispose();
    _timerController.dispose();
    _wordSlideController.dispose();
    super.dispose();
  }
}

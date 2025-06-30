import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'dart:html' as html; // 웹용 HTML 오디오
import 'dart:async'; // Timer 사용
import '../providers/game_provider.dart';
import '../services/api_service.dart';
import '../utils/double_consonant_utils.dart';
import '../widgets/character_image.dart';

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
  bool _isWaitingForAI = false;
  bool _serverConnected = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wordController = TextEditingController();
  final FocusNode _wordFocusNode = FocusNode();
  bool _nameSubmitted = false;
  bool _rankingSubmitted = false;
  
  late AnimationController _timerController;
  late AnimationController _aiTimerController; // AI 전용 타이머 추가
  late AnimationController _aiThinkingController;
  late AnimationController _wordSlideController;
  
  // 게임 상태
  String? _gameId;
  List<String> _usedWords = [];
  List<String> _displayWords = ['', '', '']; // 3개 슬롯
  String _currentMessage = '';
  String _lastChar = '';
  bool _playerTurn = true;
  bool _victory = false;
  int _playerTurns = 0;
  int _score = 0;
  int _currentSlot = 0;
  int _currentStage = 1;
  bool _stageClearInProgress = false;
  
  // AI 응답 관리
  String? _pendingAIWord; // AI 응답 대기 중인 단어
  bool _aiResponseReady = false; // AI 응답 준비 완료
  int _aiThinkingDuration = 0; // AI 생각 시간 (밀리초)
  bool _aiCannotRespond = false; // AI가 응답할 수 없는 상태
  
  // 타이핑 애니메이션 관리
  String _typingWord = ''; // 현재 타이핑 중인 단어
  int _typingProgress = 0; // 타이핑 진행률 (글자 수)
  bool _isTyping = false; // 타이핑 중인지 여부
  bool _isPlayerTyping = true; // 플레이어가 타이핑 중인지 (false면 AI)
  late AudioPlayer _audioPlayer; // 사운드 플레이어
  
  // 캐릭터 상태 관리
  CharacterState _playerState = CharacterState.idle;
  CharacterState _enemyState = CharacterState.idle;
  bool _isShowingDeathAnimation = false; // 죽는 애니메이션 표시 중
  Timer? _deathAnimationTimer; // 죽는 애니메이션 타이머
  
  @override
  void initState() {
    super.initState();
    
    // 사운드 플레이어 초기화
    _audioPlayer = AudioPlayer();
    
    _timerController = AnimationController(
      duration: const Duration(seconds: 10), // 10초 제한
      vsync: this,
    );
    _aiTimerController = AnimationController(
      duration: const Duration(seconds: 10), // AI도 10초 제한
      vsync: this,
    );
    _aiThinkingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _wordSlideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // 플레이어 타이머 완료 시 게임 오버
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && _gameStarted && !_gameOver && _playerTurn) {
        _timeUp();
      }
    });
    
    // AI 타이머 완료 시 AI 응답 처리
    _aiTimerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && _gameStarted && !_gameOver && !_playerTurn) {
        _handleAITurnComplete();
      }
    });
    
    _checkServerConnection();
  }
  
  // 타이핑 애니메이션 시작
  Future<void> _startTypingAnimation(String word, bool isPlayer) async {
    setState(() {
      _typingWord = word;
      _typingProgress = 0;
      _isTyping = true;
      _isPlayerTyping = isPlayer;
      
      // 캐릭터 상태를 공격 상태로 변경
      if (isPlayer) {
        _playerState = CharacterState.attack;
      } else {
        _enemyState = CharacterState.attack;
      }
    });
    
    // 전체 타이핑 시간 0.75초를 글자 수로 나누어 동적 속도 계산
    const totalTypingTime = 750; // 0.75초 (밀리초)
    final typingDelayPerChar = totalTypingTime ~/ word.length; // 글자당 시간
    
    print('🎯 타이핑 속도: ${word.length}글자, 글자당 ${typingDelayPerChar}ms');
    
    // 글자별로 동적 시간으로 타이핑
    for (int i = 0; i < word.length; i++) {
      if (!mounted || !_isTyping) break;
      
      // 타이핑 사운드 재생
      _playTypingSound();
      
      setState(() {
        _typingProgress = i + 1;
      });
      
      // 동적 시간 대기
      await Future.delayed(Duration(milliseconds: typingDelayPerChar));
    }
    
    // 타이핑 완료 후 1초 대기
    await Future.delayed(const Duration(seconds: 1));
    
    // 타이핑 애니메이션 종료 및 캐릭터 상태 복귀
    setState(() {
      _isTyping = false;
      _typingWord = '';
      _typingProgress = 0;
      
      // 캐릭터 상태를 기본 상태로 복귀
      if (isPlayer) {
        _playerState = CharacterState.idle;
      } else {
        _enemyState = CharacterState.idle;
      }
    });
  }
  
  // 타이핑 사운드 재생
  void _playTypingSound() {
    try {
      // 웹에서 HTML 오디오 사용 (다른 경로들 시도)
      final audio = html.AudioElement();
      
      // 여러 경로 시도
      const possiblePaths = [
        'assets/sounds/typing_sound.wav',
        'assets/assets/sounds/typing_sound.wav', // Flutter Web에서 때로는 이렇게 된다
        '/assets/sounds/typing_sound.wav',
        'sounds/typing_sound.wav'
      ];
      
      audio.src = possiblePaths[0]; // 기본 경로 사용
      audio.volume = 0.3; // 볼륨 30%
      audio.currentTime = 0; // 처음부터 재생
      
      audio.play().then((_) {
        print('🔊 타이핑 사운드 재생 성공 (${_typingProgress}/${_typingWord.length})');
      }).catchError((e) {
        print('🔊 HTML 오디오 재생 오류: $e');
        
        // 백업: audioplayers 사용
        try {
          _audioPlayer.play(AssetSource('sounds/typing_sound.wav'));
          print('🔊 백업 오디오 재생 시도');
        } catch (e2) {
          print('🔊 백업 오디오 재생 오류: $e2');
        }
      });
      
    } catch (e) {
      print('🔊 사운드 재생 오류: $e');
    }
  }
  
  // 시간 초과 처리
  void _timeUp() async {
    // 플레이어 죽는 애니메이션 시작
    setState(() {
      _playerState = CharacterState.death;
      _isShowingDeathAnimation = true;
      _currentMessage = '⏰ 시간 초과...';
    });
    
    // 2초 후 게임오버 화면 표시
    _deathAnimationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _gameOver = true;
          _victory = false;
          _currentMessage = '⏰ 시간 초과! 게임 종료';
          _isShowingDeathAnimation = false;
        });
      }
    });
    
    if (_gameId != null) {
      await ApiService.endGame(gameId: _gameId!);
    }
  }
  
  // AI 턴 완료 처리
  void _handleAITurnComplete() async {
    print('🔔 AI 타이머 완료 - 확률 실패: $_aiCannotRespond'); // 디버깅
    
    // 확률 실패로 AI가 응답할 수 없는 경우만 처리
    if (_aiCannotRespond) {
      print('🔔 AI 타이머에서 단계 클리어 처리 시도 - 현재 단계: $_currentStage');
      
      // 중요: 백엔드에서 이미 단계 클리어 처리가 되었을 수 있음
      // 중복 처리를 방지하기 위해 백엔드로 확인 요청
      if (_gameId != null) {
        final gameStatus = await ApiService.getGameStatus(_gameId!);
        if (gameStatus != null && gameStatus['success'] == true) {
          final backendStage = gameStatus['currentStage'] as int? ?? _currentStage;
          print('📊 백엔드 단계 확인: $backendStage vs 프론트엔드: $_currentStage');
          
          if (backendStage > _currentStage) {
            // 백엔드에서 이미 단계 업데이트가 되었음
            print('🚫 백엔드에서 이미 단계 클리어 처리됨. 중복 처리 방지.');
            setState(() {
              _currentStage = backendStage;
              _playerTurn = true;
              _isWaitingForAI = false;
              _aiCannotRespond = false;
              _currentMessage = '${backendStage}단계 시작!';
            });
            return; // 중복 처리 방지
          }
        }
      }
      
      // 백엔드에서 아직 처리되지 않은 경우에만 진행
      if (_currentStage < 3) {
        print('🎉 프론트엔드에서 단계 클리어 처리 진행');
        
        // 단계 클리어 처리
        final nextStage = _currentStage + 1;
        
        setState(() {
          _enemyState = CharacterState.death;
          _isShowingDeathAnimation = true;
          _stageClearInProgress = true;
          _currentMessage = '🎉 ${_currentStage}단계 클리어!';
        });
        
        // 3초 후 다음 단계 적 등장
        _deathAnimationTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _currentStage = nextStage;
              _enemyState = CharacterState.idle; // 새 적 등장
              _isShowingDeathAnimation = false;
              _stageClearInProgress = false;
              _playerTurn = true;
              _isWaitingForAI = false;
              _aiCannotRespond = false;
              _currentMessage = '${nextStage}단계 시작!';
              
              // 레벨 표시 애니메이션
              _showLevelIndicator(nextStage);
            });
            
            // 타이머 재시작
            _timerController.reset();
            _timerController.forward();
            
            // 포커스 요청
            _requestFocusIfPlayerTurn();
          }
        });
        
        // 게임은 계속 진행되므로 endGame 호출하지 않음!
        // 백엔드에서 이미 단계 업데이트가 완료되었음
      } else {
        // 모든 단계 클리어 - 게임 승리
        setState(() {
          _enemyState = CharacterState.death;
          _isShowingDeathAnimation = true;
          _currentMessage = '🏆 모든 단계 클리어!';
        });
        
        // 2초 후 승리 화면 표시
        _deathAnimationTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _gameOver = true;
              _victory = true;
              _currentMessage = '🏆 축하합니다! 모든 단계를 클리어했습니다!';
              _isShowingDeathAnimation = false;
            });
          }
        });
        
        // 모든 단계 클리어 시에만 게임 종료
        if (_gameId != null) {
          await ApiService.endGame(gameId: _gameId!);
        }
      }
    }
    // 정상적인 AI 응답은 _processAIResponse에서 처리
  }
  
  // 서버 연결 상태 확인
  Future<void> _checkServerConnection() async {
    final isConnected = await ApiService.checkServerHealth();
    setState(() {
      _serverConnected = isConnected;
    });
    
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버에 연결할 수 없습니다. 백엔드 서버가 실행 중인지 확인해주세요.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
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
          
          // 서버 연결 상태 표시
          if (!_serverConnected)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ 서버 연결 안됨 - 백엔드 서버를 실행해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        
        // 플레이어 캐릭터
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
          ).animate().slideX(begin: -2.0, end: 0, duration: 1500.ms, curve: Curves.elasticOut).fadeIn(duration: 800.ms),
        ),
        
        // AI 캐릭터
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
                  'TEST AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width < 600 ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ).animate().slideX(begin: 2.0, end: 0, duration: 1500.ms, curve: Curves.elasticOut).fadeIn(duration: 800.ms),
        ),
        
        // 중앙 버튼들
        Positioned(
          left: 0,
          right: 0,
          top: size.height * 0.7,
          child: Column(
            children: [
              // 시작 버튼
              ElevatedButton(
                onPressed: _serverConnected ? _startGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _serverConnected ? const Color(0xFF50E3C2) : Colors.grey,
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
                  _serverConnected ? '게임 시작' : '서버 연결 안됨',
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
              
              // 적 도감 버튼
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
        // 플레이어 캐릭터 (왼쪽 화면)
        Positioned(
          left: 0,
          top: size.height * 0.15,
          bottom: size.height * 0.05,
          width: size.width * 0.35, // 왼쪽 35% 차지
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 플레이어 타이핑 애니메이션
              if (_isTyping && _isPlayerTyping)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF50E3C2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF50E3C2).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    _typingWord.substring(0, _typingProgress),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 600 ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8)),
              
              // 플레이어 캐릭터 이미지
              Expanded(
                child: Center(
                  child: CharacterImage(
                    type: CharacterType.player,
                    state: _playerState,
                    width: size.width * 0.25,
                    height: size.height * 0.4,
                    isActive: _playerTurn && !_isWaitingForAI,
                  ),
                ),
              ),
              
              // 플레이어 상태 텍스트
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _playerTurn && !_isWaitingForAI 
                    ? const Color(0xFF50E3C2) 
                    : const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _playerTurn && !_isWaitingForAI ? 'YOUR TURN' : 'WAIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width < 600 ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // AI 캐릭터 (오른쪽 화면)
        Positioned(
          right: 0,
          top: size.height * 0.15,
          bottom: size.height * 0.05,
          width: size.width * 0.35, // 오른쪽 35% 차지
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AI 타이핑 애니메이션
              if (_isTyping && !_isPlayerTyping)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    _typingWord.substring(0, _typingProgress),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 600 ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8)),
              
              // AI 캐릭터 이미지
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CharacterImage(
                        type: CharacterType.enemy,
                        state: _enemyState,
                        stage: _currentStage, // 단계 전달
                        width: size.width * 0.25,
                        height: size.height * 0.4,
                        isActive: !_playerTurn && _isWaitingForAI,
                      ),
                      
                      // AI 생각 중 애니메이션 제거 (CharacterImage의 isActive로 처리)
                    ],
                  ),
                ),
              ),
              
              // AI 상태 텍스트
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isWaitingForAI 
                    ? const Color(0xFF50E3C2) 
                    : const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _isWaitingForAI ? 'THINKING...' : _getEnemyName(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width < 600 ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 타이머 바 (상단) - 중앙 영역
        Positioned(
          top: size.height * 0.08,
          left: size.width * 0.35,
          right: size.width * 0.35,
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
                animation: _playerTurn ? _timerController : _aiTimerController,
                builder: (context, child) {
                  final currentTimer = _playerTurn ? _timerController : _aiTimerController;
                  return LinearProgressIndicator(
                    value: 1.0 - currentTimer.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      currentTimer.value < 0.3 
                        ? (_playerTurn ? const Color(0xFF50E3C2) : const Color(0xFFFF6B6B))
                        : currentTimer.value < 0.7
                          ? Colors.orange
                          : const Color(0xFFFF6B6B),
                    ),
                  );
                },
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 800.ms).slideY(begin: -0.5),
        ),
        
        // 점수 및 단계 표시 (중앙 상단)
        Positioned(
          top: size.height * 0.12,
          left: size.width * 0.35,
          right: size.width * 0.35,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width < 600 ? 12 : 15, 
                    vertical: size.width < 600 ? 8 : 10
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                  ),
                  child: Text(
                    'LV.$_currentStage',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFF6B6B),
                      fontSize: size.width < 600 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
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
                    'SCORE: $_score',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 600 ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 800.ms).slideY(begin: -0.5),
        ),
        
        // 단어 슬롯 (중앙 영역)
        Positioned(
          top: size.height * 0.25,
          left: size.width * 0.35,
          right: size.width * 0.35,
          child: Column(
            children: [
              if (_currentMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF50E3C2), width: 1),
                    ),
                    child: Text(
                      _currentMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width < 600 ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              
              Wrap(
                alignment: WrapAlignment.center,
                spacing: size.width < 600 ? 8 : 15,
                children: _buildWordSlots(size),
              ),
            ],
          ).animate().fadeIn(delay: 900.ms, duration: 800.ms).slideY(begin: -0.3),
        ),
        
        // 마지막 글자 강조 표시 (중앙 영역) - 두음법칙 적용, 항상 표시
        if (_lastChar.isNotEmpty)
          Positioned(
            top: size.height * 0.45,
            left: size.width * 0.35,
            right: size.width * 0.35,
            child: Column(
              children: [
                AnimatedOpacity(
                  opacity: _isWaitingForAI ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width < 600 ? 20 : 30,
                      vertical: size.width < 600 ? 15 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: (_playerTurn && !_isWaitingForAI 
                        ? const Color(0xFF50E3C2) 
                        : Colors.grey).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: (_playerTurn && !_isWaitingForAI 
                            ? const Color(0xFF50E3C2) 
                            : Colors.grey).withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isWaitingForAI ? 'AI 생각 중...' : '다음 글자',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width < 600 ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DoubleConsonantUtils.getDisplayText(_lastChar),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width < 600 ? 36 : 48,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DoubleConsonantUtils.hasDoubleConsonantRule(_lastChar) ? '(두음법칙 적용)' : '',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: size.width < 600 ? 10 : 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // 입력창 (중앙 하단) - 항상 표시하되 상태에 따라 활성화/비활성화
        Positioned(
          bottom: size.height * 0.05,
          left: size.width * 0.35,
          right: size.width * 0.35,
          child: AnimatedOpacity(
            opacity: _stageClearInProgress ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width < 600 ? 15 : 20, 
              vertical: size.width < 600 ? 12 : 15
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _playerTurn && !_isWaitingForAI 
                  ? const Color(0xFF50E3C2) 
                  : Colors.grey, 
                width: 2
              ),
              boxShadow: [
                if (_playerTurn && !_isWaitingForAI) BoxShadow(
                  color: const Color(0xFF50E3C2).withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: TextField(
              controller: _wordController,
              focusNode: _wordFocusNode,
              enabled: _playerTurn && !_isWaitingForAI && !_stageClearInProgress,
              autofocus: _playerTurn && !_isWaitingForAI && !_stageClearInProgress, // 상태에 따라 autofocus
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _playerTurn && !_isWaitingForAI ? Colors.white : Colors.white54, 
                fontSize: size.width < 600 ? 16 : 18
              ),
              decoration: InputDecoration(
                hintText: _isWaitingForAI 
                  ? 'AI가 응답하는 중...' 
                  : _playerTurn 
                    ? '단어를 입력하세요...' 
                    : '대기 중...',
                hintStyle: TextStyle(
                  color: _playerTurn && !_isWaitingForAI ? Colors.white54 : Colors.white38
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isWaitingForAI ? Icons.hourglass_empty : Icons.send, 
                    color: _playerTurn && !_isWaitingForAI 
                      ? const Color(0xFF50E3C2) 
                      : Colors.grey,
                    size: size.width < 600 ? 20 : 24,
                  ),
                  onPressed: _playerTurn && !_isWaitingForAI && !_stageClearInProgress ? _submitWord : null,
                ),
              ),
              onSubmitted: _playerTurn && !_isWaitingForAI && !_stageClearInProgress ? (_) => _submitWord() : null,
            ),
          ),
          ),
        ),
      ],
    );
  }
  
  // 3개 단어 슬롯 생성
  List<Widget> _buildWordSlots(Size size) {
    List<Widget> slots = [];
    
    for (int i = 0; i < 3; i++) {
      String word = _displayWords[i];
      bool isCurrent = i == _currentSlot && _playerTurn;
      bool isEmpty = word.isEmpty;
      
      slots.add(_buildWordBlock(word, isCurrent, isEmpty, size));
    }
    
    return slots;
  }
  
  Widget _buildWordBlock(String word, bool isCurrent, bool isEmpty, Size size) {
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
  
  // 게임 시작
  Future<void> _startGame() async {
    if (!_serverConnected) return;
    
    // 오디오 게임 시작 시 활성화 (브라우저 autoplay 정책 우회)
    _initializeAudio();
    
    setState(() {
      _gameStarted = true;
      _gameOver = false;
      _isWaitingForAI = true;
      _currentMessage = '게임을 시작하는 중...';
      _displayWords = ['', '', ''];
      _currentSlot = 0;
      _playerTurns = 0;
      _score = 0;
      _currentStage = 1;
      
      // Provider 단계 상태도 초기화
      Provider.of<GameProvider>(context, listen: false).updateStage(1);
      _stageClearInProgress = false;
      _aiCannotRespond = false;
    });
    
    Provider.of<GameProvider>(context, listen: false).startGame(resetStage: true);
    
    try {
      final response = await ApiService.startGame();
      
      if (response != null && response['success'] == true) {
        setState(() {
          _gameId = response['gameId'];
          _usedWords = List<String>.from(response['usedWords'] ?? []);
          _currentMessage = response['message'] ?? '';
          _playerTurn = true;
          _isWaitingForAI = false;
          _playerTurns = response['playerTurns'] ?? 0;
          _score = response['score'] ?? 0;
          
          // 첫 번째 슬롯에 AI 단어 표시
          if (_usedWords.isNotEmpty) {
            _displayWords[0] = _usedWords.last;
            _currentSlot = 1;
            final lastWord = _usedWords.last;
            _lastChar = lastWord[lastWord.length - 1];
          }
        });
        
        // 포커스 요청
        _requestFocusIfPlayerTurn();
        
        // 타이머 시작
        _timerController.reset();
        _timerController.forward();
        
        // 입력창에 포커스 (강화된 버전)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _playerTurn && !_isWaitingForAI) {
            _wordFocusNode.requestFocus();
          }
        });
        
        // 추가 포커스 시도
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _playerTurn && !_isWaitingForAI) {
            _wordFocusNode.requestFocus();
          }
        });
      } else {
        _showError('게임 시작에 실패했습니다');
        setState(() {
          _gameStarted = false;
        });
      }
    } catch (e) {
      _showError('서버 연결 오류: $e');
      setState(() {
        _gameStarted = false;
      });
    }
  }
  
  // 오디오 초기화 (브라우저 autoplay 정책 우회)
  void _initializeAudio() {
    try {
      // 더미 오디오를 재생해서 브라우저 오디오 컴텍스트 활성화
      final audio = html.AudioElement();
      audio.src = 'assets/sounds/typing_sound.wav';
      audio.volume = 0.01; // 매우 작은 볼륨
      audio.currentTime = 0;
      
      audio.play().then((_) {
        print('🎵 오디오 컴텍스트 활성화 성공');
        
        // 성공하면 즉시 소리 끌기
        Timer(const Duration(milliseconds: 50), () {
          audio.pause();
        });
      }).catchError((e) {
        print('🎵 오디오 컴텍스트 활성화 실패: $e');
        print('🎵 브라우저에서 사운드를 차단했을 수 있습니다. 첫 번째 단어 입력 후에 소리가 나올 것입니다.');
      });
    } catch (e) {
      print('오디오 초기화 오류: $e');
    }
  }
  
  // 단어 제출
  Future<void> _submitWord() async {
    if (!_playerTurn || _isWaitingForAI || _gameId == null || _isTyping || _stageClearInProgress) return;
    
    final word = _wordController.text.trim();
    if (word.isEmpty) return;
    
    // 플레이어 타이머 중지
    _timerController.stop();
    
    // 입력창 클리어
    _wordController.clear();
    
    // AI 생각 시간 설정 (1-7초, 70% 확률로 빠름)
    final isQuickResponse = Random().nextDouble() < 0.7;
    _aiThinkingDuration = isQuickResponse 
        ? 1000 + Random().nextInt(3000)  // 1-4초
        : 4000 + Random().nextInt(3000); // 4-7초
    
    print('🤖 AI 생각 시간: ${(_aiThinkingDuration/1000).toStringAsFixed(1)}초');
    
    // API에 단어 제출하고 결과에 따라 처리
    await _submitWordToAPI(word);
  }
  
  // AI 응답 스케줄링 (지정된 시간 후 응답)
  Future<void> _scheduleAIResponse() async {
    // AI가 확률로 인해 응답할 수 없는 경우 처리하지 않음
    if (_aiCannotRespond) {
      print('🚫 AI가 확률 실패로 응답할 수 없으므로 대기');
      return;
    }
    
    // 지정된 시간만큼 대기
    await Future.delayed(Duration(milliseconds: _aiThinkingDuration));
    
    // 게임이 아직 진행 중이고 AI 턴인 경우에만 실행
    if (!mounted || _gameOver || _playerTurn || _aiCannotRespond) return;
    
    // AI 응답이 준비된 경우 즉시 처리
    if (_aiResponseReady && _pendingAIWord != null) {
      _processAIResponse();
      return;
    }
    
    // 아직 AI 응답이 준비되지 않은 경우 조금 더 기다림 (최대 1초)
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted || _gameOver || _playerTurn || _aiCannotRespond) return;
      
      if (_aiResponseReady && _pendingAIWord != null) {
        _processAIResponse();
        return;
      }
    }
    
    // 여전히 응답이 없는 경우 메시지 업데이트
    if (mounted && !_gameOver && !_playerTurn && !_aiCannotRespond) {
      setState(() {
        _currentMessage = 'AI가 단어를 찾는 중...';
      });
    }
  }
  
  // AI 응답 처리
  void _processAIResponse() {
    if (_pendingAIWord != null) {
      // AI 타이머 중지 (AI가 이미 답했으므로)
      _aiTimerController.stop();
      
      // AI 타이핑 애니메이션 시작
      _startTypingAnimation(_pendingAIWord!, false);
      
      final aiWord = _pendingAIWord!;
      
      // 타이핑 완룼 후 플레이어 턴으로 전환
      Future.delayed(const Duration(milliseconds: 1750), () { // 타이핑 0.75초 + 대기 1초
        if (!mounted) return;
        
        setState(() {
          _lastChar = aiWord[aiWord.length - 1];
          _updateWordSlots(aiWord);
          _playerTurn = true;
          _isWaitingForAI = false;
          _currentMessage = 'AI: $aiWord';
          
          // 대기 상태 초기화
          _pendingAIWord = null;
          _aiResponseReady = false;
        });
        
        // 플레이어 턴 타이머 시작
        _timerController.reset();
        _timerController.forward();
        
        // 포커스 요청
        _requestFocusIfPlayerTurn();
      });
    }
  }
  
  // API에 단어 제출 (성공 시에만 타이핑 애니메이션)
  Future<void> _submitWordToAPI(String word) async {
    print('📤 API 전송 준비: gameId=$_gameId, word=$word'); // 디버깅
    
    try {
      final response = await ApiService.submitWord(
        gameId: _gameId!,
        word: word,
        responseTime: (_timerController.value * 10000).toInt(),
      );
      
      if (response != null && response['success'] == true) {
        // 성공! 플레이어 타이핑 애니메이션 시작
        await _startTypingAnimation(word, true);
        
        // 단계 클리어 처리
        if (response['stageClear'] == true) {
          print('🎉 단계 클리어 감지! gameId: $_gameId'); // 디버깅
          
          // 단계 클리어!
          final nextStage = response['nextStage'] ?? (_currentStage + 1);
          
          setState(() {
            _enemyState = CharacterState.death; // 현재 적 죽음
            _isShowingDeathAnimation = true;
            _stageClearInProgress = true;
            _currentMessage = response['message'] ?? '🎉 ${_currentStage}단계 클리어!';
            _usedWords = List<String>.from(response['usedWords'] ?? []);
            _playerTurns = response['playerTurns'] ?? _playerTurns;
            _score = response['score'] ?? _score;
            
            // 단어 슬롯에 플레이어 단어 추가
            _displayWords[_currentSlot] = word;
          });
          
          // 3초 후 다음 단계 적 등장
          _deathAnimationTimer = Timer(const Duration(seconds: 3), () {
            print('🕐 3초 타이머 완료 - gameId: $_gameId'); // 디버깅
            
            if (mounted) {
              setState(() {
                print('🎮 단계 전환: $_currentStage -> $nextStage (gameId: $_gameId)'); // 디버깅
                
                _currentStage = nextStage;
                _enemyState = CharacterState.idle; // 새 적 등장
                
                // Provider 단계 상태도 업데이트
                Provider.of<GameProvider>(context, listen: false).updateStage(nextStage);
                _isShowingDeathAnimation = false;
                _stageClearInProgress = false;
                _playerTurn = true;
                _isWaitingForAI = false;
                _currentMessage = '${nextStage}단계 시작!';
                
                // AI 턴 카운트 리셋
                _aiCannotRespond = false;
                
                // 🔧 수정: 마지막 사용된 단어의 마지막 글자를 시작 글자로 설정
                if (_usedWords.isNotEmpty) {
                  final lastUsedWord = _usedWords.last;
                  _lastChar = lastUsedWord[lastUsedWord.length - 1];
                  print('🎯 새 단계 시작 글자: $_lastChar (마지막 단어: $lastUsedWord)');
                }
                
                // 레벨 표시 애니메이션
                _showLevelIndicator(nextStage);
              });
              
              // 타이머 재시작
              _timerController.reset();
              _timerController.forward();
              
              // 포커스 요청
              _requestFocusIfPlayerTurn();
            }
          });
          
        } else if (response['gameOver'] == true) {
          // 게임 종룄 - 승리/패배에 따른 죽는 애니메이션
          final victory = response['victory'] ?? false;
          
          setState(() {
            if (victory) {
              _enemyState = CharacterState.death; // AI 죽음
            } else {
              _playerState = CharacterState.death; // 플레이어 죽음
            }
            _isShowingDeathAnimation = true;
            _currentMessage = victory ? 'AI 패배...' : '플레이어 패배...';
            _usedWords = List<String>.from(response['finalWords'] ?? response['usedWords'] ?? []);
            _playerTurns = response['playerTurns'] ?? _playerTurns;
            _score = response['score'] ?? _score;
          });
          
          // 2초 후 게임오버 화면 표시
          _deathAnimationTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _gameOver = true;
                _victory = victory;
                _currentMessage = response['message'] ?? '';
                _isShowingDeathAnimation = false;
              });
            }
          });
        } else {
          // 게임 계속 - AI 턴으로 전환
          setState(() {
            _playerTurn = false;
            _isWaitingForAI = true;
            _currentMessage = 'AI가 생각하는 중...';
            _aiCannotRespond = false; // 초기화
            
            // 플레이어 단어를 슬롯에 추가
            _displayWords[_currentSlot] = word;
            
            // 게임 데이터 업데이트
            _usedWords = List<String>.from(response['usedWords'] ?? []);
            _playerTurns = response['playerTurns'] ?? _playerTurns;
            _score = response['score'] ?? _score;
            
            // 단계 업데이트 전후 비교
            final oldStage = _currentStage;
            final backendStage = response['currentStage'] ?? _currentStage;
            _currentStage = backendStage;
            
            // Provider 단계 상태도 동기화
            if (oldStage != _currentStage) {
              Provider.of<GameProvider>(context, listen: false).updateStage(_currentStage);
            }
            
            print('📊 단계 상태: $oldStage -> $_currentStage (백엔드: $backendStage)');
            
            // AI 응답 준비
            final aiWord = response['aiWord'];
            if (aiWord != null && aiWord.isNotEmpty) {
              _pendingAIWord = aiWord;
              _aiResponseReady = true;
              print('✅ AI 응답 준비 완료: $aiWord');
            } else if (response['aiFailReason'] == 'probability_fail') {
              // 확률 실패로 AI가 응답할 수 없음
              _aiCannotRespond = true;
              _pendingAIWord = null;
              _aiResponseReady = false;
              
              // 중요: AI 타이머 중지 (중복 처리 방지)
              _aiTimerController.stop();
              
              print('🎲 AI가 확률로 인해 응답할 수 없습니다 (단계: $_currentStage)');
              print('⏹️ AI 타이머 중지 - 중복 처리 방지');
            }
          });
          
          // AI 타이머 시작 (10초 고정)
          _aiTimerController.duration = const Duration(seconds: 10);
          _aiTimerController.reset();
          _aiTimerController.forward();
          
          // AI 응답 스케줄링 (지정된 시간 후 응답)
          _scheduleAIResponse();
        }
      } else {
        // 오류 처리 - 플레이어 턴 복구 (타이핑 애니메이션 없음)
        setState(() {
          _currentMessage = response?['message'] ?? '단어 제출 실패';
          _playerTurn = true;
          _isWaitingForAI = false;
        });
        
        // 플레이어 타이머 재시작
        _timerController.forward();
        
        // 포커스 요청
        _requestFocusIfPlayerTurn();
      }
    } catch (e) {
      // 오류 처리 - 플레이어 턴 복구
      setState(() {
        _currentMessage = '서버 연결 오류';
        _playerTurn = true;
        _isWaitingForAI = false;
      });
      
      // 플레이어 타이머 재시작
      _timerController.forward();
      
      // 포커스 요청
      _requestFocusIfPlayerTurn();
    }
  }
  
  // 단어 슬롯 업데이트 (슬라이딩 효과)
  void _updateWordSlots(String aiWord) {
    // 슬롯을 왼쪽으로 밀기
    if (_currentSlot >= 2) {
      _displayWords[0] = _displayWords[1];
      _displayWords[1] = _displayWords[2];
      _displayWords[2] = aiWord;
      _currentSlot = 2;
    } else {
      _currentSlot++;
      _displayWords[_currentSlot] = aiWord;
      _currentSlot++;
      if (_currentSlot >= 3) _currentSlot = 2;
    }
    
    // 슬라이드 애니메이션
    _wordSlideController.forward().then((_) {
      _wordSlideController.reset();
    });
  }
  
  // 포커스 요청 헬퍼 메서드
  void _requestFocusIfPlayerTurn() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _playerTurn && !_isWaitingForAI) {
        _wordFocusNode.requestFocus();
        print('🎯 포커스 요청 실행: 플레이어 턴=$_playerTurn, AI대기=$_isWaitingForAI');
      }
    });
  }
  
  // 레벨 표시 애니메이션
  void _showLevelIndicator(int level) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF50E3C2), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF50E3C2).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LEVEL $level',
                  style: const TextStyle(
                    color: Color(0xFF50E3C2),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getStageName(level),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ).animate()
          .scale(duration: 500.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 300.ms);
      },
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
    
    // 2초 후 자동으로 닫기
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  
  // 단계 이름 가져오기
  String _getStageName(int stage) {
    switch (stage) {
      case 1:
        return '초급 전사';
      case 2:
        return '중급 마법사';
      case 3:
        return '전설의 드래곤';
      default:
        return '';
    }
  }
  
  // 적 이름 가져오기 (짧은 버전)
  String _getEnemyName() {
    switch (_currentStage) {
      case 1:
        return '전사';
      case 2:
        return '마법사';
      case 3:
        return '드래곤';
      default:
        return 'AI';
    }
  }
  

  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Widget _buildRankingUI(Size size) {
    return Stack(
      children: [
        // 배경
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
        
        // 랭킹 콘텐츠
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: 20,
              ),
              child: Column(
                children: [
                  // 헤더
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showRanking = false;
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '🏆 랭킹',
                        style: TextStyle(
                          fontSize: size.width < 600 ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 랭킹 리스트
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: ApiService.getRankings(limit: 10),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF50E3C2),
                            ),
                          );
                        }
                        
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data?['success'] != true) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 64,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  '랭킹 데이터를 불러올 수 없습니다',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF),
                                  ),
                                  child: const Text('새로고침'),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final rankings = List<Map<String, dynamic>>.from(snapshot.data?['rankings'] ?? []);
                        
                        if (rankings.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  '아직 랭킹 데이터가 없습니다',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '게임을 플레이하고 랭킹에 도전해보세요!',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: rankings.length,
                          itemBuilder: (context, index) {
                            final ranking = rankings[index];
                            final rank = ranking['rank'] ?? index + 1;
                            final playerName = ranking['playerName'] ?? '알 수 없음';
                            final score = ranking['score'] ?? 0;
                            final stageReached = ranking['stageReached'] ?? 1;
                            
                            Color rankColor = Colors.white;
                            IconData rankIcon = Icons.emoji_events;
                            
                            if (rank == 1) {
                              rankColor = const Color(0xFFFFD700); // 금색
                              rankIcon = Icons.workspace_premium;
                            } else if (rank == 2) {
                              rankColor = const Color(0xFFC0C0C0); // 은색
                              rankIcon = Icons.military_tech;
                            } else if (rank == 3) {
                              rankColor = const Color(0xFFCD7F32); // 동색
                              rankIcon = Icons.emoji_events;
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: rank <= 3 
                                  ? rankColor.withOpacity(0.1)
                                  : const Color(0xFF16213E).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: rank <= 3 
                                    ? rankColor.withOpacity(0.5)
                                    : Colors.white24,
                                  width: rank <= 3 ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // 순위 아이콘
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: rankColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: rank <= 3 
                                        ? Icon(
                                            rankIcon,
                                            color: rankColor,
                                            size: 24,
                                          )
                                        : Text(
                                            '$rank',
                                            style: TextStyle(
                                              color: rankColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 15),
                                  
                                  // 정보
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playerName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size.width < 600 ? 16 : 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '점수: $score점 | 단계: $stageReached',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // 점수 배지
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF50E3C2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      '$score',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: index * 100),
                              duration: 600.ms,
                            ).slideX(
                              begin: 1.0,
                              end: 0.0,
                              curve: Curves.easeOutCubic,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 하단 버튼
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showRanking = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width < 600 ? 30 : 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('메인으로 돌아가기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDictionaryUI(Size size) {
    return Container(); // 기존과 동일
  }
  
  Widget _buildGameOverUI(Size size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _victory ? 'VICTORY!' : 'GAME OVER',
              style: TextStyle(
                fontSize: size.width < 600 ? 36 : 48,
                fontWeight: FontWeight.bold,
                color: _victory ? const Color(0xFF50E3C2) : const Color(0xFFFF6B6B),
                shadows: const [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              _currentMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width < 600 ? 16 : 18,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF50E3C2), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    '최종 점수: $_score점',
                    style: TextStyle(
                      color: const Color(0xFF50E3C2),
                      fontSize: size.width < 600 ? 18 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '플레이어 턴: $_playerTurns',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '최종 단어들',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _displayWords.where((w) => w.isNotEmpty).map((word) => 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          word,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    ).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 이름 입력 및 랭킹 등록
            if (!_rankingSubmitted) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      '🏆 랭킹에 등록하세요!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width < 600 ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: '이름을 입력하세요',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _submitRanking(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _submitRanking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF50E3C2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('랭킹 등록'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF50E3C2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF50E3C2), width: 1),
                ),
                child: const Text(
                  '✅ 랭킹에 등록되었습니다!',
                  style: TextStyle(
                    color: Color(0xFF50E3C2),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            Row(
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
                  onPressed: _backToMain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50E3C2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('메인으로'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 랭킹 등록
  Future<void> _submitRanking() async {
    final playerName = _nameController.text.trim();
    
    if (playerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름을 입력해주세요!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      final response = await ApiService.submitScore(
        playerName: playerName,
        score: _score,
        stageReached: 1, // 현재는 단계 1만 있음
      );
      
      if (response != null && response['success'] == true) {
        setState(() {
          _rankingSubmitted = true;
        });
        
        final rank = response['rank'] ?? '?';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏆 랭킹 등록 성공! $rank위입니다.'),
            backgroundColor: const Color(0xFF50E3C2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('랭킹 등록 실패: ${response?['message'] ?? '알 수 없는 오류'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('랭킹 등록 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      _gameStarted = false;
      _gameOver = false;
      _rankingSubmitted = false;
    });
    _nameController.clear();
  }
  
  void _restartGame() {
    setState(() {
      _gameStarted = false;
      _gameOver = false;
      _gameId = null;
      _usedWords = [];
      _displayWords = ['', '', ''];
      _currentMessage = '';
      _lastChar = '';
      _playerTurn = true;
      _victory = false;
      _playerTurns = 0;
      _score = 0;
      _currentSlot = 0;
      _currentStage = 1;
      _stageClearInProgress = false;
      _isWaitingForAI = false;
      _rankingSubmitted = false;
      
      // AI 응답 관리 초기화
      _pendingAIWord = null;
      _aiResponseReady = false;
      _aiThinkingDuration = 0;
      _aiCannotRespond = false;
      
      // 캐릭터 상태 초기화
      _playerState = CharacterState.idle;
      _enemyState = CharacterState.idle;
      _isShowingDeathAnimation = false;
    });
    _nameController.clear();
    _wordController.clear();
    _timerController.reset();
    _aiTimerController.reset(); // AI 타이머도 리셋
    _deathAnimationTimer?.cancel(); // 죽는 애니메이션 타이머 취소
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _wordController.dispose();
    _wordFocusNode.dispose();
    _timerController.dispose();
    _aiTimerController.dispose(); // AI 타이머 추가
    _aiThinkingController.dispose();
    _wordSlideController.dispose();
    _audioPlayer.dispose(); // 오디오 플레이어 리소스 해제
    _deathAnimationTimer?.cancel(); // 죽는 애니메이션 타이머 해제
    super.dispose();
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BGMService {
  static final BGMService _instance = BGMService._internal();
  factory BGMService() => _instance;
  BGMService._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  
  // 현재 상태
  bool _isEnabled = false; // 기본적으로 BGM 꺼진 상태
  double _volume = 0.2; // 기본 볼륨 20%
  String _currentTrack = '';
  bool _isPlaying = false;

  // 배경음악 트랙들
  static const Map<String, String> _tracks = {
    'main_menu': 'sounds/bgm/main_menu.mp3',
    'game_battle': 'sounds/bgm/game_battle.mp3',
  };

  // Getters
  bool get isEnabled => _isEnabled;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  String get currentTrack => _currentTrack;

  // 초기화
  Future<void> initialize() async {
    await _loadSettings();
    
    // 플레이어 설정
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundPlayer.setVolume(_volume);
    
    // 플레이어 상태 리스너
    _backgroundPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
    });
    
    print('🎵 BGM 서비스 초기화 완료 - 활성화: $_isEnabled, 볼륨: ${(_volume * 100).toInt()}%');
  }

  // 설정 로드
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('bgm_enabled') ?? false; // 기본적으로 BGM 꺼진 상태
      _volume = prefs.getDouble('bgm_volume') ?? 0.2; // 기본 볼륨 20%
    } catch (e) {
      print('BGM 설정 로드 실패: $e');
    }
  }

  // 설정 저장
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bgm_enabled', _isEnabled);
      await prefs.setDouble('bgm_volume', _volume);
    } catch (e) {
      print('BGM 설정 저장 실패: $e');
    }
  }

  // 배경음악 재생
  Future<void> playBGM(String trackName, {bool forceRestart = false}) async {
    if (!_isEnabled) {
      print('🔇 BGM이 비활성화되어 있음');
      return;
    }
    
    final trackPath = _tracks[trackName];
    if (trackPath == null) {
      print('❌ 알 수 없는 BGM 트랙: $trackName');
      return;
    }

    // 이미 같은 트랙이 재생 중이면 무시 (강제 재시작이 아닌 경우)
    if (_currentTrack == trackName && _isPlaying && !forceRestart) {
      print('✅ 이미 $trackName 재생 중');
      return;
    }

    try {
      print('🎵 BGM 재생 시도: $trackName');
      
      // 기존 재생 중지
      await _backgroundPlayer.stop();
      
      // 새 트랙 재생
      await _backgroundPlayer.play(AssetSource(trackPath));
      _currentTrack = trackName;
      
      print('✅ BGM 재생 성공: $trackName');
    } catch (e) {
      print('❌ BGM 재생 실패: $e');
      
      // 파일이 없는 경우 또는 권한 문제
      if (e.toString().contains('404') || 
          e.toString().contains('not found') ||
          e.toString().contains('NotAllowedError') ||
          e.toString().contains('autoplay')) {
        print('💡 BGM 재생 제한: 브라우저 정책 또는 파일 없음');
        print('💡 해결책: 1) BGM 컨트롤러 클릭 2) $trackPath 파일 확인');
      }
    }
  }

  // 배경음악 중지
  Future<void> stopBGM() async {
    try {
      await _backgroundPlayer.stop();
      _currentTrack = '';
      print('🎵 BGM 중지');
    } catch (e) {
      print('BGM 중지 실패: $e');
    }
  }

  // 일시정지
  Future<void> pauseBGM() async {
    try {
      await _backgroundPlayer.pause();
      print('🎵 BGM 일시정지');
    } catch (e) {
      print('BGM 일시정지 실패: $e');
    }
  }

  // 재개
  Future<void> resumeBGM() async {
    try {
      if (_isEnabled && _currentTrack.isNotEmpty) {
        await _backgroundPlayer.resume();
        print('🎵 BGM 재개');
      }
    } catch (e) {
      print('BGM 재개 실패: $e');
    }
  }

  // 볼륨 설정
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _backgroundPlayer.setVolume(_volume);
    await _saveSettings();
    print('🎵 BGM 볼륨 변경: ${(_volume * 100).toInt()}%');
  }

  // BGM 활성화/비활성화
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();
    
    if (!_isEnabled) {
      await stopBGM();
    } else if (_currentTrack.isNotEmpty) {
      // 마지막으로 재생했던 트랙 재개
      await playBGM(_currentTrack);
    }
    
    print('🎵 BGM ${_isEnabled ? "활성화" : "비활성화"}');
  }

  // 페이드아웃
  Future<void> fadeOut({Duration duration = const Duration(seconds: 2)}) async {
    if (!_isPlaying) return;
    
    final originalVolume = _volume;
    const steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    
    for (int i = steps; i >= 0; i--) {
      final currentVolume = originalVolume * (i / steps);
      await _backgroundPlayer.setVolume(currentVolume);
      await Future.delayed(stepDuration);
    }
    
    await stopBGM();
    await _backgroundPlayer.setVolume(originalVolume);
  }

  // 페이드인
  Future<void> fadeIn(String trackName, {Duration duration = const Duration(seconds: 2)}) async {
    if (!_isEnabled) return;
    
    const steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    
    // 볼륨을 0으로 설정하고 재생 시작
    await _backgroundPlayer.setVolume(0.0);
    await playBGM(trackName);
    
    // 서서히 볼륨 증가
    for (int i = 0; i <= steps; i++) {
      final currentVolume = _volume * (i / steps);
      await _backgroundPlayer.setVolume(currentVolume);
      await Future.delayed(stepDuration);
    }
  }

  // 리소스 해제
  Future<void> dispose() async {
    await _backgroundPlayer.dispose();
  }
}

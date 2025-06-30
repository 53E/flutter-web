import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';

class DatabaseManager {
  static Database? _database;
  
  static Database get database {
    if (_database == null) {
      throw Exception('데이터베이스가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
    }
    return _database!;
  }
  
  static Future<void> initialize() async {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      final dbPath = path.join(Directory.current.path, 'word_chain_game.db');
      
      _database = await openDatabase(
        dbPath,
        version: 4, // 버전 업데이트
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // used_words 컬럼 추가
            await db.execute('ALTER TABLE game_sessions ADD COLUMN used_words TEXT DEFAULT ""');
            print('✅ 데이터베이스 스키마 업데이트 완료');
          }
          if (oldVersion < 3) {
            // player_turns 컬럼 추가
            await db.execute('ALTER TABLE game_sessions ADD COLUMN player_turns INTEGER DEFAULT 0');
            print('✅ player_turns 컬럼 추가 완료');
          }
          if (oldVersion < 4) {
            // ai_turn_count 컬럼 추가
            await db.execute('ALTER TABLE game_sessions ADD COLUMN ai_turn_count INTEGER DEFAULT 0');
            print('✅ ai_turn_count 컬럼 추가 완료');
          }
        },
      );
      
      // 한국어 단어 파일에서 로드
      await _loadKoreanWordsFromFile();
      
      print('✅ SQLite 데이터베이스 초기화 완료: $dbPath');
    } catch (e) {
      print('❌ 데이터베이스 초기화 실패: $e');
      rethrow;
    }
  }
  
  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT UNIQUE NOT NULL,
        first_char TEXT NOT NULL,
        last_char TEXT NOT NULL,
        frequency INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_sessions (
        id TEXT PRIMARY KEY,
        player_name TEXT,
        current_stage INTEGER DEFAULT 1,
        score INTEGER DEFAULT 0,
        player_turns INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        used_words TEXT DEFAULT '',
        ai_turn_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        ended_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rankings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_name TEXT NOT NULL,
        score INTEGER NOT NULL,
        stage_reached INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    print('✅ 모든 테이블 생성 완료');
  }
  
  static Future<void> _loadKoreanWordsFromFile() async {
    try {
      // 기존 단어가 있는지 확인
      final result = await database.rawQuery('SELECT COUNT(*) as count FROM words');
      final count = result.first['count'] as int;
      
      if (count > 0) {
        print('✅ 단어 데이터가 이미 존재합니다 ($count개)');
        return;
      }
      
      // txt 파일 경로
      final filePath = path.join(Directory.current.path, 'assets', 'korean_words.txt');
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('⚠️ korean_words.txt 파일을 찾을 수 없습니다: $filePath');
        print('📂 backend/assets/ 폴더에 korean_words.txt 파일을 추가해주세요');
        await _insertDefaultWords();
        return;
      }
      
      print('📖 한국어 단어 파일 로딩 중...');
      print('📂 파일 경로: $filePath');
      
      // 파일 읽기
      final lines = await file.readAsLines(encoding: utf8);
      final validWords = <String>[];
      
      // 유효한 단어만 필터링
      for (String line in lines) {
        final word = line.trim();
        if (word.isNotEmpty && word.length >= 2 && _isKorean(word)) {
          validWords.add(word);
        }
      }
      
      if (validWords.isEmpty) {
        print('⚠️ 유효한 한국어 단어를 찾을 수 없습니다');
        await _insertDefaultWords();
        return;
      }
      
      print('🔄 ${validWords.length}개 단어를 데이터베이스에 저장 중...');
      
      // 배치로 단어 삽입 (성능 최적화)
      final batchSize = 1000;
      for (int i = 0; i < validWords.length; i += batchSize) {
        final batch = database.batch();
        final endIndex = (i + batchSize < validWords.length) ? i + batchSize : validWords.length;
        
        for (int j = i; j < endIndex; j++) {
          final word = validWords[j];
          final firstChar = word[0];
          final lastChar = word[word.length - 1];
          
          batch.insert(
            'words',
            {
              'word': word,
              'first_char': firstChar,
              'last_char': lastChar,
              'frequency': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        
        await batch.commit(noResult: true);
        print('📝 진행률: ${((endIndex / validWords.length) * 100).toStringAsFixed(1)}% (${endIndex}/${validWords.length})');
      }
      
      // 최종 결과 확인
      final finalResult = await database.rawQuery('SELECT COUNT(*) as count FROM words');
      final finalCount = finalResult.first['count'] as int;
      
      print('✅ 한국어 단어 $finalCount개 로드 완료!');
      print('🎮 이제 모든 한국어 단어를 끝말잇기에서 사용할 수 있습니다!');
      
    } catch (e) {
      print('❌ 한국어 단어 파일 로드 실패: $e');
      print('🔄 기본 단어로 대체합니다...');
      await _insertDefaultWords();
    }
  }
  
  // 한국어 문자 확인
  static bool _isKorean(String text) {
    final koreanRegex = RegExp(r'^[가-힣]+$');
    return koreanRegex.hasMatch(text);
  }
  
  // 기본 단어들 (파일이 없을 때 대체용)
  static Future<void> _insertDefaultWords() async {
    final testWords = [
      '사과', '과일', '일요일', '일반', '반찬', '찬물', '물고기', '기차', '차량', '량심',
      '심장', '장미', '미소', '소나무', '무지개', '개구리', '리본', '본격', '격투', '투자',
      '자동차', '차돌박이', '이상', '상어', '어린이', '이발소', '소금', '금요일', '일기', '기억',
      '학교', '교실', '실내', '내일', '일찍', '찍기', '기분', '분노', '노래', '래퍼',
      '컴퓨터', '터미널', '널리', '리더', '더블', '블루', '우산', '산책', '책상', '상자'
    ];
    
    final batch = database.batch();
    
    for (String word in testWords) {
      final firstChar = word[0];
      final lastChar = word[word.length - 1];
      
      batch.insert(
        'words',
        {
          'word': word,
          'first_char': firstChar,
          'last_char': lastChar,
          'frequency': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    
    await batch.commit(noResult: true);
    
    final result = await database.rawQuery('SELECT COUNT(*) as count FROM words');
    final count = result.first['count'] as int;
    print('✅ 기본 단어 $count개 삽입 완료');
  }
  
  static Future<List<Map<String, dynamic>>> select(String query, [List<dynamic>? params]) async {
    return await database.rawQuery(query, params);
  }
  
  static Future<void> execute(String query, [List<dynamic>? params]) async {
    await database.rawQuery(query, params);
  }
  
  static Future<void> close() async {
    await _database?.close();
    _database = null;
    print('✅ 데이터베이스 연결 종료');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum CharacterState {
  idle,    // 기본 대기 상태
  attack,  // 공격(타이핑) 상태
  death,   // 죽는/패배 상태
}

enum CharacterType {
  player,
  enemy,
}

class CharacterImage extends StatefulWidget {
  final CharacterType type;
  final CharacterState state;
  final double? width;
  final double? height;
  final bool isActive; // 현재 턴인지 여부

  const CharacterImage({
    super.key,
    required this.type,
    required this.state,
    this.width,
    this.height,
    this.isActive = false,
  });

  @override
  State<CharacterImage> createState() => _CharacterImageState();
}

class _CharacterImageState extends State<CharacterImage>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _attackController;
  late AnimationController _deathController;
  late AnimationController _activeController;

  @override
  void initState() {
    super.initState();
    
    // 숨쉬기 애니메이션 (기본 상태)
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // 공격 애니메이션
    _attackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 죽는 애니메이션
    _deathController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 활성 상태 애니메이션 (현재 턴)
    _activeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(CharacterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 상태 변경에 따른 애니메이션 처리
    if (oldWidget.state != widget.state) {
      _handleStateChange();
    }

    // 활성 상태 변경
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _activeController.repeat();
      } else {
        _activeController.stop();
      }
    }
  }

  void _handleStateChange() {
    switch (widget.state) {
      case CharacterState.idle:
        _attackController.reset();
        _deathController.reset();
        _breathingController.repeat(reverse: true);
        break;
      case CharacterState.attack:
        _breathingController.stop();
        _attackController.forward().then((_) {
          // 공격 애니메이션 완료 후 idle로 자동 복귀하지 않음
          // 상위 위젯에서 제어
        });
        break;
      case CharacterState.death:
        _breathingController.stop();
        _attackController.stop();
        _activeController.stop();
        _deathController.forward();
        break;
    }
  }

  String _getImagePath() {
    final String characterType = widget.type == CharacterType.player ? 'player' : 'enemy';
    final String stateName = widget.state.name; // idle, attack, death
    return 'assets/images/characters/$characterType/$stateName.png';
  }

  Widget _buildFallbackIcon() {
    IconData iconData;
    Color iconColor;

    switch (widget.type) {
      case CharacterType.player:
        iconData = Icons.person;
        iconColor = const Color(0xFF6C63FF);
        break;
      case CharacterType.enemy:
        iconData = Icons.smart_toy;
        iconColor = const Color(0xFFFF6B6B);
        break;
    }

    // 상태에 따른 색상 변경
    switch (widget.state) {
      case CharacterState.attack:
        iconColor = const Color(0xFF50E3C2);
        break;
      case CharacterState.death:
        iconColor = Colors.grey;
        break;
      case CharacterState.idle:
        break;
    }

    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 250,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: (widget.width ?? 200) * 0.4,
          color: iconColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathingController,
        _attackController,
        _deathController,
        _activeController,
      ]),
      builder: (context, child) {
        // 기본 스케일
        double scale = 1.0;
        double rotation = 0.0;
        double opacity = 1.0;

        // 상태별 애니메이션 적용
        switch (widget.state) {
          case CharacterState.idle:
            // 숨쉬기 애니메이션
            scale = 1.0 + (_breathingController.value * 0.05);
            break;
          case CharacterState.attack:
            // 공격 애니메이션 (앞으로 돌진)
            scale = 1.0 + (_attackController.value * 0.2);
            if (widget.type == CharacterType.player) {
              rotation = _attackController.value * 0.1;
            } else {
              rotation = -_attackController.value * 0.1;
            }
            break;
          case CharacterState.death:
            // 죽는 애니메이션 (쓰러짐)
            scale = 1.0 - (_deathController.value * 0.3);
            opacity = 1.0 - (_deathController.value * 0.5);
            rotation = _deathController.value * 0.3;
            break;
        }

        // 활성 상태 애니메이션 (빛나는 효과)
        if (widget.isActive && widget.state != CharacterState.death) {
          scale *= 1.0 + (_activeController.value * 0.03);
        }

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: widget.width ?? 200,
                height: widget.height ?? 250,
                decoration: widget.isActive && widget.state != CharacterState.death
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.type == CharacterType.player
                                    ? const Color(0xFF50E3C2)
                                    : const Color(0xFFFF6B6B))
                                .withOpacity(0.3 + _activeController.value * 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      )
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    _getImagePath(),
                    width: widget.width ?? 200,
                    height: widget.height ?? 250,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // 이미지 로드 실패 시 폴백 아이콘 표시
                      return _buildFallbackIcon();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _attackController.dispose();
    _deathController.dispose();
    _activeController.dispose();
    super.dispose();
  }
}

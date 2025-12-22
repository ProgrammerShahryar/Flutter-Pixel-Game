import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/Components/collision_block.dart';
import 'package:pixel_adventure/Components/player_hitbox.dart';
import 'package:pixel_adventure/Components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {idle, running, jumping, falling}


class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, KeyboardHandler{
  Player({this.character = 'Ninja Frog', position}) : super(position: position);
  String character;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  final double stepTime = 0.05;

  final double _gravity = 9.8;
  final double _jumpForce = 460;
  final double _terminalVelocity = 300;
  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  List<CollisionBlock> collisionBlocks = [];
  PlayerHitBox hitBox = PlayerHitBox(height: 20, width: 14, offsetX: 10, offsetY: 10);

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimation();
    // debugMode = true;
    add(RectangleHitbox(position: Vector2(hitBox.offsetX, hitBox.offsetY), size: Vector2(hitBox.width, hitBox.height)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerState();
    _updatePlayerMovement(dt);
    _checkHorizontalCollisions();
    _applyGravity(dt);
    _checkVerticalCollisions();
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight);
    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;
    hasJumped = keysPressed.contains(LogicalKeyboardKey.space) || keysPressed.contains(LogicalKeyboardKey.arrowUp);
   
    return super.onKeyEvent(event, keysPressed);
  }

  void _loadAllAnimation() {
    idleAnimation = _spriteAnimation('Idle', 11);

     runningAnimation = _spriteAnimation('Run', 12);

     jumpingAnimation = _spriteAnimation('Jump', 1);
     fallingAnimation = _spriteAnimation('Fall', 1);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
    };

    current = PlayerState.running;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/$character/$state (32x32).png'), SpriteAnimationData.sequenced(amount: amount, stepTime: stepTime, textureSize: Vector2.all(32)));
  }
  
  void _updatePlayerMovement(double dt) {
    if(hasJumped && isOnGround) _playerJump(dt);
    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }
  
  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;
    if(velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if(velocity.y < 0) {
      playerState = PlayerState.jumping;
    } else if (velocity.y > 0) {
      playerState = PlayerState.falling;
    } else

    if(velocity.x != 0) {
      playerState = PlayerState.running;
    }

    current = playerState;
  }
  
  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if(!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitBox.offsetX - hitBox.width;
          } else if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + width;
          }
        }
      }
    }
  }
  
  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }
  
  void _checkVerticalCollisions() {
  isOnGround = false;

  for (final block in collisionBlocks) {
    if (checkCollision(this, block)) {
      if (velocity.y > 0) {
        velocity.y = 0;
        position.y = block.y - hitBox.height - hitBox.offsetY; // use hitbox
        isOnGround = true;
        break;
      }
      if (!block.isPlatform && velocity.y < 0) {
        velocity.y = 0;
        position.y = block.y + block.height - hitBox.offsetY;
      }
    }
  }
}
}
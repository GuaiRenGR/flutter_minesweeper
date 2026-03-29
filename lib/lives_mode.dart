import 'package:flutter/material.dart';
import 'main.dart';

class LivesGamePage extends BaseGamePage {
  const LivesGamePage({
    super.key, 
    required super.difficulty, 
    required super.autoFlag
  });

  @override
  State<LivesGamePage> createState() => _LivesGamePageState();
}

class _LivesGamePageState extends BaseGameState<LivesGamePage> {
  @override
  void onGameInit() {
    lives = 3; 
  }

  @override
  bool onRevealMine(MineCell cell) {
    if (lives > 1) {
      lives--;
      cell.isFlagged = true;
      flagsPlaced++;
      cell.isRevealed = false; 
      return true; 
    }
    return false; 
  }

  @override
  Widget buildTopBarLeft() {
    return Row(
      children: List.generate(3, (index) {
        return Icon(
          index < lives ? Icons.favorite : Icons.favorite_border, 
          color: Colors.red,
          size: 28,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold('生命模式');
  }
}

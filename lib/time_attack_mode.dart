import 'package:flutter/material.dart';
import 'main.dart';

class TimeAttackGamePage extends BaseGamePage {
  const TimeAttackGamePage({
    super.key, 
    required super.difficulty, 
    required super.autoFlag
  });

  @override
  State<TimeAttackGamePage> createState() => _TimeAttackGamePageState();
}

class _TimeAttackGamePageState extends BaseGameState<TimeAttackGamePage> {
  @override
  void onGameInit() {
    timeValue = widget.difficulty.mines * 3;
  }

  @override
  void onTimerTick() {
    if (gameState != GameState.playing) {
      return;
    }
    setState(() {
      timeValue--;
      if (timeValue <= 0) {
        timeValue = 0;
        gameOver(false); 
      }
    });
  }

  @override
  void onRevealSafeCell() {
    timeValue += 1;
  }

  @override
  void onFlagMineCorrectly() {
    timeValue += 3;
  }

  @override
  Widget buildTopBarRight() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: timeValue < 10 ? Colors.red : Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 6),
          Text(timeValue.toString().padLeft(3, '0'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold('倒计时模式');
  }
}

import 'package:flutter/material.dart';
import 'main.dart';

class BlindGamePage extends BaseGamePage {
  const BlindGamePage({
    super.key, 
    required super.difficulty, 
    required super.autoFlag
  });

  @override
  State<BlindGamePage> createState() => _BlindGamePageState();
}

class _BlindGamePageState extends BaseGameState<BlindGamePage> {
  @override
  void onCellTapHook(int row, int col) {
    for (int r = 0; r < widget.difficulty.rows; r++) {
      for (int c = 0; c < widget.difficulty.cols; c++) {
        grid[r][c].isVisibleInBlind = (r - row).abs() <= 2 && (c - col).abs() <= 2;
      }
    }
  }

  @override
  void onGameOverHook(bool won) {
    for (int r = 0; r < widget.difficulty.rows; r++) {
      for (int c = 0; c < widget.difficulty.cols; c++) {
        grid[r][c].isVisibleInBlind = true;
      }
    }
  }

  @override
  Widget buildCellDecorator(MineCell cell, Widget child) {
    if (!cell.isVisibleInBlind) {
      return Container(
        width: cellSize,
        height: cellSize,
        color: Colors.black87,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold('盲步模式');
  }
}

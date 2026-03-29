import 'package:flutter/material.dart';
import 'main.dart'; 

class ClassicGamePage extends BaseGamePage {
  const ClassicGamePage({
    super.key, 
    required super.difficulty, 
    required super.autoFlag
  });

  @override
  State<ClassicGamePage> createState() => _ClassicGamePageState();
}

class _ClassicGamePageState extends BaseGameState<ClassicGamePage> {
  @override
  Widget build(BuildContext context) {
    return buildScaffold('经典模式');
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

// 导入其他四个玩法的独立文件
import 'classic_mode.dart';
import 'blind_mode.dart';
import 'time_attack_mode.dart';
import 'lives_mode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material 3 扫雷',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ================= 模型与枚举 =================
class MineCell {
  final int row;
  final int col;
  bool isMine;
  int surroundingMines;
  bool isRevealed;
  bool isFlagged;
  bool isVisibleInBlind;

  MineCell({
    required this.row,
    required this.col,
    this.isMine = false,
    this.surroundingMines = 0,
    this.isRevealed = false,
    this.isFlagged = false,
    this.isVisibleInBlind = true,
  });
}

enum GameDifficulty {
  easy(9, 9, 10, '初级 (9x9, 10雷)'),
  medium(16, 16, 40, '中级 (16x16, 40雷)'),
  hard(16, 30, 99, '高级 (16x30, 99雷)');

  final int rows; final int cols; final int mines; final String label;
  const GameDifficulty(this.rows, this.cols, this.mines, this.label);
}

enum GameMode {
  classic('经典模式', '传统的扫雷体验，找出所有地雷。', Icons.grid_on),
  blind('盲步模式', '只有当前点击位置周围保持可见，考验你的记忆力！', Icons.visibility_off),
  timeAttack('倒计时模式', '与时间赛跑！翻开格子或正确标雷可增加时间。', Icons.timer),
  lives('生命模式', '拥有3次容错机会，踩雷扣除生命但不立即结束。', Icons.favorite);

  final String title; final String desc; final IconData icon;
  const GameMode(this.title, this.desc, this.icon);
}

enum GameState { idle, playing, won, lost }

// ================= 底栏主骨架 =================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [GameLobbyPage(), AboutPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.videogame_asset_outlined), selectedIcon: Icon(Icons.videogame_asset), label: '大厅'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: '关于'),
        ],
      ),
    );
  }
}

// ================= 游戏大厅页面 =================
class GameLobbyPage extends StatefulWidget {
  const GameLobbyPage({super.key});
  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> {
  GameDifficulty _selectedDifficulty = GameDifficulty.easy;
  GameMode _selectedMode = GameMode.classic;
  bool _autoFlagEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模式选择', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('设置', style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile(
              title: const Text('自动标记已知地雷', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('揭雷后，若数字周围未知格子数等同于该数字，自动插旗标记。'),
              value: _autoFlagEnabled,
              onChanged: (val) {
                setState(() {
                  _autoFlagEnabled = val;
                });
              },
              secondary: const Icon(Icons.auto_fix_high),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const SizedBox(height: 8),

            Text('选择尺寸与难度', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<GameDifficulty>(
              segments: GameDifficulty.values.map((d) => ButtonSegment(value: d, label: Text(d.name.toUpperCase()), tooltip: d.label)).toList(),
              selected: {_selectedDifficulty},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedDifficulty = set.first;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(_selectedDifficulty.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            ),
            const SizedBox(height: 12),

            Text('选择玩法', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...GameMode.values.map((mode) {
              final isSelected = _selectedMode == mode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _selectedMode = mode;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : Theme.of(context).cardColor,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(mode.icon, size: 32, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mode.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(mode.desc, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('开始游戏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Widget page;
                  switch (_selectedMode) {
                    case GameMode.classic: page = ClassicGamePage(difficulty: _selectedDifficulty, autoFlag: _autoFlagEnabled); break;
                    case GameMode.blind: page = BlindGamePage(difficulty: _selectedDifficulty, autoFlag: _autoFlagEnabled); break;
                    case GameMode.timeAttack: page = TimeAttackGamePage(difficulty: _selectedDifficulty, autoFlag: _autoFlagEnabled); break;
                    case GameMode.lives: page = LivesGamePage(difficulty: _selectedDifficulty, autoFlag: _autoFlagEnabled); break;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 关于页面 =================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('关于应用', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(32)),
                  child: Icon(Icons.grid_on, size: 50, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text('Flutter 扫雷 Pro', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('Version 3.0.0', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0, color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: const Column(
              children: [
                ListTile(leading: Icon(Icons.person_outline), title: Text('开发者'), subtitle: Text('StarNguyen with AI')),
                Divider(height: 1, indent: 60),
                ListTile(leading: Icon(Icons.description_outlined), title: Text('许可证'), subtitle: Text('MIT License')),
                Divider(height: 1, indent: 60),
                ListTile(leading: Icon(Icons.code), title: Text('开源仓库'), subtitle: Text('github.com/GuaiRenGr/flutter_minesweeper'), trailing: Icon(Icons.open_in_new)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0, color: theme.colorScheme.tertiaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.lightbulb_outline, color: theme.colorScheme.onTertiaryContainer), const SizedBox(width: 8), Text('操作贴士', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 12),
                  Text('• 长按/电脑右键：手动标记地雷\n• 双击/点击已翻开数字：和弦排雷\n• 地图支持双指自由缩放和平移\n• 开启"自动标雷"可极大简化后期操作', style: TextStyle(color: theme.colorScheme.onTertiaryContainer, height: 1.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= 游戏底层核心基类 =================
abstract class BaseGamePage extends StatefulWidget {
  final GameDifficulty difficulty;
  final bool autoFlag;
  const BaseGamePage({super.key, required this.difficulty, required this.autoFlag});
}

abstract class BaseGameState<T extends BaseGamePage> extends State<T> {
  late List<List<MineCell>> grid;
  int flagsPlaced = 0;
  GameState gameState = GameState.idle;
  Timer? timer;
  int timeValue = 0;
  int lives = 1;

  final double cellSize = 32.0;
  final TransformationController transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    initGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    transformationController.dispose();
    super.dispose();
  }

  void initGame() {
    timer?.cancel();
    setState(() {
      gameState = GameState.idle;
      flagsPlaced = 0;
      timeValue = 0;
      lives = 1;
      grid = List.generate(
        widget.difficulty.rows,
        (row) => List.generate(widget.difficulty.cols, (col) => MineCell(row: row, col: col)),
      );
      onGameInit();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitGridToScreen();
    });
  }

  void _fitGridToScreen() {
    if (!mounted) {
      return;
    }
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height - kToolbarHeight - 120;
    final gridW = widget.difficulty.cols * cellSize;
    final gridH = widget.difficulty.rows * cellSize;
    
    final scale = (min(screenW / (gridW + 32), screenH / (gridH + 32))).clamp(0.2, 1.5);
    final dx = (screenW - gridW * scale) / 2;
    final dy = (screenH - gridH * scale) / 2;

    // 终极兼容写法：直接操作底层对角线实现缩放，操作第3列实现平移
    // 100% 避免任何 API 废弃和参数变动引起的报错
    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setTranslationRaw(dx, dy, 0.0);

    transformationController.value = matrix;
  }

  // --- 提供给子类的重写钩子 (Hooks) ---
  void onGameInit() {}
  
  void onTimerTick() {
    if (gameState != GameState.playing) {
      return;
    }
    setState(() { 
      if (timeValue < 999) {
        timeValue++; 
      }
    });
  }

  void onCellTapHook(int row, int col) {}
  void onRevealSafeCell() {}
  void onFlagMineCorrectly() {}
  bool onRevealMine(MineCell cell) { return false; } 
  void onGameOverHook(bool won) {}
  
  Widget buildTopBarLeft() => _buildInfoChip(Icons.flag, Colors.red, (widget.difficulty.mines - flagsPlaced).toString());
  Widget buildTopBarRight() => _buildInfoChip(Icons.timer, Theme.of(context).colorScheme.primary, timeValue.toString().padLeft(3, '0'));
  Widget buildCellDecorator(MineCell cell, Widget child) => child;

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      onTimerTick();
    });
  }

  void _generateMines(int avoidRow, int avoidCol) {
    final random = Random();
    int placed = 0;
    while (placed < widget.difficulty.mines) {
      final r = random.nextInt(widget.difficulty.rows);
      final c = random.nextInt(widget.difficulty.cols);
      if ((r - avoidRow).abs() <= 1 && (c - avoidCol).abs() <= 1) {
        continue;
      }
      if (!grid[r][c].isMine) {
        grid[r][c].isMine = true;
        placed++;
      }
    }
    for (int r = 0; r < widget.difficulty.rows; r++) {
      for (int c = 0; c < widget.difficulty.cols; c++) {
        if (!grid[r][c].isMine) {
          grid[r][c].surroundingMines = getSurroundingCells(r, c).where((cell) => cell.isMine).length;
        }
      }
    }
  }

  List<MineCell> getSurroundingCells(int row, int col) {
    List<MineCell> cells = [];
    for (int r = max(0, row - 1); r <= min(row + 1, widget.difficulty.rows - 1); r++) {
      for (int c = max(0, col - 1); c <= min(col + 1, widget.difficulty.cols - 1); c++) {
        if (r == row && c == col) {
          continue;
        }
        cells.add(grid[r][c]);
      }
    }
    return cells;
  }

  void _autoFlagPass() {
    if (!widget.autoFlag) {
      return;
    }
    bool changed;
    do {
      changed = false;
      for (int r = 0; r < widget.difficulty.rows; r++) {
        for (int c = 0; c < widget.difficulty.cols; c++) {
          final cell = grid[r][c];
          if (cell.isRevealed && cell.surroundingMines > 0) {
            final neighbors = getSurroundingCells(r, c);
            final unrevealed = neighbors.where((n) => !n.isRevealed).toList();
            if (unrevealed.length == cell.surroundingMines) {
              for (var n in unrevealed) {
                if (!n.isFlagged) {
                  n.isFlagged = true;
                  flagsPlaced++;
                  changed = true;
                  if (n.isMine) {
                    onFlagMineCorrectly();
                  }
                }
              }
            }
          }
        }
      }
    } while (changed);
  }

  void onCellTap(int row, int col) {
    if (gameState == GameState.won || gameState == GameState.lost) {
      return;
    }
    final cell = grid[row][col];
    if (cell.isFlagged) {
      return;
    }

    if (gameState == GameState.idle) {
      gameState = GameState.playing;
      _generateMines(row, col);
      startTimer();
    }

    setState(() {
      onCellTapHook(row, col);
    });

    if (cell.isRevealed) {
      if (cell.surroundingMines > 0) {
        _chordCell(row, col);
      }
      return;
    }

    _revealCell(row, col);
  }

  void onCellRightClick(int row, int col) {
    if (gameState == GameState.won || gameState == GameState.lost) {
      return;
    }
    final cell = grid[row][col];
    if (cell.isRevealed) {
      return;
    }
    setState(() {
      cell.isFlagged = !cell.isFlagged;
      flagsPlaced += cell.isFlagged ? 1 : -1;
      if (cell.isFlagged && cell.isMine) {
        onFlagMineCorrectly();
      }
    });
  }

  void _chordCell(int row, int col) {
    final cell = grid[row][col];
    final neighbors = getSurroundingCells(row, col);
    if (neighbors.where((c) => c.isFlagged).length == cell.surroundingMines) {
      for (var n in neighbors) {
        if (!n.isRevealed && !n.isFlagged) {
          _revealCell(n.row, n.col);
        }
      }
    }
  }

  void _revealCell(int row, int col) {
    final cell = grid[row][col];
    if (cell.isRevealed || cell.isFlagged) {
      return;
    }

    setState(() {
      cell.isRevealed = true;
      if (cell.isMine) {
        if (!onRevealMine(cell)) {
          gameOver(false);
          return;
        }
      } else {
        onRevealSafeCell();
      }

      if (cell.surroundingMines == 0 && !cell.isMine) {
        for (var n in getSurroundingCells(row, col)) {
          _revealCell(n.row, n.col);
        }
      }

      _autoFlagPass();

      if (checkWin()) {
        gameOver(true);
      }
    });
  }

  bool checkWin() {
    int revealed = 0;
    for (int r = 0; r < widget.difficulty.rows; r++) {
      for (int c = 0; c < widget.difficulty.cols; c++) {
        if (grid[r][c].isRevealed) {
          revealed++;
        }
      }
    }
    return revealed == (widget.difficulty.rows * widget.difficulty.cols - widget.difficulty.mines);
  }

  void gameOver(bool won) {
    timer?.cancel();
    gameState = won ? GameState.won : GameState.lost;
    onGameOverHook(won);
    for (int r = 0; r < widget.difficulty.rows; r++) {
      for (int c = 0; c < widget.difficulty.cols; c++) {
        final cell = grid[r][c];
        if (won && cell.isMine) {
          cell.isFlagged = true;
        } else if (!won && cell.isMine && !cell.isFlagged) {
          cell.isRevealed = true;
        }
      }
    }
    setState(() {
      if (won) {
        flagsPlaced = widget.difficulty.mines;
      }
    });
  }

  Widget _buildInfoChip(IconData icon, Color iconColor, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [Icon(icon, color: iconColor, size: 20), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'))]),
    );
  }

  Widget _buildTopBar() {
    String emoji = gameState == GameState.won ? '😎' : (gameState == GameState.lost ? '😵' : '😊');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildTopBarLeft(),
          GestureDetector(onTap: initGame, child: Text(emoji, style: const TextStyle(fontSize: 28))),
          buildTopBarRight(),
        ],
      ),
    );
  }

  Widget buildScaffold(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title - ${widget.difficulty.name.toUpperCase()}', style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            tooltip: '重新开始', 
            onPressed: () { initGame(); }
          )
        ],
      ),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: 0.2, maxScale: 4.0, constrained: false,
              boundaryMargin: EdgeInsets.all(MediaQuery.of(context).size.width),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.difficulty.rows, (r) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.difficulty.cols, (c) => _buildCellGrid(grid[r][c]))
                  )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellGrid(MineCell cell) {
    Widget content;
    Color bgColor = Theme.of(context).colorScheme.surface;
    if (!cell.isRevealed) {
      bgColor = Colors.grey.shade400;
      if (cell.isFlagged) {
        content = Icon(gameState == GameState.lost && !cell.isMine ? Icons.close : Icons.flag, color: Colors.red, size: 22);
      } else {
        content = const SizedBox();
      }
    } else {
      bgColor = Theme.of(context).scaffoldBackgroundColor;
      if (cell.isMine) {
        bgColor = Colors.red.shade400; content = const Icon(Icons.brightness_high, color: Colors.white, size: 24);
      } else if (cell.surroundingMines > 0) {
        final colors = [Colors.transparent, Colors.blue.shade700, Colors.green.shade700, Colors.red.shade700, Colors.purple.shade700, Colors.brown.shade700, Colors.cyan.shade700, Colors.black, Colors.grey.shade700];
        content = Text('${cell.surroundingMines}', style: TextStyle(color: colors[cell.surroundingMines], fontWeight: FontWeight.w900, fontSize: 22));
      } else {
        content = const SizedBox();
      }
    }

    Widget cellBox = GestureDetector(
      onTap: () => onCellTap(cell.row, cell.col),
      onLongPress: () => onCellRightClick(cell.row, cell.col),
      onSecondaryTap: () => onCellRightClick(cell.row, cell.col),
      child: Container(
        width: cellSize, height: cellSize,
        decoration: BoxDecoration(
          color: bgColor,
          border: !cell.isRevealed 
            ? Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 2), 
                left: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 2), 
                right: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 2), 
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 2)
              )
            : Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
        child: Center(child: content),
      ),
    );
    return buildCellDecorator(cell, cellBox);
  }
}

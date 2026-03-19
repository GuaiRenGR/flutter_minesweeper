import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
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
  bool isVisibleInBlind; // 盲步模式下的可见性

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

  final int rows;
  final int cols;
  final int mines;
  final String label;

  const GameDifficulty(this.rows, this.cols, this.mines, this.label);
}

enum GameMode {
  classic('经典模式', '传统的扫雷体验，找出所有地雷。', Icons.grid_on),
  blind('盲步模式', '只有当前点击位置周围保持可见，考验你的记忆力！', Icons.visibility_off),
  timeAttack('倒计时模式', '与时间赛跑！翻开格子或正确标雷可增加时间。', Icons.timer),
  lives('生命模式', '拥有3次容错机会，踩雷扣除生命但不立即结束。', Icons.favorite);

  final String title;
  final String desc;
  final IconData icon;

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
  
  // 切换页面的控制器
  void _switchPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const GameLobbyPage(),
      const AboutPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.videogame_asset_outlined),
            selectedIcon: Icon(Icons.videogame_asset),
            label: '大厅',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: '关于',
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模式选择', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择尺寸与难度', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<GameDifficulty>(
              segments: GameDifficulty.values.map((d) {
                return ButtonSegment<GameDifficulty>(
                  value: d,
                  label: Text(d.name.toUpperCase()),
                  tooltip: d.label,
                );
              }).toList(),
              selected: {_selectedDifficulty},
              onSelectionChanged: (Set<GameDifficulty> newSelection) {
                setState(() {
                  _selectedDifficulty = newSelection.first;
                });
              },
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
              child: Text(_selectedDifficulty.label, 
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            ),

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
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                          : Theme.of(context).cardColor,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(mode.icon, size: 32, 
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mode.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(mode.desc, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GamePlayPage(
                        difficulty: _selectedDifficulty,
                        mode: _selectedMode,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 实际游戏页面 =================
class GamePlayPage extends StatefulWidget {
  final GameDifficulty difficulty;
  final GameMode mode;

  const GamePlayPage({
    super.key,
    required this.difficulty,
    required this.mode,
  });

  @override
  State<GamePlayPage> createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage> {
  late List<List<MineCell>> _grid;
  int _flagsPlaced = 0;
  GameState _gameState = GameState.idle;
  
  Timer? _timer;
  int _timeValue = 0; // 经典/生命模式为已用时间，倒计时模式为剩余时间
  int _lives = 3; // 生命模式下的红心

  final double _cellSize = 32.0;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  void _initGame() {
    _timer?.cancel();
    setState(() {
      _gameState = GameState.idle;
      _flagsPlaced = 0;
      _lives = widget.mode == GameMode.lives ? 3 : 1;
      
      // 时间初始化
      if (widget.mode == GameMode.timeAttack) {
        _timeValue = widget.difficulty.mines * 3; // 基础时间，比如初级30秒，高级297秒
      } else {
        _timeValue = 0;
      }

      _grid = List.generate(
        widget.difficulty.rows,
        (row) => List.generate(
          widget.difficulty.cols,
          (col) => MineCell(row: row, col: col),
        ),
      );
    });

    // 延迟一帧后调整视角适应屏幕
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitGridToScreen();
    });
  }

  void _fitGridToScreen() {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight - 120; // 减去AppBar和顶部状态栏预估高度
    
    final gridWidth = widget.difficulty.cols * _cellSize;
    final gridHeight = widget.difficulty.rows * _cellSize;

    final scaleX = screenWidth / (gridWidth + 32); // 预留一点边距
    final scaleY = screenHeight / (gridHeight + 32);
    final scale = min(scaleX, scaleY).clamp(0.2, 1.5); // 限制最小最大初始缩放

    // 居中偏移量
    final dx = (screenWidth - gridWidth * scale) / 2;
    final dy = (screenHeight - gridHeight * scale) / 2;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState != GameState.playing) return;
      
      setState(() {
        if (widget.mode == GameMode.timeAttack) {
          _timeValue--;
          if (_timeValue <= 0) {
            _timeValue = 0;
            _gameOver(false);
          }
        } else {
          if (_timeValue < 999) _timeValue++;
        }
      });
    });
  }

  void _generateMines(int avoidRow, int avoidCol) {
    final random = Random();
    int minesPlaced = 0;

    while (minesPlaced < widget.difficulty.mines) {
      final row = random.nextInt(widget.difficulty.rows);
      final col = random.nextInt(widget.difficulty.cols);

      if ((row - avoidRow).abs() <= 1 && (col - avoidCol).abs() <= 1) {
        continue; // 首次点击周围3x3安全
      }
      if (!_grid[row][col].isMine) {
        _grid[row][col].isMine = true;
        minesPlaced++;
      }
    }

    // 计算周围雷数
    for (int row = 0; row < widget.difficulty.rows; row++) {
      for (int col = 0; col < widget.difficulty.cols; col++) {
        if (!_grid[row][col].isMine) {
          _grid[row][col].surroundingMines = _getSurroundingCells(row, col).where((c) => c.isMine).length;
        }
      }
    }
  }

  List<MineCell> _getSurroundingCells(int row, int col) {
    List<MineCell> cells = [];
    for (int r = max(0, row - 1); r <= min(row + 1, widget.difficulty.rows - 1); r++) {
      for (int c = max(0, col - 1); c <= min(col + 1, widget.difficulty.cols - 1); c++) {
        if (r == row && c == col) continue;
        cells.add(_grid[r][c]);
      }
    }
    return cells;
  }

  void _updateBlindModeVisibility(int focusRow, int focusCol) {
    if (widget.mode != GameMode.blind) return;
    for (int r = 0; r < widget.difficulty.rows; r++) {
      for (int c = 0; c < widget.difficulty.cols; c++) {
        // 只可见点击位置周围距离<=2的区域
        _grid[r][c].isVisibleInBlind = (r - focusRow).abs() <= 2 && (c - focusCol).abs() <= 2;
      }
    }
  }

  void _onCellTap(int row, int col) {
    if (_gameState == GameState.won || _gameState == GameState.lost) return;
    final cell = _grid[row][col];
    if (cell.isFlagged) return;

    if (_gameState == GameState.idle) {
      _gameState = GameState.playing;
      _generateMines(row, col);
      _startTimer();
    }

    setState(() {
      _updateBlindModeVisibility(row, col);
    });

    if (cell.isRevealed) {
      if (cell.surroundingMines > 0) {
        _chordCell(row, col);
      }
      return;
    }

    _revealCell(row, col);
  }

  void _onCellRightClickOrLongPress(int row, int col) {
    if (_gameState == GameState.won || _gameState == GameState.lost) return;
    final cell = _grid[row][col];
    if (cell.isRevealed) return;

    setState(() {
      cell.isFlagged = !cell.isFlagged;
      _flagsPlaced += cell.isFlagged ? 1 : -1;

      // 倒计时模式正确标记地雷奖励时间
      if (widget.mode == GameMode.timeAttack && cell.isFlagged && cell.isMine) {
         _timeValue += 2; 
      }
    });
  }

  void _chordCell(int row, int col) {
    final cell = _grid[row][col];
    final neighbors = _getSurroundingCells(row, col);
    final flaggedCount = neighbors.where((c) => c.isFlagged).length;

    if (flaggedCount == cell.surroundingMines) {
      for (var neighbor in neighbors) {
        if (!neighbor.isRevealed && !neighbor.isFlagged) {
          _revealCell(neighbor.row, neighbor.col);
        }
      }
    }
  }

  void _revealCell(int row, int col) {
    final cell = _grid[row][col];
    if (cell.isRevealed || cell.isFlagged) return;

    setState(() {
      cell.isRevealed = true;

      if (cell.isMine) {
        if (widget.mode == GameMode.lives && _lives > 1) {
          // 生命模式扣血不断游戏
          _lives--;
          cell.isFlagged = true; // 自动标雷避免重复踩
          _flagsPlaced++;
          cell.isRevealed = false; // 隐藏翻开状态，转为标记状态
          return;
        } else {
          _gameOver(false);
          return;
        }
      }

      // 倒计时模式成功翻开安全格奖励时间
      if (widget.mode == GameMode.timeAttack) {
        _timeValue += 1;
      }

      if (cell.surroundingMines == 0) {
        final neighbors = _getSurroundingCells(row, col);
        for (var neighbor in neighbors) {
          _revealCell(neighbor.row, neighbor.col);
        }
      }

      if (_checkWin()) {
        _gameOver(true);
      }
    });
  }

  bool _checkWin() {
    int revealedCount = 0;
    for (int row = 0; row < widget.difficulty.rows; row++) {
      for (int col = 0; col < widget.difficulty.cols; col++) {
        if (_grid[row][col].isRevealed) revealedCount++;
      }
    }
    return revealedCount == (widget.difficulty.rows * widget.difficulty.cols - widget.difficulty.mines);
  }

  void _gameOver(bool won) {
    _timer?.cancel();
    _gameState = won ? GameState.won : GameState.lost;

    for (int row = 0; row < widget.difficulty.rows; row++) {
      for (int col = 0; col < widget.difficulty.cols; col++) {
        final cell = _grid[row][col];
        cell.isVisibleInBlind = true; // 游戏结束时全部可见
        if (won && cell.isMine) {
          cell.isFlagged = true; 
        } else if (!won) {
          if (cell.isMine && !cell.isFlagged) {
            cell.isRevealed = true;
          }
        }
      }
    }
    setState(() {
      if (won) _flagsPlaced = widget.difficulty.mines;
    });
  }

  Widget _buildTopBar() {
    String emoji = '😊';
    if (_gameState == GameState.won) emoji = '😎';
    if (_gameState == GameState.lost) emoji = '😵';

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：剩余地雷 / 生命值
          if (widget.mode == GameMode.lives)
            Row(
              children: List.generate(3, (index) => 
                Icon(index < _lives ? Icons.favorite : Icons.favorite_border, color: Colors.red)
              ),
            )
          else
            _buildInfoChip(Icons.flag, Colors.red, (widget.difficulty.mines - _flagsPlaced).toString()),
          
          // 中间：表情重置按钮
          GestureDetector(
            onTap: _initGame,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          
          // 右侧：时间
          _buildInfoChip(
            widget.mode == GameMode.timeAttack ? Icons.timer_outlined : Icons.timer, 
            widget.mode == GameMode.timeAttack && _timeValue < 10 ? Colors.red : theme.colorScheme.primary, 
            _timeValue.toString().padLeft(3, '0')
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, Color iconColor, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildCell(MineCell cell) {
    Widget content;
    Color bgColor = Theme.of(context).colorScheme.surface;
    Color borderColor = Theme.of(context).colorScheme.outlineVariant;
    
    // 盲步模式黑暗遮罩
    if (widget.mode == GameMode.blind && !cell.isVisibleInBlind) {
      return Container(
        width: _cellSize,
        height: _cellSize,
        color: Colors.black87,
      );
    }

    if (!cell.isRevealed) {
      // 未翻开格子绘制类原生凸起效果
      Border border = Border(
        top: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
        left: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
        right: BorderSide(color: Colors.black.withOpacity(0.3), width: 2),
        bottom: BorderSide(color: Colors.black.withOpacity(0.3), width: 2),
      );
      bgColor = Colors.grey.shade400; // 经典扫雷灰
      
      if (cell.isFlagged) {
        if (_gameState == GameState.lost && !cell.isMine) {
          content = const Icon(Icons.close, color: Colors.red, size: 22); // 标错的雷
        } else {
          content = const Icon(Icons.flag, color: Colors.red, size: 22);
        }
      } else {
        content = const SizedBox();
      }

      return GestureDetector(
        onTap: () => _onCellTap(cell.row, cell.col),
        onLongPress: () => _onCellRightClickOrLongPress(cell.row, cell.col),
        onSecondaryTap: () => _onCellRightClickOrLongPress(cell.row, cell.col),
        child: Container(
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(color: bgColor, border: border),
          child: Center(child: content),
        ),
      );
    } else {
      // 已翻开格子
      bgColor = Theme.of(context).scaffoldBackgroundColor;
      Border border = Border.all(color: borderColor, width: 0.5);

      if (cell.isMine) {
        bgColor = Colors.red.shade400;
        content = const Icon(Icons.brightness_high, color: Colors.white, size: 24); // 炸弹
      } else if (cell.surroundingMines > 0) {
        final colors = [
          Colors.transparent, Colors.blue.shade700, Colors.green.shade700, Colors.red.shade700,
          Colors.purple.shade700, Colors.brown.shade700, Colors.cyan.shade700, Colors.black, Colors.grey.shade700
        ];
        content = Text(
          '${cell.surroundingMines}',
          style: TextStyle(
            color: colors[cell.surroundingMines],
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        );
      } else {
        content = const SizedBox();
      }

      return GestureDetector(
        onTap: () => _onCellTap(cell.row, cell.col),
        onLongPress: () => _onCellRightClickOrLongPress(cell.row, cell.col),
        onSecondaryTap: () => _onCellRightClickOrLongPress(cell.row, cell.col),
        child: Container(
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(color: bgColor, border: border),
          child: Center(child: content),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode.title} - ${widget.difficulty.name.toUpperCase()}', 
          style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新开始',
            onPressed: _initGame,
          )
        ],
      ),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.2,
                maxScale: 4.0,
                constrained: false, // 允许超出屏幕边界进行缩放和平移
                boundaryMargin: EdgeInsets.all(MediaQuery.of(context).size.width), // 足够大的滑动边界
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.difficulty.rows, (row) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(widget.difficulty.cols, (col) {
                          return _buildCell(_grid[row][col]);
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= 关于页面 (Material 3 风格) =================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于应用', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 头部 App Icon 与名字
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(32), // MD3 特色大圆角
                  ),
                  child: Icon(Icons.grid_on, size: 50, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text('Material 3 扫雷', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Version 2.0.0', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // 信息卡片列表
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('开发者信息'),
                  subtitle: Text('StarNguyen with AI'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                const Divider(height: 1, indent: 60),
                const ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('许可证'),
                  subtitle: Text('MIT License'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('开源仓库'),
                  subtitle: const Text('github.com/GuaiRenGR/flutter_minesweeper'),
                  trailing: const Icon(Icons.open_in_new),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  onTap: () {
                    // 实际应用可调用 url_launcher
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 底部贴士卡片
          Card(
            elevation: 0,
            color: theme.colorScheme.tertiaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Text('操作贴士', style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('• 手机长按 / 电脑右键：标记地雷\n• 双击/点击已翻开的数字：自动和弦排雷\n• 地图支持双指自由缩放和平移\n• 尝试不同玩法模式体验别样乐趣',
                    style: TextStyle(color: theme.colorScheme.onTertiaryContainer, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

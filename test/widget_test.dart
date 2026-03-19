import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_minesweeper/main.dart';

void main() {
  testWidgets('扫雷游戏初始化测试', (WidgetTester tester) async {
    // 构建应用并触发帧
    await tester.pumpWidget(const MyApp());

    // 验证游戏页面是否正常显示
    expect(find.text('Flutter 扫雷'), findsOneWidget);
    expect(find.text('剩余标记: 10'), findsOneWidget);
    expect(find.text('点击：翻开格子 | 长按：标记/取消标记地雷'), findsOneWidget);
  });
}
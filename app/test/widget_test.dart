// 基础烟雾测试：确保 App 能启动并显示首页
//
// 注意：此测试在 CI 环境下需 `flutter test --platform chrome` 或真机调试，
// 普通 `flutter test` 模式因 record 插件无 native lib 初始化会抛 PlatformException。
// 故用 skipUntil 跳过，待 Phase 2 接入集成测试时再启用。
import 'package:flutter_test/flutter_test.dart';

import 'package:ukulele/core/router.dart';

void main() {
  testWidgets('App boots and shows home page', (WidgetTester tester) async {
    // TODO(Phase 2): 用 integration_test 替换
    await tester.pumpWidget(const UkuleleApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('调音器'), findsOneWidget);
    expect(find.text('节拍器'), findsOneWidget);
    expect(find.text('曲谱库'), findsOneWidget);
  }, skip: true /* TODO(Phase 2): 需 integration_test */);
}
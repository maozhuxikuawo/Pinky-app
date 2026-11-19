import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pinky_homework/main.dart';
import 'package:pinky_homework/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('privacy -> create child -> add task -> check off', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs, clock: () => DateTime(2026, 11, 18, 17));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PinkyApp(store: store));

    expect(find.text('隐私声明'), findsOneWidget);
    await tester.tap(find.byKey(const Key('privacy_agree')));
    await tester.pumpAndSettle();
    expect(prefs.getBool('privacy_accepted_v1'), isTrue);

    await tester.enterText(find.byKey(const Key('child_name')), '乐乐');
    await tester.scrollUntilVisible(find.byKey(const Key('child_save')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('child_save')));
    await tester.pumpAndSettle();
    expect(find.text('乐乐'), findsWidgets);

    await tester.tap(find.byKey(const Key('add_task')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task_title')), '口算练习');
    await tester.tap(find.byKey(const Key('task_save')));
    await tester.pumpAndSettle();
    expect(find.text('口算练习'), findsOneWidget);

    final task = store.tasksFor(store.currentChild!.id, store.today).single;
    await tester.tap(find.byKey(Key('toggle_${task.id}')));
    await tester.pump(const Duration(seconds: 1));
    expect(task.done, isTrue);
    expect(find.text('今天的作业全部完成！'), findsOneWidget);
    expect(store.statsFor(task.childId).balance, 4);

    // Drain dialogs and timers.
    for (var i = 0; i < 6; i++) {
      final btn = find.byType(FilledButton);
      if (btn.evaluate().isEmpty) break;
      await tester.tap(btn.last, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('privacy accepted state is remembered', (tester) async {
    SharedPreferences.setMockInitialValues({'privacy_accepted_v1': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(PinkyApp(store: AppStore(prefs)));
    expect(find.text('隐私声明'), findsNothing);
    expect(find.text('先来创建第一位小朋友吧～'), findsOneWidget);
  });
}

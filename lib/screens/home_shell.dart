import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../theme.dart';
import 'child_edit_screen.dart';
import 'growth_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppStore>().currentChild!;
    final pages = [
      TodayScreen(key: ValueKey('today_${child.id}')),
      GrowthScreen(key: ValueKey('growth_${child.id}')),
      RewardsScreen(key: ValueKey('rewards_${child.id}')),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist_rounded), label: '作业'),
          NavigationDestination(icon: Icon(Icons.eco_outlined), selectedIcon: Icon(Icons.eco), label: '成长'),
          NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), selectedIcon: Icon(Icons.card_giftcard), label: '奖励'),
          NavigationDestination(icon: Icon(Icons.family_restroom_outlined), selectedIcon: Icon(Icons.family_restroom), label: '家长'),
        ],
      ),
    );
  }
}

/// Header with current child's avatar + name; tapping opens the child switcher.
class ChildHeader extends StatelessWidget {
  const ChildHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final child = store.currentChild!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          InkWell(
            key: const Key('child_switcher'),
            borderRadius: BorderRadius.circular(30),
            onTap: () => showChildSwitcher(context),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: child.color.withValues(alpha: 0.3),
                  child: Text(child.avatar, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 10),
                Text(child.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark)),
                const Icon(Icons.expand_more, color: textGrey),
              ]),
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

void showChildSwitcher(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (ctx) {
      final store = ctx.watch<AppStore>();
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('切换小朋友', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 8),
            for (final c in store.children)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: c.color.withValues(alpha: 0.3),
                  child: Text(c.avatar, style: const TextStyle(fontSize: 22)),
                ),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('⭐ ${store.statsFor(c.id).balance}   🔥 连续 ${store.statsFor(c.id).currentStreak} 天'),
                trailing: c.id == store.currentChild?.id ? Icon(Icons.check_circle, color: c.color) : null,
                onTap: () {
                  store.selectChild(c.id);
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF2EEF4), child: Icon(Icons.add, color: textGrey)),
              title: const Text('添加小朋友'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildEditScreen()));
              },
            ),
            const SizedBox(height: 8),
          ],
          ),
        ),
      );
    },
  );
}

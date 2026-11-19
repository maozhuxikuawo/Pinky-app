import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../theme.dart';
import 'child_edit_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Text('家长中心', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textDark)),
        ),
        const _Group('小朋友'),
        Card(
          child: Column(children: [
            for (final c in store.children)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: c.color.withValues(alpha: 0.3),
                  child: Text(c.avatar, style: const TextStyle(fontSize: 22)),
                ),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('累计完成 ${store.statsFor(c.id).totalDone} 项作业'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: textGrey),
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChildEditScreen(child: c))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: textGrey),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('删除「${c.name}」？'),
                          content: const Text('该小朋友的所有作业、星星和奖励记录都会被删除，且无法恢复。'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE57373)),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) store.deleteChild(c.id);
                    },
                  ),
                ]),
              ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF2EEF4), child: Icon(Icons.add, color: textGrey)),
              title: const Text('添加小朋友'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildEditScreen())),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const _Group('使用小贴士'),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '• 每完成一项作业可获得星星，当天全部完成再额外奖励 3 颗\n'
              '• 每天全部完成即算打卡成功，连续打卡可解锁徽章\n'
              '• 星星越多，成长小树长得越高\n'
              '• 在「奖励」页可以设置孩子喜欢的奖励，用星星兑换\n'
              '• 向左滑动作业可快速删除，点击作业可编辑',
              style: TextStyle(height: 1.8, color: textDark),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _Group('关于'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('隐私声明'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('版本'),
              trailing: Text('1.0.0', style: TextStyle(color: textGrey)),
            ),
          ]),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textGrey)),
      );
}

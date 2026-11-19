import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/celebrate.dart';
import 'home_shell.dart';

const _rewardEmojis = ['🎁', '📺', '🎮', '🍦', '🍭', '🧸', '🎡', '🌙', '📚', '🚲', '🎨', '🍕'];

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final child = store.currentChild!;
    final stats = store.statsFor(child.id);
    final rewards = store.rewardsFor(child.id);
    final history = store.redemptionsFor(child.id);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const Key('add_reward'),
        onPressed: () => _editReward(context, child.id),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const ChildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFC27A)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(children: [
                const Text('⭐', style: TextStyle(fontSize: 48)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('我的星星', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                  Text('${stats.balance}',
                      key: const Key('star_balance'),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: textDark)),
                ]),
                const Spacer(),
                const Text('完成作业赚星星\n星星可以换奖励',
                    textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: textDark, height: 1.5)),
              ]),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text('奖励商店', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark)),
          ),
          if (rewards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('还没有奖励，家长可以点右下角 + 添加', textAlign: TextAlign.center, style: TextStyle(color: textGrey)),
            ),
          for (final r in rewards)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
                  onLongPress: () => _editReward(context, child.id, reward: r),
                  leading: Text(r.emoji, style: const TextStyle(fontSize: 34)),
                  title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, color: textDark)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (stats.balance / r.cost).clamp(0, 1).toDouble(),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF3F0F4),
                        color: const Color(0xFFFFC94D),
                      ),
                    ),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(72, 40),
                        backgroundColor: stats.balance >= r.cost ? scheme.primary : const Color(0xFFE6E1E8),
                        foregroundColor: stats.balance >= r.cost ? Colors.white : textGrey,
                      ),
                      onPressed: () => _redeem(context, r, stats.balance),
                      child: Text('${r.cost}⭐'),
                    ),
                    IconButton(
                      onPressed: () => _editReward(context, child.id, reward: r),
                      icon: const Icon(Icons.more_vert, color: textGrey),
                    ),
                  ]),
                ),
              ),
            ),
          if (history.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('兑换记录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark)),
            ),
            for (final h in history.take(20))
              ListTile(
                dense: true,
                leading: Text(h.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(h.title),
                subtitle: Text('${h.at.month}月${h.at.day}日 ${h.at.hour.toString().padLeft(2, '0')}:${h.at.minute.toString().padLeft(2, '0')}'),
                trailing: Text('-${h.cost}⭐', style: const TextStyle(color: textGrey, fontWeight: FontWeight.w600)),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _redeem(BuildContext context, Reward r, int balance) async {
    if (balance < r.cost) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('还差 ${r.cost - balance} 颗星星，继续加油完成作业吧！')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('兑换 ${r.emoji} ${r.title}？'),
        content: Text('将使用 ${r.cost} 颗星星。请和爸爸妈妈确认后兑换哦～'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('再想想')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认兑换')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final store = context.read<AppStore>();
    if (!store.redeem(r)) return;
    await showCelebration(context, emoji: r.emoji, title: '兑换成功！', message: '「${r.title}」\n快去找爸爸妈妈领取奖励吧！');
    if (!context.mounted) return;
    await showAchievements(context, store.takeNewAchievements(r.childId));
  }

  void _editReward(BuildContext context, String childId, {Reward? reward}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _RewardEditor(childId: childId, reward: reward),
    );
  }
}

class _RewardEditor extends StatefulWidget {
  const _RewardEditor({required this.childId, this.reward});

  final String childId;
  final Reward? reward;

  @override
  State<_RewardEditor> createState() => _RewardEditorState();
}

class _RewardEditorState extends State<_RewardEditor> {
  late final _title = TextEditingController(text: widget.reward?.title ?? '');
  late String _emoji = widget.reward?.emoji ?? _rewardEmojis.first;
  late double _cost = (widget.reward?.cost ?? 20).toDouble();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final store = context.read<AppStore>();
    if (widget.reward == null) {
      store.addReward(widget.childId, title: title, emoji: _emoji, cost: _cost.round());
    } else {
      store.updateReward(widget.reward!, title: title, emoji: _emoji, cost: _cost.round());
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.reward != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(editing ? '编辑奖励' : '添加奖励',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark)),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _rewardEmojis)
                GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e == _emoji ? const Color(0xFFFFF3C4) : const Color(0xFFF6F3F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              maxLength: 20,
              autofocus: !editing,
              decoration: const InputDecoration(hintText: '奖励名称，例如：吃一次冰淇淋', counterText: ''),
            ),
            const SizedBox(height: 16),
            Text('需要 ${_cost.round()} 颗星星', style: const TextStyle(fontWeight: FontWeight.w700, color: textDark)),
            Slider(
              value: _cost,
              min: 5,
              max: 200,
              divisions: 39,
              label: '${_cost.round()}',
              onChanged: (v) => setState(() => _cost = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              if (editing) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 48),
                      foregroundColor: const Color(0xFFE57373),
                    ),
                    onPressed: () {
                      context.read<AppStore>().deleteReward(widget.reward!);
                      Navigator.pop(context);
                    },
                    child: const Text('删除'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(flex: 2, child: FilledButton(onPressed: _save, child: const Text('保存'))),
            ]),
          ],
        ),
      ),
    );
  }
}

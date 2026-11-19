import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../stats.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/celebrate.dart';
import 'home_shell.dart';

const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final child = store.currentChild!;
    final today = store.today;
    final day = _selected ?? today;
    final tasks = store.tasksFor(child.id, day);
    final stats = store.statsFor(child.id);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_task'),
        onPressed: () => showTaskEditor(context, child.id, _selected ?? store.today),
        icon: const Icon(Icons.add),
        label: const Text('添加作业', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ChildHeader(
              trailing: Row(children: [
                StarChip(text: '${stats.balance}'),
                const SizedBox(width: 6),
                StarChip(text: '${stats.currentStreak}天', icon: '🔥', color: const Color(0xFFFFE3D6)),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: _WeekStrip(
              selected: day,
              today: today,
              stats: stats,
              onSelect: (d) => setState(() => _selected = d == today ? null : d),
            ),
          ),
          SliverToBoxAdapter(child: _ProgressCard(day: day, today: today, tasks: tasks, stats: stats)),
          if (tasks.isEmpty)
            SliverToBoxAdapter(child: _EmptyState(childId: child.id, day: day))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverList.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _TaskTile(
                  key: ValueKey(tasks[i].id),
                  task: tasks[i],
                  onToggle: () => _toggle(tasks[i], day),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggle(HomeworkTask t, DateTime day) async {
    final store = context.read<AppStore>();
    if (day.isAfter(store.today)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('还没到这一天哦，到时候再来打卡吧～')));
      return;
    }
    if (t.done) {
      store.setDone(t, false);
      return;
    }
    final before = store.statsFor(t.childId);
    store.setDone(t, true);
    final after = store.statsFor(t.childId);
    final allDone = store.tasksFor(t.childId, day).every((e) => e.done);

    burstConfetti(context, particles: 18);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1500),
        content: Text('${randomCheer()} +${t.stars} ⭐'),
      ));

    if (allDone && after.perfectDays.length > before.perfectDays.length) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final isToday = dateKey(day) == dateKey(store.today);
      await showCelebration(
        context,
        emoji: '🏆',
        title: isToday ? '今天的作业全部完成！' : '这一天的作业全部完成！',
        message: '额外奖励 +$perfectDayBonus ⭐\n已连续打卡 ${after.currentStreak} 天，继续保持！',
      );
    }
    if (!mounted) return;
    await showAchievements(context, store.takeNewAchievements(t.childId));
    if (!mounted) return;
    if (after.level.index > before.level.index) {
      await showCelebration(
        context,
        emoji: after.level.emoji,
        title: '升级啦！${after.level.name}',
        message: '你的成长小树长大了，快去「成长」页看看吧！',
      );
    }
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selected, required this.today, required this.stats, required this.onSelect});

  final DateTime selected;
  final DateTime today;
  final ChildStats stats;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monday = DateTime(selected.year, selected.month, selected.day - (selected.weekday - 1));
    final isToday = dateKey(selected) == dateKey(today);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => onSelect(DateTime(selected.year, selected.month, selected.day - 7)),
                icon: const Icon(Icons.chevron_left, color: textGrey),
              ),
              Expanded(
                child: Text('${selected.year}年${selected.month}月',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark)),
              ),
              if (!isToday)
                TextButton(onPressed: () => onSelect(today), child: const Text('回到今天')),
              IconButton(
                onPressed: () => onSelect(DateTime(selected.year, selected.month, selected.day + 7)),
                icon: const Icon(Icons.chevron_right, color: textGrey),
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Builder(builder: (context) {
                  final d = DateTime(monday.year, monday.month, monday.day + i);
                  final key = dateKey(d);
                  final sel = key == dateKey(selected);
                  final isT = key == dateKey(today);
                  final mark = stats.perfectDays.contains(key)
                      ? '⭐'
                      : stats.partialDays.contains(key)
                          ? '•'
                          : '';
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelect(d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? scheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isT && !sel ? Border.all(color: scheme.primary, width: 1.5) : null,
                        ),
                        child: Column(children: [
                          Text(isT ? '今' : _weekdays[i],
                              style: TextStyle(fontSize: 12, color: sel ? Colors.white : textGrey)),
                          const SizedBox(height: 4),
                          Text('${d.day}',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700, color: sel ? Colors.white : textDark)),
                          SizedBox(
                            height: 16,
                            child: Text(mark,
                                style: TextStyle(fontSize: 11, color: sel ? Colors.white : scheme.primary)),
                          ),
                        ]),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.day, required this.today, required this.tasks, required this.stats});

  final DateTime day;
  final DateTime today;
  final List<HomeworkTask> tasks;
  final ChildStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = tasks.where((t) => t.done).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : done / total;
    final isToday = dateKey(day) == dateKey(today);
    final label = isToday ? '今天' : '${day.month}月${day.day}日';
    final String tip;
    if (total == 0) {
      tip = '还没有作业，先添加吧';
    } else if (done == total) {
      tip = '全部完成啦，真了不起！🎉';
    } else if (done == 0) {
      tip = '开始第一项吧，加油！💪';
    } else {
      tip = '还差 ${total - done} 项就全部完成啦！';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [scheme.primary.withValues(alpha: 0.85), scheme.tertiary.withValues(alpha: 0.75)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(fit: StackFit.expand, children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 500),
                  builder: (_, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.35),
                    color: Colors.white,
                  ),
                ),
                Center(
                  child: Text(done == total && total > 0 ? '🏆' : '$done/$total',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ]),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$label的作业', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(tip, style: const TextStyle(fontSize: 14, color: Colors.white)),
                  if (total > 0 && done < total) ...[
                    const SizedBox(height: 6),
                    Text('全部完成额外奖励 +$perfectDayBonus ⭐',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({super.key, required this.task, required this.onToggle});

  final HomeworkTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final subject = subjectByName(task.subject);
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: const Color(0xFFFF8A80), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _deleteWithUndo(context, task),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showTaskEditor(context, task.childId, parseDateKey(task.date), task: task),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: subject.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: Text(subject.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: task.done ? textGrey : textDark,
                          decoration: task.done ? TextDecoration.lineThrough : null,
                          decorationColor: textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${subject.name} · 奖励 ${'⭐' * task.stars}',
                          style: const TextStyle(fontSize: 12, color: textGrey)),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('toggle_${task.id}'),
                  iconSize: 40,
                  onPressed: onToggle,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: task.done
                        ? Icon(Icons.check_circle_rounded, key: const ValueKey(1), color: scheme.primary)
                        : const Icon(Icons.radio_button_unchecked_rounded, key: ValueKey(0), color: Color(0xFFD9D3DD)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _deleteWithUndo(BuildContext context, HomeworkTask task) =>
    _deleteTask(context.read<AppStore>(), ScaffoldMessenger.of(context), task);

void _deleteTask(AppStore store, ScaffoldMessengerState messenger, HomeworkTask task) {
  store.deleteTask(task);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('已删除「${task.title}」'),
      action: SnackBarAction(label: '撤销', onPressed: () => store.restoreTask(task)),
    ));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.childId, required this.day});

  final String childId;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final prev = store.previousDayWithTasks(childId, day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          const Text('这一天还没有作业', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark)),
          const SizedBox(height: 6),
          const Text('点击右下角「添加作业」开始吧', style: TextStyle(color: textGrey)),
          if (prev != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('copy_prev'),
              onPressed: () {
                final n = store.copyTasks(childId, prev, day);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制 $n 项作业')));
              },
              icon: const Icon(Icons.copy_all_rounded),
              label: Text('复制 ${prev.month}月${prev.day}日 的作业'),
            ),
          ],
        ],
      ),
    );
  }
}

const _suggestions = <String, List<String>>{
  '语文': ['生字抄写', '背诵课文', '朗读课文', '语文练习册', '写日记'],
  '数学': ['口算练习', '数学练习册', '应用题', '预习新课'],
  '英语': ['读英语课文', '单词听写', '英语听力 15 分钟', '英语练习册'],
  '阅读': ['课外阅读 30 分钟', '亲子共读', '读绘本'],
  '练字': ['练字一页', '描红练习'],
  '运动': ['跳绳 200 个', '户外运动 30 分钟', '拍球 100 个'],
  '其他': ['整理书包', '收拾书桌', '练琴 20 分钟', '画一幅画'],
};

Future<void> showTaskEditor(BuildContext context, String childId, DateTime day, {HomeworkTask? task}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _TaskEditor(childId: childId, day: day, task: task),
  );
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({required this.childId, required this.day, this.task});

  final String childId;
  final DateTime day;
  final HomeworkTask? task;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final _title = TextEditingController(text: widget.task?.title ?? '');
  late String _subject = widget.task?.subject ?? subjects.first.name;
  late int _stars = widget.task?.stars ?? 1;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写作业内容')));
      return;
    }
    final store = context.read<AppStore>();
    if (widget.task == null) {
      store.addTask(widget.childId, widget.day, title: title, subject: _subject, stars: _stars);
    } else {
      store.updateTask(widget.task!, title: title, subject: _subject, stars: _stars);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.task != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(editing ? '编辑作业' : '添加作业',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark)),
            ),
            const SizedBox(height: 16),
            const Text('科目', style: TextStyle(fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in subjects)
                  ChoiceChip(
                    label: Text('${s.emoji} ${s.name}'),
                    selected: _subject == s.name,
                    onSelected: (_) => setState(() => _subject = s.name),
                    selectedColor: s.color.withValues(alpha: 0.35),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('作业内容', style: TextStyle(fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 8),
            TextField(
              key: const Key('task_title'),
              controller: _title,
              autofocus: !editing,
              maxLength: 30,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(hintText: '例如：数学练习册第 12 页', counterText: ''),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in _suggestions[_subject] ?? const <String>[])
                  ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 13)),
                    onPressed: () => setState(() => _title.text = s),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('完成后奖励', style: TextStyle(fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('⭐')),
                ButtonSegment(value: 2, label: Text('⭐⭐')),
                ButtonSegment(value: 3, label: Text('⭐⭐⭐')),
              ],
              selected: {_stars},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _stars = s.first),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (editing) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 48),
                        foregroundColor: const Color(0xFFE57373),
                        side: const BorderSide(color: Color(0xFFFFCDD2)),
                      ),
                      onPressed: () {
                        final store = context.read<AppStore>();
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        _deleteTask(store, messenger, widget.task!);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('删除'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(key: const Key('task_save'), onPressed: _save, child: const Text('保存')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

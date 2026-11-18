import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../stats.dart';
import '../store.dart';
import '../theme.dart';
import 'home_shell.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final child = store.currentChild!;
    final stats = store.statsFor(child.id);
    final unlocked = store.unlockedFor(child.id);
    final month = _month ?? DateTime(store.today.year, store.today.month);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const ChildHeader(),
        _TreeCard(stats: stats),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            _StatBox(emoji: '⭐', value: '${stats.earnedStars}', label: '累计星星'),
            _StatBox(emoji: '✅', value: '${stats.totalDone}', label: '完成作业'),
            _StatBox(emoji: '🔥', value: '${stats.currentStreak}', label: '连续天数'),
            _StatBox(emoji: '🏅', value: '${stats.bestStreak}', label: '最长连续'),
          ]),
        ),
        _SectionTitle('打卡日历'),
        _CalendarCard(
          month: month,
          today: store.today,
          stats: stats,
          onChange: (m) => setState(() => _month = m),
        ),
        _SectionTitle('我的徽章  ${unlocked.length}/${achievements.length}'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.9,
            children: [
              for (final a in achievements) _BadgeTile(a: a, unlocked: unlocked.contains(a.id)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({required this.stats});

  final ChildStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = stats.level;
    final next = stats.nextLevel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F6FF), Color(0xFFE8F8EC)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text('Lv.${level.index + 1}  ${level.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Text(level.emoji, style: TextStyle(fontSize: 72 + level.index * 6.0)),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: stats.levelProgress,
                minHeight: 12,
                backgroundColor: Colors.white,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              next == null
                  ? '已经是最高等级啦，太厉害了！'
                  : '再获得 ${next.minStars - stats.earnedStars} 颗星星，就能变成「${next.emoji} ${next.name}」',
              style: const TextStyle(fontSize: 13, color: textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
              Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
            ]),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark)),
      );
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.month, required this.today, required this.stats, required this.onChange});

  final DateTime month;
  final DateTime today;
  final ChildStats stats;
  final ValueChanged<DateTime> onChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = lead + daysInMonth;
    final perfectThisMonth =
        stats.perfectDays.where((d) => d.startsWith('${month.year}-${month.month.toString().padLeft(2, '0')}')).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            children: [
              Row(children: [
                IconButton(
                    onPressed: () => onChange(DateTime(month.year, month.month - 1)),
                    icon: const Icon(Icons.chevron_left, color: textGrey)),
                Expanded(
                  child: Column(children: [
                    Text('${month.year}年${month.month}月',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: textDark)),
                    Text('本月完美打卡 $perfectThisMonth 天', style: const TextStyle(fontSize: 12, color: textGrey)),
                  ]),
                ),
                IconButton(
                    onPressed: () => onChange(DateTime(month.year, month.month + 1)),
                    icon: const Icon(Icons.chevron_right, color: textGrey)),
              ]),
              Row(children: [
                for (final w in ['一', '二', '三', '四', '五', '六', '日'])
                  Expanded(
                      child: Center(child: Text(w, style: const TextStyle(fontSize: 12, color: textGrey)))),
              ]),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (cells / 7).ceil() * 7,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4),
                itemBuilder: (_, i) {
                  final dayNum = i - lead + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();
                  final key = dateKey(DateTime(month.year, month.month, dayNum));
                  final isToday = key == dateKey(today);
                  final perfect = stats.perfectDays.contains(key);
                  final partial = stats.partialDays.contains(key);
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: perfect
                          ? const Color(0xFFFFF3C4)
                          : partial
                              ? scheme.primary.withValues(alpha: 0.12)
                              : null,
                      shape: BoxShape.circle,
                      border: isToday ? Border.all(color: scheme.primary, width: 1.5) : null,
                    ),
                    alignment: Alignment.center,
                    child: perfect
                        ? const Text('⭐', style: TextStyle(fontSize: 18))
                        : Text('$dayNum',
                            style: TextStyle(fontSize: 13, color: partial ? scheme.primary : textDark)),
                  );
                },
              ),
              const SizedBox(height: 4),
              const Text('⭐ 全部完成   ○ 部分完成', style: TextStyle(fontSize: 11, color: textGrey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.a, required this.unlocked});

  final Achievement a;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: unlocked ? Colors.white : const Color(0xFFF3F0F4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('${a.title}：${a.desc}${unlocked ? '（已获得）' : ''}'))),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: ColorFiltered(
                  colorFilter: unlocked
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix([
                          0.33, 0.33, 0.33, 0, 0, //
                          0.33, 0.33, 0.33, 0, 0, //
                          0.33, 0.33, 0.33, 0, 0, //
                          0, 0, 0, 1, 0,
                        ]),
                  child: Text(a.emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 6),
              Text(a.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: unlocked ? textDark : textGrey)),
              if (!unlocked) const Icon(Icons.lock_outline, size: 14, color: textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

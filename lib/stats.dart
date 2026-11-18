import 'models.dart';

const perfectDayBonus = 3;

class Level {
  final int index;
  final String emoji;
  final String name;
  final int minStars;
  const Level(this.index, this.emoji, this.name, this.minStars);
}

const levels = <Level>[
  Level(0, '🌰', '小种子', 0),
  Level(1, '🌱', '冒出小芽', 10),
  Level(2, '🌿', '长出叶子', 30),
  Level(3, '🪴', '茁壮小苗', 60),
  Level(4, '🌳', '小小树', 100),
  Level(5, '🌸', '开满鲜花', 160),
  Level(6, '🍎', '结出果实', 250),
  Level(7, '🏰', '魔法森林', 400),
];

class ChildStats {
  final int totalDone;
  final int earnedStars;
  final int spentStars;
  final int currentStreak;
  final int bestStreak;
  final Set<String> perfectDays;
  final Set<String> partialDays;
  final int fastDays;
  final int redemptions;

  ChildStats({
    required this.totalDone,
    required this.earnedStars,
    required this.spentStars,
    required this.currentStreak,
    required this.bestStreak,
    required this.perfectDays,
    required this.partialDays,
    required this.fastDays,
    required this.redemptions,
  });

  int get balance => earnedStars - spentStars;

  Level get level => levels.lastWhere((l) => earnedStars >= l.minStars);

  Level? get nextLevel => level.index + 1 < levels.length ? levels[level.index + 1] : null;

  double get levelProgress {
    final next = nextLevel;
    if (next == null) return 1;
    return (earnedStars - level.minStars) / (next.minStars - level.minStars);
  }

  static ChildStats compute({
    required List<HomeworkTask> tasks,
    required List<Redemption> redemptions,
    required DateTime today,
  }) {
    final byDate = <String, List<HomeworkTask>>{};
    for (final t in tasks) {
      byDate.putIfAbsent(t.date, () => []).add(t);
    }
    final todayKey = dateKey(today);
    final perfect = <String>{};
    final partial = <String>{};
    var fast = 0;
    var earned = 0;
    var totalDone = 0;
    byDate.forEach((date, list) {
      final done = list.where((t) => t.done).toList();
      totalDone += done.length;
      earned += done.fold(0, (s, t) => s + t.stars);
      if (date.compareTo(todayKey) > 0) return;
      if (list.isNotEmpty && done.length == list.length) {
        perfect.add(date);
        earned += perfectDayBonus;
        final day = parseDateKey(date);
        final lastDone = done.map((t) => t.doneAt).whereType<DateTime>();
        if (lastDone.isNotEmpty &&
            lastDone.every((d) => dayOnly(d) == day && d.hour < 19)) {
          fast++;
        }
      } else if (done.isNotEmpty) {
        partial.add(date);
      }
    });

    // Current streak: consecutive perfect days ending today, or ending yesterday
    // if today isn't finished yet (so the streak isn't "lost" mid-day).
    var cursor = dayOnly(today);
    if (!perfect.contains(dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var current = 0;
    while (perfect.contains(dateKey(cursor))) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    final sorted = perfect.map(parseDateKey).toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in sorted) {
      if (prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = d;
    }

    return ChildStats(
      totalDone: totalDone,
      earnedStars: earned,
      spentStars: redemptions.fold(0, (s, r) => s + r.cost),
      currentStreak: current,
      bestStreak: best,
      perfectDays: perfect,
      partialDays: partial,
      fastDays: fast,
      redemptions: redemptions.length,
    );
  }
}

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String desc;
  final bool Function(ChildStats s) test;
  const Achievement(this.id, this.emoji, this.title, this.desc, this.test);
}

final achievements = <Achievement>[
  Achievement('first_task', '🎉', '初次打卡', '完成第 1 项作业', (s) => s.totalDone >= 1),
  Achievement('perfect_1', '💯', '完美一天', '完成一天的全部作业', (s) => s.perfectDays.isNotEmpty),
  Achievement('streak_3', '🔥', '坚持三天', '连续 3 天完成全部作业', (s) => s.bestStreak >= 3),
  Achievement('streak_7', '🌈', '一周之星', '连续 7 天完成全部作业', (s) => s.bestStreak >= 7),
  Achievement('streak_14', '🚀', '两周达人', '连续 14 天完成全部作业', (s) => s.bestStreak >= 14),
  Achievement('streak_30', '👑', '月度冠军', '连续 30 天完成全部作业', (s) => s.bestStreak >= 30),
  Achievement('tasks_10', '🐝', '勤劳小蜜蜂', '累计完成 10 项作业', (s) => s.totalDone >= 10),
  Achievement('tasks_50', '🦉', '学习小能手', '累计完成 50 项作业', (s) => s.totalDone >= 50),
  Achievement('tasks_100', '🏅', '百项达人', '累计完成 100 项作业', (s) => s.totalDone >= 100),
  Achievement('tasks_300', '🎓', '小小学霸', '累计完成 300 项作业', (s) => s.totalDone >= 300),
  Achievement('stars_50', '⭐', '星星收集者', '累计获得 50 颗星星', (s) => s.earnedStars >= 50),
  Achievement('stars_200', '🌟', '闪亮之星', '累计获得 200 颗星星', (s) => s.earnedStars >= 200),
  Achievement('stars_500', '✨', '银河之星', '累计获得 500 颗星星', (s) => s.earnedStars >= 500),
  Achievement('fast_3', '⚡', '效率闪电侠', '3 天在晚上 7 点前完成全部作业', (s) => s.fastDays >= 3),
  Achievement('redeem_1', '🎁', '第一份奖励', '第一次用星星兑换奖励', (s) => s.redemptions >= 1),
];

const cheers = [
  '太棒啦！',
  '真厉害！',
  '继续加油！',
  '你是最棒的！',
  '又进步了一点点！',
  '超级认真！',
  '为你点赞！',
];

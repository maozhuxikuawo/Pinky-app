import 'package:flutter_test/flutter_test.dart';
import 'package:pinky_homework/models.dart';
import 'package:pinky_homework/stats.dart';

HomeworkTask t(String date, {bool done = false, int stars = 1, DateTime? doneAt}) => HomeworkTask(
      id: newId(),
      childId: 'c',
      date: date,
      title: 'x',
      subject: '数学',
      stars: stars,
      done: done,
      doneAt: doneAt ?? (done ? parseDateKey(date).add(const Duration(hours: 18)) : null),
    );

void main() {
  final today = DateTime(2026, 11, 18);

  test('stars include per-task stars and perfect-day bonus', () {
    final s = ChildStats.compute(
      tasks: [t('2026-11-18', done: true, stars: 2), t('2026-11-18', done: true), t('2026-11-17', done: true), t('2026-11-17')],
      redemptions: [],
      today: today,
    );
    expect(s.totalDone, 3);
    expect(s.earnedStars, 2 + 1 + 1 + perfectDayBonus);
    expect(s.perfectDays, {'2026-11-18'});
    expect(s.partialDays, {'2026-11-17'});
  });

  test('current streak survives an unfinished today and breaks on gaps', () {
    final s = ChildStats.compute(
      tasks: [
        t('2026-11-18'),
        t('2026-11-17', done: true),
        t('2026-11-16', done: true),
        t('2026-11-15', done: true),
        t('2026-11-13', done: true),
        t('2026-11-12', done: true),
        t('2026-11-11', done: true),
        t('2026-11-10', done: true),
      ],
      redemptions: [],
      today: today,
    );
    expect(s.currentStreak, 3);
    expect(s.bestStreak, 4);
  });

  test('streak crosses month boundaries', () {
    final s = ChildStats.compute(
      tasks: [t('2026-12-01', done: true), t('2026-11-30', done: true)],
      redemptions: [],
      today: DateTime(2026, 12, 1),
    );
    expect(s.currentStreak, 2);
    expect(s.bestStreak, 2);
  });

  test('future days do not count as perfect days', () {
    final s = ChildStats.compute(tasks: [t('2026-11-20', done: true)], redemptions: [], today: today);
    expect(s.perfectDays, isEmpty);
  });

  test('balance subtracts redemptions and level advances', () {
    final tasks = [for (var i = 0; i < 10; i++) t('2026-11-18', done: true)];
    final s = ChildStats.compute(
      tasks: tasks,
      redemptions: [Redemption(id: '1', childId: 'c', title: 'r', emoji: '🎁', cost: 5, at: today)],
      today: today,
    );
    expect(s.earnedStars, 13);
    expect(s.balance, 8);
    expect(s.level.index, 1);
    expect(achievements.where((a) => a.test(s)).map((a) => a.id), containsAll(['first_task', 'perfect_1', 'tasks_10', 'redeem_1']));
  });
}

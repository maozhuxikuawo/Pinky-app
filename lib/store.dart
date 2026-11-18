import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'stats.dart';

class AppStore extends ChangeNotifier {
  AppStore(this._prefs, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _load();
  }

  static const _kPrivacy = 'privacy_accepted_v1';
  static const _kChildren = 'children';
  static const _kTasks = 'tasks';
  static const _kRewards = 'rewards';
  static const _kRedemptions = 'redemptions';
  static const _kSeen = 'seen_achievements';
  static const _kCurrent = 'current_child';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  bool privacyAccepted = false;
  List<Child> children = [];
  List<HomeworkTask> _tasks = [];
  List<Reward> _rewards = [];
  List<Redemption> _redemptions = [];
  Map<String, Set<String>> _seen = {};
  String? _currentId;

  DateTime get today => dayOnly(_clock());
  DateTime get now => _clock();

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) f) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => f(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void _load() {
    privacyAccepted = _prefs.getBool(_kPrivacy) ?? false;
    children = _readList(_kChildren, Child.fromJson);
    _tasks = _readList(_kTasks, HomeworkTask.fromJson);
    _rewards = _readList(_kRewards, Reward.fromJson);
    _redemptions = _readList(_kRedemptions, Redemption.fromJson);
    final seenRaw = _prefs.getString(_kSeen);
    if (seenRaw != null) {
      try {
        _seen = (jsonDecode(seenRaw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as List).cast<String>().toSet()));
      } catch (_) {}
    }
    _currentId = _prefs.getString(_kCurrent);
  }

  Future<void> _save() async {
    await Future.wait([
      _prefs.setString(_kChildren, jsonEncode(children.map((e) => e.toJson()).toList())),
      _prefs.setString(_kTasks, jsonEncode(_tasks.map((e) => e.toJson()).toList())),
      _prefs.setString(_kRewards, jsonEncode(_rewards.map((e) => e.toJson()).toList())),
      _prefs.setString(_kRedemptions, jsonEncode(_redemptions.map((e) => e.toJson()).toList())),
      _prefs.setString(_kSeen, jsonEncode(_seen.map((k, v) => MapEntry(k, v.toList())))),
      if (_currentId != null) _prefs.setString(_kCurrent, _currentId!) else _prefs.remove(_kCurrent),
    ]);
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---------- 隐私 ----------
  Future<void> acceptPrivacy() async {
    privacyAccepted = true;
    notifyListeners();
    await _prefs.setBool(_kPrivacy, true);
  }

  // ---------- 小朋友 ----------
  Child? get currentChild {
    if (children.isEmpty) return null;
    return children.firstWhere((c) => c.id == _currentId, orElse: () => children.first);
  }

  void selectChild(String id) {
    _currentId = id;
    _changed();
  }

  Child addChild({required String name, required String avatar, required int colorIndex}) {
    final c = Child(id: newId(), name: name, avatar: avatar, colorIndex: colorIndex);
    children.add(c);
    _currentId = c.id;
    _rewards.addAll([
      Reward(id: newId(), childId: c.id, title: '看动画片 20 分钟', emoji: '📺', cost: 10),
      Reward(id: newId(), childId: c.id, title: '晚睡 15 分钟', emoji: '🌙', cost: 15),
      Reward(id: newId(), childId: c.id, title: '周末去公园玩', emoji: '🎡', cost: 30),
      Reward(id: newId(), childId: c.id, title: '挑选一个小玩具', emoji: '🧸', cost: 50),
    ]);
    _changed();
    return c;
  }

  void updateChild(Child c, {required String name, required String avatar, required int colorIndex}) {
    c
      ..name = name
      ..avatar = avatar
      ..colorIndex = colorIndex;
    _changed();
  }

  void deleteChild(String id) {
    children.removeWhere((c) => c.id == id);
    _tasks.removeWhere((t) => t.childId == id);
    _rewards.removeWhere((r) => r.childId == id);
    _redemptions.removeWhere((r) => r.childId == id);
    _seen.remove(id);
    if (_currentId == id) _currentId = children.isEmpty ? null : children.first.id;
    _changed();
  }

  // ---------- 作业 ----------
  List<HomeworkTask> tasksFor(String childId, DateTime day) {
    final key = dateKey(day);
    return _tasks.where((t) => t.childId == childId && t.date == key).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<HomeworkTask> allTasksFor(String childId) => _tasks.where((t) => t.childId == childId).toList();

  HomeworkTask addTask(String childId, DateTime day, {required String title, required String subject, int stars = 1}) {
    final existing = tasksFor(childId, day);
    final t = HomeworkTask(
      id: newId(),
      childId: childId,
      date: dateKey(day),
      title: title,
      subject: subject,
      stars: stars,
      order: existing.isEmpty ? 0 : existing.last.order + 1,
    );
    _tasks.add(t);
    _changed();
    return t;
  }

  void updateTask(HomeworkTask t, {required String title, required String subject, required int stars}) {
    t
      ..title = title
      ..subject = subject
      ..stars = stars;
    _changed();
  }

  void deleteTask(HomeworkTask t) {
    _tasks.removeWhere((e) => e.id == t.id);
    _changed();
  }

  void restoreTask(HomeworkTask t) {
    _tasks.add(t);
    _changed();
  }

  void setDone(HomeworkTask t, bool done) {
    t
      ..done = done
      ..doneAt = done ? now : null;
    _changed();
  }

  /// The most recent day before [day] that has homework, used for "copy last homework".
  DateTime? previousDayWithTasks(String childId, DateTime day) {
    final key = dateKey(day);
    final dates = _tasks.where((t) => t.childId == childId && t.date.compareTo(key) < 0).map((t) => t.date).toSet().toList()
      ..sort();
    return dates.isEmpty ? null : parseDateKey(dates.last);
  }

  int copyTasks(String childId, DateTime from, DateTime to) {
    final src = tasksFor(childId, from);
    for (final s in src) {
      addTask(childId, to, title: s.title, subject: s.subject, stars: s.stars);
    }
    return src.length;
  }

  // ---------- 奖励 ----------
  List<Reward> rewardsFor(String childId) =>
      _rewards.where((r) => r.childId == childId).toList()..sort((a, b) => a.cost.compareTo(b.cost));

  List<Redemption> redemptionsFor(String childId) =>
      _redemptions.where((r) => r.childId == childId).toList()..sort((a, b) => b.at.compareTo(a.at));

  void addReward(String childId, {required String title, required String emoji, required int cost}) {
    _rewards.add(Reward(id: newId(), childId: childId, title: title, emoji: emoji, cost: cost));
    _changed();
  }

  void updateReward(Reward r, {required String title, required String emoji, required int cost}) {
    r
      ..title = title
      ..emoji = emoji
      ..cost = cost;
    _changed();
  }

  void deleteReward(Reward r) {
    _rewards.removeWhere((e) => e.id == r.id);
    _changed();
  }

  bool redeem(Reward r) {
    if (statsFor(r.childId).balance < r.cost) return false;
    _redemptions.add(Redemption(id: newId(), childId: r.childId, title: r.title, emoji: r.emoji, cost: r.cost, at: now));
    _changed();
    return true;
  }

  // ---------- 统计与成就 ----------
  ChildStats statsFor(String childId) => ChildStats.compute(
        tasks: allTasksFor(childId),
        redemptions: _redemptions.where((r) => r.childId == childId).toList(),
        today: today,
      );

  Set<String> unlockedFor(String childId) {
    final s = statsFor(childId);
    return {..._seen[childId] ?? {}, ...achievements.where((a) => a.test(s)).map((a) => a.id)};
  }

  /// Returns achievements newly earned since the last call and marks them as seen.
  List<Achievement> takeNewAchievements(String childId) {
    final s = statsFor(childId);
    final seen = _seen.putIfAbsent(childId, () => {});
    final fresh = achievements.where((a) => !seen.contains(a.id) && a.test(s)).toList();
    if (fresh.isNotEmpty) {
      seen.addAll(fresh.map((a) => a.id));
      _save();
    }
    return fresh;
  }
}

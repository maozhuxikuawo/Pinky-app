import 'package:material_ui/material_ui.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String newId() => '${DateTime.now().microsecondsSinceEpoch}${_seq++}';
int _seq = 0;

const childAvatars = ['🐰', '🐻', '🐼', '🦊', '🐱', '🐶', '🐯', '🦁', '🐸', '🐧', '🦄', '🐨', '🐹', '🐵', '🐳'];

const childColors = <Color>[
  Color(0xFFFF8FB1), // 粉
  Color(0xFF6EC6FF), // 蓝
  Color(0xFF7ED6A5), // 绿
  Color(0xFFFFB86B), // 橙
  Color(0xFFB39DFF), // 紫
  Color(0xFFFFD54F), // 黄
];

class Subject {
  final String name;
  final String emoji;
  final Color color;
  const Subject(this.name, this.emoji, this.color);
}

const subjects = <Subject>[
  Subject('语文', '📖', Color(0xFFFF8A80)),
  Subject('数学', '🔢', Color(0xFF64B5F6)),
  Subject('英语', '🔤', Color(0xFF81C784)),
  Subject('阅读', '📚', Color(0xFFFFB74D)),
  Subject('练字', '✍️', Color(0xFFBA68C8)),
  Subject('运动', '⚽', Color(0xFF4DD0E1)),
  Subject('其他', '🌟', Color(0xFFFFD54F)),
];

Subject subjectByName(String name) =>
    subjects.firstWhere((s) => s.name == name, orElse: () => subjects.last);

class Child {
  final String id;
  String name;
  String avatar;
  int colorIndex;

  Child({required this.id, required this.name, required this.avatar, required this.colorIndex});

  Color get color => childColors[colorIndex % childColors.length];

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar': avatar, 'color': colorIndex};

  factory Child.fromJson(Map<String, dynamic> j) => Child(
        id: j['id'] as String,
        name: j['name'] as String,
        avatar: j['avatar'] as String,
        colorIndex: (j['color'] as num?)?.toInt() ?? 0,
      );
}

class HomeworkTask {
  final String id;
  final String childId;
  final String date;
  String title;
  String subject;
  int stars;
  bool done;
  DateTime? doneAt;
  int order;

  HomeworkTask({
    required this.id,
    required this.childId,
    required this.date,
    required this.title,
    required this.subject,
    this.stars = 1,
    this.done = false,
    this.doneAt,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'date': date,
        'title': title,
        'subject': subject,
        'stars': stars,
        'done': done,
        'doneAt': doneAt?.toIso8601String(),
        'order': order,
      };

  factory HomeworkTask.fromJson(Map<String, dynamic> j) => HomeworkTask(
        id: j['id'] as String,
        childId: j['childId'] as String,
        date: j['date'] as String,
        title: j['title'] as String,
        subject: j['subject'] as String? ?? '其他',
        stars: (j['stars'] as num?)?.toInt() ?? 1,
        done: j['done'] as bool? ?? false,
        doneAt: j['doneAt'] == null ? null : DateTime.tryParse(j['doneAt'] as String),
        order: (j['order'] as num?)?.toInt() ?? 0,
      );
}

class Reward {
  final String id;
  final String childId;
  String title;
  String emoji;
  int cost;

  Reward({required this.id, required this.childId, required this.title, required this.emoji, required this.cost});

  Map<String, dynamic> toJson() => {'id': id, 'childId': childId, 'title': title, 'emoji': emoji, 'cost': cost};

  factory Reward.fromJson(Map<String, dynamic> j) => Reward(
        id: j['id'] as String,
        childId: j['childId'] as String,
        title: j['title'] as String,
        emoji: j['emoji'] as String? ?? '🎁',
        cost: (j['cost'] as num).toInt(),
      );
}

class Redemption {
  final String id;
  final String childId;
  final String title;
  final String emoji;
  final int cost;
  final DateTime at;

  Redemption({required this.id, required this.childId, required this.title, required this.emoji, required this.cost, required this.at});

  Map<String, dynamic> toJson() =>
      {'id': id, 'childId': childId, 'title': title, 'emoji': emoji, 'cost': cost, 'at': at.toIso8601String()};

  factory Redemption.fromJson(Map<String, dynamic> j) => Redemption(
        id: j['id'] as String,
        childId: j['childId'] as String,
        title: j['title'] as String,
        emoji: j['emoji'] as String? ?? '🎁',
        cost: (j['cost'] as num).toInt(),
        at: DateTime.parse(j['at'] as String),
      );
}

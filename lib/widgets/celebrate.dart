import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:material_ui/material_ui.dart';

import '../stats.dart';
import '../theme.dart';

final _rand = Random();

String randomCheer() => cheers[_rand.nextInt(cheers.length)];

/// A full-screen confetti burst that removes itself when done.
void burstConfetti(BuildContext context, {int particles = 30}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final controller = ConfettiController(duration: const Duration(milliseconds: 600));
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: controller,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: particles,
          gravity: 0.25,
          emissionFrequency: 0.08,
          colors: const [Color(0xFFFF8FB1), Color(0xFF6EC6FF), Color(0xFF7ED6A5), Color(0xFFFFD54F), Color(0xFFB39DFF)],
        ),
      ),
    ),
  );
  overlay.insert(entry);
  controller.play();
  Future.delayed(const Duration(seconds: 4), () {
    entry.remove();
    controller.dispose();
  });
}

Future<void> showCelebration(
  BuildContext context, {
  required String emoji,
  required String title,
  required String message,
  String button = '好耶！',
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) burstConfetti(context, particles: 50);
  });
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'celebration',
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, _) {
      final scale = CurvedAnimation(parent: anim, curve: Curves.elasticOut);
      return Opacity(
        opacity: anim.value.clamp(0, 1),
        child: Center(
          child: ScaleTransition(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark)),
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: textGrey, height: 1.5)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(button)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showAchievements(BuildContext context, List<Achievement> list) async {
  for (final a in list) {
    if (!context.mounted) return;
    await showCelebration(context, emoji: a.emoji, title: '获得新徽章：${a.title}', message: a.desc, button: '收下徽章');
  }
}

class StarChip extends StatelessWidget {
  const StarChip({super.key, required this.text, this.icon = '⭐', this.color = const Color(0xFFFFF3C4)});

  final String text;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
        ]),
      );
}

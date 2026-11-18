import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';

class ChildEditScreen extends StatefulWidget {
  const ChildEditScreen({super.key, this.child, this.firstTime = false});

  final Child? child;
  final bool firstTime;

  @override
  State<ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends State<ChildEditScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.child?.name ?? '');
  late String _avatar = widget.child?.avatar ?? childAvatars.first;
  late int _color = widget.child?.colorIndex ?? 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写小朋友的昵称')));
      return;
    }
    final store = context.read<AppStore>();
    if (widget.child == null) {
      store.addChild(name: name, avatar: _avatar, colorIndex: _color);
    } else {
      store.updateChild(widget.child!, name: name, avatar: _avatar, colorIndex: _color);
    }
    if (!widget.firstTime) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = childColors[_color];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firstTime ? '欢迎！' : (widget.child == null ? '添加小朋友' : '编辑小朋友')),
        automaticallyImplyLeading: !widget.firstTime,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.firstTime)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('先来创建第一位小朋友吧～',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textGrey)),
              ),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 110,
                height: 110,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.25), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_avatar, style: const TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 24),
            const _Label('昵称'),
            TextField(
              key: const Key('child_name'),
              controller: _name,
              maxLength: 10,
              decoration: const InputDecoration(hintText: '例如：小米、乐乐', counterText: ''),
            ),
            const SizedBox(height: 20),
            const _Label('选一个头像'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in childAvatars)
                  GestureDetector(
                    onTap: () => setState(() => _avatar = a),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: a == _avatar ? color.withValues(alpha: 0.3) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: a == _avatar ? color : const Color(0xFFEDE8EF), width: 2),
                      ),
                      child: Text(a, style: const TextStyle(fontSize: 30)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _Label('喜欢的颜色'),
            Wrap(
              spacing: 14,
              children: [
                for (var i = 0; i < childColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: childColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(color: i == _color ? textDark : Colors.transparent, width: 3),
                      ),
                      child: i == _color ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 36),
            FilledButton(
              key: const Key('child_save'),
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(widget.firstTime ? '开始打卡' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textDark)),
      );
}

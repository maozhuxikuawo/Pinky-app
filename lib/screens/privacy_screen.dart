import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../theme.dart';

const privacyPolicyText = '''欢迎使用「Pinky作业打卡」！我们非常重视您和孩子的个人信息与隐私保护。在使用前，请您（家长/监护人）仔细阅读以下内容：

1. 我们收集哪些信息
本应用仅保存您主动填写的内容：小朋友的昵称、头像图案、每日作业内容与完成情况、奖励设置及兑换记录。我们不会收集姓名、手机号、位置、通讯录、照片等任何其他个人信息。

2. 信息如何存储
以上数据仅保存在您手机本地，不会上传到任何服务器，也不会与任何第三方共享。本应用不包含广告和第三方统计 SDK，不需要联网权限。

3. 儿童个人信息保护
本应用面向家长和孩子共同使用。请由家长/监护人阅读并同意本声明后，再与孩子一起使用。建议昵称使用小名，无需填写真实姓名。

4. 您的权利
您可以随时在应用内修改或删除小朋友资料及作业记录；卸载应用后，所有本地数据将被一并清除。

5. 声明更新
如本声明内容发生变更，我们会在应用内重新提示您确认。

点击「同意并进入」即表示您已阅读并同意上述内容。''';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('🐰📚', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('Pinky作业打卡', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 4),
              const Text('每天进步一点点', style: TextStyle(fontSize: 15, color: textGrey)),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.shield_outlined, color: scheme.primary),
                          const SizedBox(width: 8),
                          const Text('隐私声明', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark)),
                        ]),
                        const SizedBox(height: 12),
                        const Expanded(
                          child: SingleChildScrollView(
                            child: Text(privacyPolicyText, style: TextStyle(fontSize: 14, height: 1.7, color: textDark)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('privacy_agree'),
                  onPressed: () => context.read<AppStore>().acceptPrivacy(),
                  child: const Text('同意并进入'),
                ),
              ),
              TextButton(
                onPressed: () => _confirmExit(context),
                child: const Text('不同意', style: TextStyle(color: textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('温馨提示'),
        content: const Text('需要同意隐私声明后才能使用本应用哦。确定要退出吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('退出应用')),
          FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('再看看')),
        ],
      ),
    );
    if (exit == true) SystemNavigator.pop();
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私声明')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(privacyPolicyText, style: TextStyle(fontSize: 15, height: 1.7, color: textDark)),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'screens/child_edit_screen.dart';
import 'screens/home_shell.dart';
import 'screens/privacy_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  final prefs = await SharedPreferences.getInstance();
  runApp(PinkyApp(store: AppStore(prefs)));
}

class PinkyApp extends StatelessWidget {
  const PinkyApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: Consumer<AppStore>(
        builder: (context, store, _) {
          final seed = store.currentChild?.color ?? childColors.first;
          return MaterialApp(
            title: 'Pinky作业打卡',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(seed),
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [Locale('zh', 'CN')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const RootGate(),
          );
        },
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    if (!store.privacyAccepted) return const PrivacyScreen();
    if (store.children.isEmpty) return const ChildEditScreen(firstTime: true);
    return const HomeShell();
  }
}

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notetaking_app/core/theme/app_theme.dart';
import 'package:notetaking_app/features/auth/presentation/login_screen.dart';
import 'package:notetaking_app/features/notes/presentation/notes_screen.dart';
import 'package:notetaking_app/features/offlinesupport/notes_db.dart';
import 'package:notetaking_app/features/offlinesupport/sync_service.dart';
import 'package:notetaking_app/features/setting/presentation/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotesDB.instance.database; // init SQLite

  // Check JWT in local storage
  final prefs = await SharedPreferences.getInstance();
  final jwt = prefs.getString('auth_token');
  final bool isLoggedIn = jwt != null && jwt.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> _connSub;

  @override
  void initState() {
    super.initState();

    _connSub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        SyncService.syncPendingNotes();
      }
    });

    // Sync once at app start
    SyncService.syncPendingNotes();
  }

  @override
  void dispose() {
    _connSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notes App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: widget.isLoggedIn ? const NotesScreen() : const LoginScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

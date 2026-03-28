import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'services/local_storage_service.dart';
import 'services/offline_sync_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/note_provider.dart';
import 'providers/analytics_provider.dart';
import 'services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🚀 Starting application...');

    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);
    debugPrint('✅ Firebase initialized');

    debugPrint('🔔 Initializing Notifications...');
    await NotificationService.instance.initialize();
    debugPrint('✅ Notifications initialized');

    debugPrint('⏰ Initializing Alarm Service...');
    await AlarmService.instance.initialize();
    debugPrint('✅ Alarm Service initialized');

    tz.initializeTimeZones();
    await AndroidAlarmManager.initialize();

    debugPrint('💾 Initializing SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences initialized');

    debugPrint('📦 Initializing Local Storage...');
    final localStorage = LocalStorageService();
    await localStorage.initialize();
    debugPrint('✅ Local Storage initialized');

    debugPrint('🔄 Initializing Offline Sync Service...');
    final offlineSync = OfflineSyncService();
    await offlineSync.initialize(
      onConnectivityChanged: (isOnline) {
        if (isOnline) {
          debugPrint('📡 Back online! Syncing pending changes...');
        } else {
          debugPrint('📵 Offline mode - changes will sync when online');
        }
      },
    );
    debugPrint('✅ Offline Sync Service initialized');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider(prefs)),
          ChangeNotifierProvider(create: (_) => NoteProvider()),
          ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
          ChangeNotifierProvider(create: (_) => SyncService()),
        ],
        child: const TaskApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ Initialization Error: $e');
    debugPrint(stackTrace.toString());
    // Run a basic error app if initialization fails
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'Task',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
    );
  }
}

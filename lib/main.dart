import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'firebase_options.dart';
import 'models.dart';
import 'child_lock.dart';
import 'register_screen.dart';

// Zmienna globalna przechowująca informację, czy jest nowa wersja
bool globalUpdateAvailable = false;
String globalLatestVersion = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Sprawdzamy aktualizację w tle podczas uruchamiania
  _checkForUpdatesSilently();

  runApp(const MyApp());
}

Future<void> _checkForUpdatesSilently() async {
  try {
    // Poprawny link do Twojego repozytorium GitHub
    final url = Uri.parse(
      'https://raw.githubusercontent.com/tomekpuchalskix-gif/edushield/main/version.json',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String latestVersion = data['version'];
      const String currentVersion = '1.0.0'; // Twoja obecna wersja

      if (latestVersion != currentVersion) {
        globalUpdateAvailable = true;
        globalLatestVersion = latestVersion;
      }
    }
  } catch (e) {
    debugPrint('Błąd sprawdzania aktualizacji: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Jeśli brak profili (pierwsze uruchomienie), pokaż rejestrację/logowanie rodzica.
    // W przeciwnym razie od razu uruchom Tryb Dziecka (blokadę z pytaniami).
    bool isFirstRun = globalProfiles.isEmpty;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduShield',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A6B52)),
        useMaterial3: true,
      ),
      home: isFirstRun
          ? const RegisterScreen()
          : LockScreenWidget(onUnlocked: () {}),
    );
  }
}

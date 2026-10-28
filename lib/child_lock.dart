import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'parent_auth.dart'; // <--- Import nowego ekranu autoryzacji

class LockScreenWidget extends StatefulWidget {
  final ChildProfileEntity profile;
  const LockScreenWidget({super.key, required this.profile});

  @override
  State<LockScreenWidget> createState() => _LockScreenWidgetState();
}

class _LockScreenWidgetState extends State<LockScreenWidget> {
  bool isUnlocked = false;

  void _openParentAuth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ParentAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) {
      return FreePlayScreen(profile: widget.profile);
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.alt, LogicalKeyboardKey.keyP): () {
          _openParentAuth(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Ekran blokady edukacyjnej dziecka...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isUnlocked = true;
                        });
                      },
                      child: const Text('Testowo odblokuj (Przejdź do czasu wolnego)'),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF2A6B52), size: 28),
                  tooltip: 'Panel Rodzica',
                  onPressed: () => _openParentAuth(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FreePlayScreen extends StatelessWidget {
  final ChildProfileEntity profile;
  const FreePlayScreen({super.key, required this.profile});

  void _openParentAuth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ParentAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_esports, size: 60, color: Color(0xFF2A6B52)),
                  const SizedBox(height: 12),
                  Text('Urządzenie odblokowane dla: ${profile.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF2A6B52), size: 28),
              tooltip: 'Panel Rodzica',
              onPressed: () => _openParentAuth(context),
            ),
          ),
        ],
      ),
    );
  }
}
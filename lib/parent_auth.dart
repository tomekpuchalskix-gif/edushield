import 'package:flutter/material.dart';

import 'models.dart';
import 'child_lock.dart';

class ParentAuthScreen extends StatefulWidget {
  const ParentAuthScreen({super.key});

  @override
  State<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends State<ParentAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showError = false;

  void _verifyPin() async {
    // Symulacja operacji asynchronicznej (np. odczyt bazy danych / zapisu)
    await Future.delayed(const Duration(milliseconds: 100));

    // Zabezpieczenie przed użyciem contextu po async gap
    if (!mounted) return;

    if (_pinController.text == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ParentDashboardWrapper()),
      );
    } else {
      setState(() {
        _showError = true;
      });
    }
  }

  void _goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LockScreenWidget(onUnlocked: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Color(0xFF2A6B52),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Panel Rodzica',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Wpisz 4-cyfrowy kod PIN, aby przejść do ustawień:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Kod PIN (np. 1234)',
                    errorText: _showError ? 'Niepoprawny kod PIN!' : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6B52),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: _verifyPin,
                  child: const Text('Wejdź', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _goBack,
                  child: const Text(
                    'Wróć do trybu dziecka',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Pomocniczy widok dla Panelu Rodzica po autoryzacji
class ParentDashboardWrapper extends StatelessWidget {
  const ParentDashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Zarządzania Rodzica'),
        backgroundColor: const Color(0xFF2A6B52),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LockScreenWidget(onUnlocked: () {}),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Text(
              'Zarządzanie profilem i czasem dziecka',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A6B52),
              ),
            ),
            const SizedBox(height: 16),
            ...globalProfiles.map(
              (profile) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF2A6B52)),
                  title: Text(profile.name),
                  subtitle: Text('Klasa: ${profile.statusClass}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

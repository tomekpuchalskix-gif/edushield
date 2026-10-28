import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'parent_panel.dart';

class ParentAuthScreen extends StatefulWidget {
  const ParentAuthScreen({super.key});

  @override
  State<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends State<ParentAuthScreen> {
  bool isLoginMode = true;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> _submitAuth() async {
    String email = _emailCtrl.text.trim();
    String pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Wypełnij wszystkie pola!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLoginMode) {
        // Logowanie przez Firebase Auth
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        if (pass != _confirmPassCtrl.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Hasła muszą być takie same!')),
          );
          setState(() => isLoading = false);
          return;
        }
        // Rejestracja nowego opiekuna w Firebase Auth
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rejestracja pomyślna! Zalogowano.')),
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Wystąpił błąd autoryzacji';
      if (e.code == 'user-not-found') {
        message = 'Nie znaleziono użytkownika o takim adresie e-mail.';
      } else if (e.code == 'wrong-password') {
        message = 'Błędne hasło.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ten e-mail jest już zarejestrowany.';
      } else if (e.code == 'weak-password') {
        message = 'Podane hasło jest zbyt słabe.';
      } else if (e.code == 'invalid-credential') {
        message = 'Nieprawidłowy e-mail lub hasło.';
      } else {
        message = e.message ?? message;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ $message')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    TextEditingController resetEmailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            '🔑 Resetowanie hasła',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Wpisz swój adres e-mail, aby otrzymać link do zresetowania hasła:',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resetEmailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adres e-mail',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6B52),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String email = resetEmailCtrl.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Wpisz adres e-mail!')),
                  );
                  return;
                }
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Wysłano link resetujący na e-mail!'),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Błąd: ${e.message}')),
                  );
                }
              },
              child: const Text('Wyślij link'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 25,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 60,
                  color: Color(0xFF2A6B52),
                ),
                const SizedBox(height: 16),
                Text(
                  isLoginMode
                      ? 'Panel Rodzica - Logowanie'
                      : 'Rejestracja Konta',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Adres e-mail',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Hasło',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (!isLoginMode) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Powtórz hasło',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF2A6B52))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A6B52),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _submitAuth,
                        child: Text(
                          isLoginMode ? 'Zaloguj się' : 'Zarejestruj się',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                const SizedBox(height: 10),
                if (isLoginMode)
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      'Nie pamiętam hasła?',
                      style: TextStyle(color: Color(0xFF2A6B52)),
                    ),
                  ),
                TextButton(
                  onPressed: () => setState(() => isLoginMode = !isLoginMode),
                  child: Text(
                    isLoginMode
                        ? 'Nie masz konta? Zarejestruj się'
                        : 'Masz konto? Zaloguj się',
                  ),
                ),
                const Divider(height: 20),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Powrót do trybu dziecka'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

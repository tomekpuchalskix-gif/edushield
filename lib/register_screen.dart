// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'parent_panel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Domyślnie uruchamiamy w trybie logowania (a nie rejestracji)
  bool _isLoginMode = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleSubmit() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@') || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wprowadź poprawny adres e-mail oraz hasło!'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        // --- LOGOWANIE PRZEZ FIREBASE ---
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          // Jeśli konto nie istnieje w bazie Firebase
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            setState(() {
              _isLoading = false;
            });
            _showAccountNotFoundDialog(email);
            return;
          } else {
            rethrow;
          }
        }
      } else {
        // --- REJESTRACJA PRZEZ FIREBASE ---
        if (password.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hasło musi mieć co najmniej 6 znaków!'),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // Po udanym zalogowaniu/rejestracji przechodzimy do Panelu Rodzica
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ParentDashboardScreen(initialAuthorized: true),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Wystąpił błąd autoryzacji.';
      if (e.code == 'wrong-password') {
        message = 'Niepoprawne hasło.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ten adres e-mail jest już zarejestrowany.';
      } else if (e.code == 'weak-password') {
        message = 'Podane hasło jest za słabe.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Okno informujące, że taki e-mail nie istnieje i proponujące rejestrację
  void _showAccountNotFoundDialog(String email) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konto nie istnieje'),
        content: Text(
          'Adres e-mail "$email" nie jest zarejestrowany w systemie EduShield. Czy chcesz utworzyć nowe konto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6B52),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _isLoginMode =
                    false; // Przełączamy automatycznie na tryb rejestracji
              });
            },
            child: const Text('Zarejestruj się'),
          ),
        ],
      ),
    );
  }

  // Funkcja wywoływana po kliknięciu "Zapomniałem hasła"
  void _handleForgotPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showForgotPasswordDialog();
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wysłano link resetujący hasło na adres: $email'),
            backgroundColor: const Color(0xFF2A6B52),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie udało się wysłać maila. Sprawdź poprawność adresu e-mail.',
            ),
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController recoveryEmailController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Odzyskiwanie hasła'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Wpisz swój adres e-mail powiązany z kontem w EduShield. Wyślemy Ci instrukcje resetowania hasła.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: recoveryEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adres e-mail',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6B52),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              String recoveryEmail = recoveryEmailController.text.trim();
              if (recoveryEmail.isNotEmpty && recoveryEmail.contains('@')) {
                Navigator.pop(dialogContext);
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: recoveryEmail,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Wysłano link resetujący na adres: $recoveryEmail',
                        ),
                        backgroundColor: const Color(0xFF2A6B52),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wystąpił błąd podczas wysyłania maila.'),
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wpisz poprawny adres e-mail!')),
                );
              }
            },
            child: const Text('Wyślij link'),
          ),
        ],
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
            width: 420,
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
                Text(
                  _isLoginMode ? "Witaj ponownie!" : "Witaj w EduShield!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A6B52),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode
                      ? "Zaloguj się na swoje konto rodzica."
                      : "Zarejestruj konto rodzica, aby zarządzać aplikacją.",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adres e-mail rodzica',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _handleSubmit(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Hasło',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _handleSubmit(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Zapomniałem hasła?',
                      style: TextStyle(fontSize: 13, color: Color(0xFF2A6B52)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2A6B52),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A6B52),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                        onPressed: _handleSubmit,
                        child: Text(
                          _isLoginMode ? 'Zaloguj się' : 'Zarejestruj się',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                    });
                  },
                  child: Text(
                    _isLoginMode
                        ? 'Nie masz konta? Zarejestruj się'
                        : 'Masz już konto? Zaloguj się',
                    style: const TextStyle(color: Color(0xFF2A6B52)),
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

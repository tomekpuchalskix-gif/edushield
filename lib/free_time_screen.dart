import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'parent_panel.dart';
import 'child_lock.dart';

class FreeTimeScreen extends StatefulWidget {
  final int breakDurationMinutes;

  const FreeTimeScreen({super.key, this.breakDurationMinutes = 15});

  @override
  State<FreeTimeScreen> createState() => _FreeTimeScreenState();
}

class _FreeTimeScreenState extends State<FreeTimeScreen> with WindowListener {
  late int _remainingSeconds;
  bool _isBreakTime = false;
  Timer? _timer;

  final int _totalFreeTimeSeconds = 2 * 60 * 60; // 2 godziny czasu wolnego

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _remainingSeconds = _totalFreeTimeSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          if (_remainingSeconds == _totalFreeTimeSeconds - 3600) {
            _isBreakTime = true;
          }
        } else {
          _timer?.cancel();
          _showTimeIsUpDialog();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _minimizeApp() async {
    await windowManager.minimize();
  }

  void _promptForParentPin() {
    TextEditingController pinController = TextEditingController();
    bool showError = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF2A6B52)),
                  SizedBox(width: 8),
                  Text(
                    'Ustawienia Rodzica',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Wpisz kod PIN, aby przejść do Panelu Rodzica:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Kod PIN (np. 1234)',
                      errorText: showError ? 'Niepoprawny kod PIN!' : null,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _verifyPin(
                      pinController.text,
                      dialogContext,
                      setModalState,
                      (val) => showError = val,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Anuluj',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6B52),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _verifyPin(
                    pinController.text,
                    dialogContext,
                    setModalState,
                    (val) => showError = val,
                  ),
                  child: const Text('Wejdź'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _verifyPin(
    String enteredPin,
    BuildContext dialogContext,
    StateSetter setModalState,
    Function(bool) setError,
  ) {
    if (enteredPin == '1234') {
      Navigator.pop(dialogContext);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
      );
    } else {
      setModalState(() {
        setError(true);
      });
    }
  }

  void _showTimeIsUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Koniec czasu wolnego!'),
        content: const Text('Wracamy do zadań edukacyjnych.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6B52),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LockScreenWidget(onUnlocked: () {}),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.sports_esports,
                        color: Color(0xFF2A6B52),
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Czas Wolny / Odpoczynek",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A6B52),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _minimizeApp,
                        icon: const Icon(Icons.remove, color: Colors.grey),
                        tooltip: "Minimalizuj do paska",
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _promptForParentPin,
                        icon: const Icon(
                          Icons.settings,
                          color: Color(0xFF2A6B52),
                        ),
                        tooltip: "Ustawienia / Panel Rodzica",
                      ),
                    ],
                  ),
                ],
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sentiment_very_satisfied,
                        size: 80,
                        color: Color(0xFF2A6B52),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Świetna robota! Zadania na dziś zostały ukończone.",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Korzystaj z czasu wolnego. Pamiętaj o przerwie na świeże powietrze!",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _isBreakTime
                          ? "🕒 CZAS NA PRZERWĘ (Siku / Dwór / Posiłek)"
                          : "⏳ Pozostały czas wolny:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isBreakTime
                            ? Colors.orange[800]
                            : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A6B52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Ustawiona przerwa: ${widget.breakDurationMinutes} minut",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

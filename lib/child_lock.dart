import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'parent_panel.dart';
import 'free_time_screen.dart';
import 'daily_quiz_manager.dart';

class LockScreenWidget extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreenWidget({super.key, required this.onUnlocked});

  @override
  State<LockScreenWidget> createState() => _LockScreenWidgetState();
}

class _LockScreenWidgetState extends State<LockScreenWidget>
    with WindowListener {
  List<dynamic> rawTasks = [];
  List<TaskEntity> tasks = [];

  int currentIndex = 0;

  final TextEditingController _answerController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();

  String? _selectedDropdownAnswer;
  String feedbackMessage = '';

  bool isCorrectState = false;
  bool isLoading = true;
  bool isChecking = false;

  static const Color primaryColor = Color(0xFF24C58A);
  static const Color darkColor = Color(0xFF101B2D);
  static const Color backgroundColor = Color(0xFF0B1423);

  @override
  void initState() {
    super.initState();

    windowManager.addListener(this);

    _initWindowLock();
    _checkDailyUnlockStatus();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _answerController.dispose();
    _keyboardFocusNode.dispose();

    super.dispose();
  }

  // Uruchomienie blokady trybu dziecka.
  Future<void> _initWindowLock() async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setPreventClose(true);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onWindowMinimize() async {
    super.onWindowMinimize();

    await windowManager.restore();
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onWindowBlur() async {
    super.onWindowBlur();

    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _checkDailyUnlockStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final String? lastUnlockedDate = prefs.getString('last_unlocked_date');

    final String todayDate = DateTime.now().toIso8601String().substring(0, 10);

    if (lastUnlockedDate == todayDate) {
      _goToFreeTime();
    } else {
      _loadDailyTasks();
    }
  }

  Future<void> _saveUnlockForToday() async {
    final prefs = await SharedPreferences.getInstance();

    final String todayDate = DateTime.now().toIso8601String().substring(0, 10);

    await prefs.setString('last_unlocked_date', todayDate);
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();

    if (isPreventClose) {
      _showBlockedMessage();
    }
  }

  void _showBlockedMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Komputer jest zablokowany! Rozwiąż zadania lub poproś rodzica o PIN.',
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Pobieranie zadań z bazy.
  Future<void> _loadDailyTasks() async {
    try {
      final dailyMap = await DailyQuizManager.getDailyQuestionsPerSubject();

      List<TaskEntity> loadedTasks = [];
      List<dynamic> rawList = [];

      dailyMap.forEach((subjectName, questionList) {
        for (var q in questionList) {
          rawList.add(q);

          loadedTasks.add(
            TaskEntity(
              id: q['id'].toString(),
              childId: 'mieszko',
              subject: subjectName,
              taskText: q['taskText'],
              correctAnswer: q['correctAnswer'],
              hint: q['hint'] ?? '',
              explanation: q['explanation'] ?? '',
            ),
          );
        }
      });

      if (!mounted) return;

      setState(() {
        tasks = loadedTasks;
        rawTasks = rawList;
        isLoading = false;

        if (loadedTasks.isEmpty) {
          feedbackMessage =
              'Nie znaleziono aktywnych zadań. '
              'Komputer pozostaje zablokowany. '
              'Poproś rodzica o sprawdzenie aplikacji.';
        } else {
          feedbackMessage = '';
        }
      });

      requestFocus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        feedbackMessage =
            'Błąd ładowania zadań. Komputer pozostaje zablokowany. '
            'Poproś rodzica o sprawdzenie aplikacji.';
      });
    }
  }

  // Ponowne pobranie zadań.
  Future<void> _retryLoadDailyTasks() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      feedbackMessage = '';
      tasks = [];
      rawTasks = [];
      currentIndex = 0;
      _answerController.clear();
      _selectedDropdownAnswer = null;
    });

    await _loadDailyTasks();
  }

  void requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_keyboardFocusNode);
      }
    });
  }

  Future<void> checkAnswer() async {
    if (isChecking) return;

    // Brak zadań nigdy nie może odblokować komputera.
    if (tasks.isEmpty) {
      setState(() {
        feedbackMessage =
            'Brak zadań. Komputer pozostaje zablokowany. '
            'Poproś rodzica o sprawdzenie aplikacji.';
        isCorrectState = false;
      });
      return;
    }

    final currentTask = tasks[currentIndex];

    List<dynamic>? options =
        (rawTasks.isNotEmpty && currentIndex < rawTasks.length)
        ? rawTasks[currentIndex]['options'] as List<dynamic>?
        : null;

    String userAnswer = '';

    if (options != null && options.isNotEmpty) {
      userAnswer = (_selectedDropdownAnswer ?? '').trim().toLowerCase();
    } else {
      userAnswer = _answerController.text.trim().toLowerCase();
    }

    String correctAnswer = currentTask.correctAnswer.trim().toLowerCase();

    if (userAnswer.isEmpty) {
      setState(() {
        feedbackMessage = 'Najpierw wpisz lub wybierz odpowiedź.';
        isCorrectState = false;
      });
      return;
    }

    if (userAnswer == correctAnswer) {
      setState(() {
        feedbackMessage = 'Brawo! Poprawna odpowiedź. 🎉';
        isCorrectState = true;
        isChecking = true;
      });

      final bool wasLastTask = currentIndex == tasks.length - 1;

      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      if (wasLastTask) {
        await _saveUnlockForToday();

        if (!mounted) return;

        _goToFreeTime();
      } else {
        setState(() {
          currentIndex++;
          _answerController.clear();
          _selectedDropdownAnswer = null;
          feedbackMessage = '';
          isCorrectState = false;
          isChecking = false;
        });

        requestFocus();
      }
    } else {
      setState(() {
        feedbackMessage =
            'Spróbuj jeszcze raz. Podpowiedź: ${currentTask.hint}';

        isCorrectState = false;
      });

      requestFocus();
    }
  }

  Future<void> _goToFreeTime() async {
    await windowManager.setPreventClose(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setFullScreen(false);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FreeTimeScreen()),
    );
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
                    'Panel Rodzica',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Wpisz 4-cyfrowy kod PIN, aby wyjść z trybu dziecka:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Kod PIN',
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
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    pinController.dispose();
                  },
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

  // Przejście z trybu dziecka do panelu rodzica.
  Future<void> _verifyPin(
    String enteredPin,
    BuildContext dialogContext,
    StateSetter setModalState,
    Function(bool) setError,
  ) async {
    if (enteredPin == ParentAccount.pin) {
      // Przywrócenie standardowego okna Windows.
      await windowManager.setPreventClose(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      await windowManager.setFullScreen(false);
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();

      if (!dialogContext.mounted) return;

      Navigator.pop(dialogContext);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ParentDashboardScreen(initialAuthorized: true),
        ),
      );
    } else {
      setModalState(() {
        setError(true);
      });
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: primaryColor,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EDU SHIELD UP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Twoja przepustka do czasu wolnego',
                style: TextStyle(color: Color(0xFF9BAAC0), fontSize: 14),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _promptForParentPin,
          icon: const Icon(Icons.admin_panel_settings, size: 19),
          label: const Text(
            'PANEL RODZICA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF26364C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: primaryColor, width: 1),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProgress() {
    final double progress = tasks.isEmpty
        ? 0
        : (currentIndex + 1) / tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TWÓJ POSTĘP',
              style: TextStyle(
                color: Color(0xFF9BAAC0),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '${tasks.isEmpty ? 0 : currentIndex + 1} / ${tasks.length}',
              style: const TextStyle(
                color: primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            backgroundColor: const Color(0xFF26364C),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionContent(List<dynamic>? currentOptions) {
    if (tasks.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 64,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 20),
          Text(
            feedbackMessage.isNotEmpty
                ? feedbackMessage
                : 'Brak dostępnych zadań. Komputer pozostaje zablokowany.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _retryLoadDailyTasks,
            icon: const Icon(Icons.refresh),
            label: const Text('SPRÓBUJ PONOWNIE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: darkColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tasks[currentIndex].subject.toUpperCase(),
          style: const TextStyle(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          tasks[currentIndex].taskText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 32),

        if (currentOptions != null && currentOptions.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedDropdownAnswer,
            isExpanded: true,
            dropdownColor: const Color(0xFF26364C),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Wybierz odpowiedź',
              labelStyle: const TextStyle(color: Color(0xFF9BAAC0)),
              filled: true,
              fillColor: const Color(0xFF18263A),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF34465F)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
            items: currentOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt.toString(),
                child: Text(
                  opt.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: isChecking
                ? null
                : (val) {
                    setState(() {
                      _selectedDropdownAnswer = val;
                    });
                  },
          ),
        ] else ...[
          TextField(
            controller: _answerController,
            style: const TextStyle(color: Colors.white, fontSize: 19),
            decoration: InputDecoration(
              labelText: 'Wpisz swoją odpowiedź',
              labelStyle: const TextStyle(color: Color(0xFF9BAAC0)),
              filled: true,
              fillColor: const Color(0xFF18263A),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF34465F)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
            onSubmitted: (_) => checkAnswer(),
          ),
        ],

        const SizedBox(height: 24),

        SizedBox(
          height: 62,
          child: ElevatedButton(
            onPressed: isChecking ? null : checkAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: darkColor,
              disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'SPRAWDŹ ODPOWIEDŹ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),

        if (feedbackMessage.isNotEmpty) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isCorrectState
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrectState
                    ? primaryColor.withValues(alpha: 0.5)
                    : Colors.red.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              feedbackMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCorrectState ? primaryColor : const Color(0xFFFF8585),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? currentOptions =
        (rawTasks.isNotEmpty && currentIndex < rawTasks.length)
        ? rawTasks[currentIndex]['options'] as List<dynamic>?
        : null;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF14243A), backgroundColor, Color(0xFF101D30)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool compact = constraints.maxHeight < 700;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 700 ? 18 : 50,
                      vertical: compact ? 16 : 30,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          SizedBox(height: compact ? 25 : 45),

                          if (isLoading)
                            const SizedBox(
                              height: 350,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                    SizedBox(height: 22),
                                    Text(
                                      'Przygotowujemy Twoje zadania...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.all(
                                constraints.maxWidth < 700 ? 22 : 45,
                              ),
                              decoration: BoxDecoration(
                                color: darkColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF293B52),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 35,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildProgress(),
                                  SizedBox(height: compact ? 25 : 40),
                                  const Divider(color: Color(0xFF293B52)),
                                  SizedBox(height: compact ? 20 : 35),
                                  _buildQuestionContent(currentOptions),
                                ],
                              ),
                            ),

                          SizedBox(height: compact ? 20 : 35),

                          const Center(
                            child: Text(
                              'NAUKA TERAZ. WIĘCEJ MOŻLIWOŚCI PÓŹNIEJ.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF71839C),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

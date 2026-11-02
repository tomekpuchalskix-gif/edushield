import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:window_manager/window_manager.dart';

import 'dart:convert';

import 'models.dart';
import 'child_lock.dart';
import 'register_screen.dart';
import 'interests_data.dart';

// Zmienne globalne do obsługi powiadomienia o aktualizacji z GitHuba
bool globalUpdateAvailable = false;
String globalLatestVersion = '';

class ParentDashboardScreen extends StatefulWidget {
  final bool initialAuthorized;

  const ParentDashboardScreen({super.key, this.initialAuthorized = false});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final TextEditingController _pinController = TextEditingController();
  late bool _isAuthorized;
  int _selectedNavIndex = 0;
  int _activeChildIndex = 0;

  String _selectedDay = 'Poniedziałek';

  final List<String> _daysOfWeek = [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
  ];

  // Konfiguracja okna Windows dla Panelu Rodzica.
  // Nie zmienia rozmiaru ekranu logowania.
  Future<void> _configureParentWindow() async {
    await windowManager.setPreventClose(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setFullScreen(false);
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void initState() {
    super.initState();

    _isAuthorized = widget.initialAuthorized;

    _checkForUpdatesSilently();

    // Maksymalizujemy okno dopiero po wejściu do autoryzowanego
    // Panelu Rodzica. Ekran logowania pozostaje bez zmian.
    if (widget.initialAuthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _configureParentWindow();
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // Sprawdzanie aktualizacji z GitHuba w tle
  Future<void> _checkForUpdatesSilently() async {
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/tomekpuchalskix-gif/edushield/main/version.json',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String latestVersion = data['version'];
        const String currentVersion = '1.0.0';

        if (latestVersion != currentVersion) {
          if (!mounted) return;

          setState(() {
            globalUpdateAvailable = true;
            globalLatestVersion = latestVersion;
          });
        }
      }
    } catch (e) {
      debugPrint('Błąd sprawdzania aktualizacji: $e');
    }
  }

  String get _currentParentUid {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? user.uid : 'guest_parent';
  }

  Future<void> _saveChildToFirestore(ChildProfileEntity child) async {
    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(child.id)
          .set(child.toMap());
    } catch (e) {
      debugPrint('Błąd zapisu dziecka do Firestore: $e');
    }
  }

  Future<void> _saveExamToFirestore(ExamEntity exam) async {
    try {
      await FirebaseFirestore.instance
          .collection('exams')
          .doc(exam.id)
          .set(exam.toMap());
    } catch (e) {
      debugPrint('Błąd zapisu sprawdzianu do Firestore: $e');
    }
  }

  // Weryfikacja PIN-u i otwarcie zmaksymalizowanego Panelu Rodzica.
  Future<void> _verifyMasterPin() async {
    if (_pinController.text == ParentAccount.pin) {
      await _configureParentWindow();

      if (!mounted) return;

      setState(() {
        _isAuthorized = true;
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Niepoprawny kod PIN!')));
    }
  }

  void _returnToChildLock(List<ChildProfileEntity> myChildren) {
    if (myChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Najpierw dodaj swoje dziecko, aby przejść do trybu nauki!',
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LockScreenWidget(onUnlocked: () {}),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  /// Okno dodawania dziecka
  void _showAddChildDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController customInterestController = TextEditingController();

    String selectedSchoolType = 'Szkoła podstawowa';

    List<String> primaryClasses = [
      'Klasa 1',
      'Klasa 2',
      'Klasa 3',
      'Klasa 4',
      'Klasa 5',
      'Klasa 6',
      'Klasa 7',
      'Klasa 8',
    ];

    List<String> highClasses = [
      'Klasa 1',
      'Klasa 2',
      'Klasa 3',
      'Klasa 4',
      'Klasa 5',
    ];

    String selectedClass = primaryClasses.first;

    List<String> availableInterests = List.from(InterestsData.defaultInterests);

    List<String> selectedInterests = ['Gry wideo', 'LEGO'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentClassesList = selectedSchoolType == 'Szkoła podstawowa'
              ? primaryClasses
              : highClasses;

          if (!currentClassesList.contains(selectedClass)) {
            selectedClass = currentClassesList.first;
          }

          return AlertDialog(
            title: const Text('Dodaj swoje dziecko'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Imię dziecka',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Typ szkoły:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSchoolType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Szkoła podstawowa',
                        child: Text('Szkoła podstawowa'),
                      ),
                      DropdownMenuItem(
                        value: 'Szkoła średnia / Technikum',
                        child: Text('Szkoła średnia / Technikum'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedSchoolType = val;
                          selectedClass =
                              selectedSchoolType == 'Szkoła podstawowa'
                              ? primaryClasses.first
                              : highClasses.first;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Klasa:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedClass,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: currentClassesList
                        .map(
                          (cls) =>
                              DropdownMenuItem(value: cls, child: Text(cls)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedClass = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Zainteresowania (wybierz lub dopisz własne):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: availableInterests.map((interest) {
                      final isSelected = selectedInterests.contains(interest);

                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE2F0EC),
                        checkmarkColor: const Color(0xFF2A6B52),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2A6B52)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedInterests.add(interest);
                            } else {
                              selectedInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customInterestController,
                          decoration: const InputDecoration(
                            labelText: 'Wpisz inne zainteresowanie...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A6B52),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final customVal = customInterestController.text
                              .trim();

                          if (customVal.isEmpty) return;

                          if (!ContentFilter.isSafe(customVal)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'To słowo zawiera niedozwolone treści!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (!availableInterests.contains(customVal)) {
                            setDialogState(() {
                              availableInterests.add(customVal);
                              selectedInterests.add(customVal);
                              customInterestController.clear();
                            });
                          }
                        },
                        child: const Text('Dodaj'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    final finalInterests = selectedInterests.isNotEmpty
                        ? selectedInterests
                        : ['Ogólne'];

                    final newChild = ChildProfileEntity(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      parentId: _currentParentUid,
                      name: nameController.text.trim(),
                      schoolType: selectedSchoolType,
                      statusClass: selectedClass,
                      motivationType: MotivationType.explorer,
                      interests: finalInterests,
                      weeklySchedule: {},
                      subjectsConfig: {},
                    );

                    await _saveChildToFirestore(newChild);

                    // Poprawka: sprawdzamy oba konteksty po await.
                    if (!mounted || !context.mounted) return;

                    setState(() {
                      _activeChildIndex = 0;
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Dodano profil: ${newChild.name} '
                          '($selectedSchoolType, $selectedClass)',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Zapisz'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Okno edycji istniejącego profilu dziecka
  void _showEditChildDialog(ChildProfileEntity child) {
    TextEditingController nameController = TextEditingController(
      text: child.name,
    );

    TextEditingController customInterestController = TextEditingController();

    String selectedSchoolType = child.schoolType;

    List<String> primaryClasses = [
      'Klasa 1',
      'Klasa 2',
      'Klasa 3',
      'Klasa 4',
      'Klasa 5',
      'Klasa 6',
      'Klasa 7',
      'Klasa 8',
    ];

    List<String> highClasses = [
      'Klasa 1',
      'Klasa 2',
      'Klasa 3',
      'Klasa 4',
      'Klasa 5',
    ];

    String selectedClass =
        primaryClasses.contains(child.statusClass) ||
            highClasses.contains(child.statusClass)
        ? child.statusClass
        : 'Klasa 1';

    List<String> availableInterests = List.from(InterestsData.defaultInterests);

    for (var interest in child.interests) {
      if (!availableInterests.contains(interest)) {
        availableInterests.add(interest);
      }
    }

    List<String> selectedInterests = List.from(child.interests);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentClassesList = selectedSchoolType == 'Szkoła podstawowa'
              ? primaryClasses
              : highClasses;

          if (!currentClassesList.contains(selectedClass)) {
            selectedClass = currentClassesList.first;
          }

          return AlertDialog(
            title: Text('Edytuj profil: ${child.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Imię dziecka',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Typ szkoły:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSchoolType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Szkoła podstawowa',
                        child: Text('Szkoła podstawowa'),
                      ),
                      DropdownMenuItem(
                        value: 'Szkoła średnia / Technikum',
                        child: Text('Szkoła średnia / Technikum'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedSchoolType = val;
                          selectedClass =
                              selectedSchoolType == 'Szkoła podstawowa'
                              ? primaryClasses.first
                              : highClasses.first;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Klasa:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedClass,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: currentClassesList
                        .map(
                          (cls) =>
                              DropdownMenuItem(value: cls, child: Text(cls)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedClass = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Zainteresowania (wybierz lub dopisz własne):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: availableInterests.map((interest) {
                      final isSelected = selectedInterests.contains(interest);

                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE2F0EC),
                        checkmarkColor: const Color(0xFF2A6B52),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2A6B52)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedInterests.add(interest);
                            } else {
                              selectedInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customInterestController,
                          decoration: const InputDecoration(
                            labelText: 'Wpisz inne zainteresowanie...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A6B52),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final customVal = customInterestController.text
                              .trim();

                          if (customVal.isEmpty) return;

                          if (!ContentFilter.isSafe(customVal)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'To słowo zawiera niedozwolone treści!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (!availableInterests.contains(customVal)) {
                            setDialogState(() {
                              availableInterests.add(customVal);
                              selectedInterests.add(customVal);
                              customInterestController.clear();
                            });
                          }
                        },
                        child: const Text('Dodaj'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    final updatedChild = ChildProfileEntity(
                      id: child.id,
                      parentId: child.parentId,
                      name: nameController.text.trim(),
                      schoolType: selectedSchoolType,
                      statusClass: selectedClass,
                      motivationType: child.motivationType,
                      interests: selectedInterests.isNotEmpty
                          ? selectedInterests
                          : ['Ogólne'],
                      weeklySchedule: child.weeklySchedule,
                      subjectsConfig: child.subjectsConfig,
                    );

                    await _saveChildToFirestore(updatedChild);

                    // Poprawka: sprawdzamy oba konteksty po await.
                    if (!mounted || !context.mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Zaktualizowano profil dziecka!'),
                      ),
                    );

                    setState(() {});
                  }
                },
                child: const Text('Zapisz zmiany'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Okno dodawania sprawdzianu
  void _showAddExamDialog(ChildProfileEntity activeChild) {
    TextEditingController titleController = TextEditingController();
    TextEditingController dateController = TextEditingController();
    TextEditingController scopeController = TextEditingController();

    String selectedSubject = SchoolSubjects.getForSchoolType(
      activeChild.schoolType,
    ).first;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final subjectsList = SchoolSubjects.getForSchoolType(
            activeChild.schoolType,
          );

          if (!subjectsList.contains(selectedSubject)) {
            selectedSubject = subjectsList.first;
          }

          return AlertDialog(
            title: Text('Zaplanuj sprawdzian dla: ${activeChild.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Przedmiot:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubject,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: subjectsList
                        .map(
                          (sub) =>
                              DropdownMenuItem(value: sub, child: Text(sub)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedSubject = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tytuł / Temat (np. Kartkówka z ułamków)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Data (np. 15.06.2026)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: scopeController,
                    decoration: const InputDecoration(
                      labelText: 'Zakres materiału',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                onPressed: () async {
                  if (titleController.text.trim().isNotEmpty) {
                    final newExam = ExamEntity(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      childId: activeChild.id,
                      subject: selectedSubject,
                      title: titleController.text.trim(),
                      date: dateController.text.trim().isNotEmpty
                          ? dateController.text.trim()
                          : 'Najbliższy termin',
                      scope: scopeController.text.trim(),
                    );

                    await _saveExamToFirestore(newExam);

                    // Poprawka: sprawdzamy oba konteksty po await.
                    if (!mounted || !context.mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dodano sprawdzian do bazy danych!'),
                      ),
                    );

                    setState(() {});
                  }
                },
                child: const Text('Zapisz sprawdzian'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePinDialog() {
    TextEditingController oldPinController = TextEditingController();
    TextEditingController newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmień kod PIN Panelu Rodzica'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stary PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPinController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nowy 4-cyfrowy PIN',
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
            onPressed: () {
              if (oldPinController.text == ParentAccount.pin &&
                  newPinController.text.length == 4) {
                ParentAccount.pin = newPinController.text;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kod PIN został pomyślnie zmieniony!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Błąd! Sprawdź stary PIN lub upewnij się, że nowy ma 4 cyfry.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  // Baner powiadamiający o nowej wersji aplikacji z GitHuba
  Widget _buildUpdateBannerIfAvailable() {
    if (!globalUpdateAvailable) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F0EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A6B52), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update, color: Color(0xFF2A6B52), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dostępna nowa wersja: $globalLatestVersion!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A6B52),
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'Pobierz najnowszą wersję z zakładki Releases na GitHubie.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6B52),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Aktualizuj EduShield'),
                  content: Text(
                    'Przejdź do swojego konta GitHub w zakładce Releases, '
                    'aby pobrać nowy plik instalacyjny dla wersji '
                    '($globalLatestVersion).',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Sprawdź'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
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
                      Icon(Icons.lock, color: Color(0xFF2A6B52), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Panel Rodzica - Autoryzacja',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Wpisz 4-cyfrowy kod PIN, aby uzyskać dostęp:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Kod PIN',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _verifyMasterPin(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A6B52),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                    onPressed: _verifyMasterPin,
                    child: const Text(
                      'Potwierdź PIN',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .where('parentId', isEqualTo: _currentParentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF3F6F8),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2A6B52)),
            ),
          );
        }

        final myChildrenList = snapshot.hasData
            ? snapshot.data!.docs
                  .map(
                    (doc) => ChildProfileEntity.fromMap(
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList()
            : <ChildProfileEntity>[];

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6F8),
          body: Row(
            children: [
              Container(
                width: 220,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(Icons.shield, color: Color(0xFF2A6B52)),
                          SizedBox(width: 8),
                          Text(
                            'EduShield',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A6B52),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A6B52),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: _showAddChildDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Dodaj dziecko'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard_outlined),
                      title: const Text('Pulpit'),
                      selected: _selectedNavIndex == 0,
                      selectedColor: const Color(0xFF2A6B52),
                      onTap: () => setState(() => _selectedNavIndex = 0),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Plan lekcji'),
                      selected: _selectedNavIndex == 1,
                      selectedColor: const Color(0xFF2A6B52),
                      onTap: () => setState(() => _selectedNavIndex = 1),
                    ),
                    ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: const Text('Sprawdziany'),
                      selected: _selectedNavIndex == 2,
                      selectedColor: const Color(0xFF2A6B52),
                      onTap: () => setState(() => _selectedNavIndex = 2),
                    ),
                    ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: const Text('Kontrola aplikacji'),
                      selected: _selectedNavIndex == 3,
                      selectedColor: const Color(0xFF2A6B52),
                      onTap: () => setState(() => _selectedNavIndex = 3),
                    ),
                    const Spacer(),
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Wersja: 1.0.0',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.vpn_key, color: Colors.grey),
                      title: const Text(
                        'Zmień PIN',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: _showChangePinDialog,
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.orange),
                      title: const Text(
                        'Wyloguj',
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                      onTap: _logout,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.exit_to_app,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Tryb dziecka',
                        style: TextStyle(fontSize: 14, color: Colors.redAccent),
                      ),
                      onTap: () => _returnToChildLock(myChildrenList),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedNavIndex == 0
                                ? 'Pulpit Rodzica'
                                : _selectedNavIndex == 1
                                ? 'Zarządzanie Planem Lekcji'
                                : _selectedNavIndex == 2
                                ? 'Zarządzanie Sprawdzianami'
                                : 'Kontrola Aplikacji',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.account_circle,
                                color: Color(0xFF2A6B52),
                              ),
                              const SizedBox(width: 8),
                              myChildrenList.isNotEmpty
                                  ? DropdownButton<int>(
                                      value:
                                          _activeChildIndex <
                                              myChildrenList.length
                                          ? _activeChildIndex
                                          : 0,
                                      underline: const SizedBox(),
                                      items: List.generate(
                                        myChildrenList.length,
                                        (index) => DropdownMenuItem(
                                          value: index,
                                          child: Text(
                                            myChildrenList[index].name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onChanged: (newIndex) {
                                        if (newIndex != null) {
                                          setState(() {
                                            _activeChildIndex = newIndex;
                                          });
                                        }
                                      },
                                    )
                                  : const Text(
                                      'Brak dzieci',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildUpdateBannerIfAvailable(),
                            Expanded(
                              child: _selectedNavIndex == 0
                                  ? _buildPulpitContent(myChildrenList)
                                  : _selectedNavIndex == 1
                                  ? _buildScheduleContent(myChildrenList)
                                  : _selectedNavIndex == 2
                                  ? _buildExamsContent(myChildrenList)
                                  : const Center(
                                      child: Text(
                                        'Ustawienia kontroli aplikacji '
                                        'i limitów czasowych',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPulpitContent(List<ChildProfileEntity> myChildrenList) {
    if (myChildrenList.isEmpty) {
      return Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.child_care, size: 64, color: Color(0xFF2A6B52)),
              const SizedBox(height: 16),
              const Text(
                'Brak przypisanych dzieci',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Twoje konto nie ma jeszcze przypisanych dzieci. '
                'Dodaj swoje pierwsze dziecko.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6B52),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _showAddChildDialog,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Dodaj dziecko',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeChildIndex >= myChildrenList.length) {
      _activeChildIndex = 0;
    }

    final activeChild = myChildrenList[_activeChildIndex];

    return ListView(
      children: [
        Center(
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF2A6B52)),
                      tooltip: 'Edytuj profil dziecka',
                      onPressed: () => _showEditChildDialog(activeChild),
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFE2F0EC),
                  child: Icon(Icons.person, size: 40, color: Color(0xFF2A6B52)),
                ),
                const SizedBox(height: 12),
                Text(
                  activeChild.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F0EC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${activeChild.schoolType} • ${activeChild.statusClass}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A6B52),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Zainteresowania (Personalizacja zadań):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: activeChild.interests
                      .map(
                        (interest) => Chip(
                          backgroundColor: const Color(0xFFF3F6F8),
                          label: Text(
                            interest,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2A6B52),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: 0.0,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF2A6B52),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ogólny postęp zadań: 0%',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6B52),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => _returnToChildLock(myChildrenList),
                  child: Text(
                    'Przejdź do trybu dziecka dla: ${activeChild.name}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- ZAKŁADKA PLANU LEKCJI ---
  Widget _buildScheduleContent(List<ChildProfileEntity> myChildrenList) {
    if (myChildrenList.isEmpty) {
      return const Center(
        child: Text('Najpierw dodaj dziecko, aby zarządzać planem lekcji.'),
      );
    }

    if (_activeChildIndex >= myChildrenList.length) {
      _activeChildIndex = 0;
    }

    final activeChild = myChildrenList[_activeChildIndex];

    final availableSubjects = SchoolSubjects.getForSchoolType(
      activeChild.schoolType,
    );

    final dayScheduleMap = Map<String, dynamic>.from(
      activeChild.weeklySchedule[_selectedDay] ?? {'subjects': <String>[]},
    );

    final List<String> currentDaySubjects = List<String>.from(
      dayScheduleMap['subjects'] ?? [],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _daysOfWeek.map((day) {
              bool isSelected = day == _selectedDay;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2A6B52),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDay = day;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan na: $_selectedDay (${activeChild.name})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: currentDaySubjects.isEmpty
                            ? const Center(
                                child: Text(
                                  'Brak przedmiotów w planie.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: currentDaySubjects.length,
                                itemBuilder: (context, index) {
                                  final subject = currentDaySubjects[index];

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFE2F0EC),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF2A6B52),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(subject),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        currentDaySubjects.removeAt(index);

                                        Map<String, dynamic> updatedSchedule =
                                            Map.from(
                                              activeChild.weeklySchedule,
                                            );

                                        updatedSchedule[_selectedDay] = {
                                          'subjects': currentDaySubjects,
                                        };

                                        final updatedChild = ChildProfileEntity(
                                          id: activeChild.id,
                                          parentId: activeChild.parentId,
                                          name: activeChild.name,
                                          schoolType: activeChild.schoolType,
                                          statusClass: activeChild.statusClass,
                                          motivationType:
                                              activeChild.motivationType,
                                          interests: activeChild.interests,
                                          weeklySchedule: updatedSchedule,
                                          subjectsConfig:
                                              activeChild.subjectsConfig,
                                        );

                                        await _saveChildToFirestore(
                                          updatedChild,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dostępne (${activeChild.schoolType})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: availableSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = availableSubjects[index];

                            return Card(
                              elevation: 0,
                              color: const Color(0xFFF3F6F8),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  subject,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: const Icon(
                                  Icons.add_circle,
                                  color: Color(0xFF2A6B52),
                                  size: 20,
                                ),
                                onTap: () async {
                                  currentDaySubjects.add(subject);

                                  Map<String, dynamic> updatedSchedule =
                                      Map.from(activeChild.weeklySchedule);

                                  updatedSchedule[_selectedDay] = {
                                    'subjects': currentDaySubjects,
                                  };

                                  final updatedChild = ChildProfileEntity(
                                    id: activeChild.id,
                                    parentId: activeChild.parentId,
                                    name: activeChild.name,
                                    schoolType: activeChild.schoolType,
                                    statusClass: activeChild.statusClass,
                                    motivationType: activeChild.motivationType,
                                    interests: activeChild.interests,
                                    weeklySchedule: updatedSchedule,
                                    subjectsConfig: activeChild.subjectsConfig,
                                  );

                                  await _saveChildToFirestore(updatedChild);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ZAKŁADKA SPRAWDZIANÓW Z SYNCHRONIZACJĄ Z FIRESTORE ---
  Widget _buildExamsContent(List<ChildProfileEntity> myChildrenList) {
    if (myChildrenList.isEmpty) {
      return const Center(
        child: Text('Najpierw dodaj dziecko, aby zarządzać sprawdzianami.'),
      );
    }

    if (_activeChildIndex >= myChildrenList.length) {
      _activeChildIndex = 0;
    }

    final activeChild = myChildrenList[_activeChildIndex];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exams')
          .where('childId', isEqualTo: activeChild.id)
          .snapshots(),
      builder: (context, snapshot) {
        final examsList = snapshot.hasData
            ? snapshot.data!.docs
                  .map(
                    (doc) =>
                        ExamEntity.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList()
            : <ExamEntity>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zaplanowane sprawdziany dla: ${activeChild.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6B52),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showAddExamDialog(activeChild),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Dodaj sprawdzian'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: examsList.isEmpty
                  ? Center(
                      child: Text(
                        'Brak zaplanowanych sprawdzianów dla '
                        '${activeChild.name}.\n'
                        'Kliknij przycisk powyżej, aby dodać nowy.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: examsList.length,
                      itemBuilder: (context, index) {
                        final exam = examsList[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE2F0EC),
                              child: Icon(
                                Icons.assignment,
                                color: Color(0xFF2A6B52),
                              ),
                            ),
                            title: Text(
                              exam.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Przedmiot: ${exam.subject} | Data: ${exam.date}\n'
                              'Zakres: ${exam.scope}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('exams')
                                    .doc(exam.id)
                                    .delete();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

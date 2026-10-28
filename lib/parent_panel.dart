import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'models.dart';
import 'child_lock.dart';

const List<String> availableTextbooks = [
  'Standardowy Podręcznik MEN / Wbudowany',
  'Matematyka z plusem (GWO)',
  'English Class (Pearson)',
  'Steps Plus (Oxford)',
  'Tajemnice przyrody (Nowa Era)',
  'Między nami (GWO - Język polski)',
];

const Map<int, String> dayNamesMap = {
  1: 'Poniedziałek',
  2: 'Wtorek',
  3: 'Środa',
  4: 'Czwartek',
  5: 'Piątek',
  6: 'Sobota',
  7: 'Niedziela',
};

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _selectedNavIndex = 0;
  int _selectedProfileIndex = 0;

  void _minimizeApp() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.minimize();
    }
  }

  void _closeApp() async {
    exit(0);
  }

  void _returnToChildMode(BuildContext ctx) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.setFullScreen(true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
    }
    if (!mounted) return;

    // ignore: use_build_context_synchronously
    if (!ctx.mounted) return;

    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(
        builder: (context) => LockScreenWidget(profile: globalProfiles.first),
      ),
      (route) => false,
    );
  }

  void _showAddChildDialog() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController classCtrl = TextEditingController();
    TextEditingController interestsCtrl = TextEditingController();
    MotivationType selectedMotivation = MotivationType.gamer;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.person_add, color: Color(0xFF2A6B52)),
                  SizedBox(width: 8),
                  Text(
                    'Dodaj nowe dziecko',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Imię dziecka',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: classCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Klasa (np. Klasa 5 SP)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MotivationType>(
                      // ignore: deprecated_member_use
                      value: selectedMotivation,
                      decoration: const InputDecoration(
                        labelText: 'Typ motywacji',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: MotivationType.gamer,
                          child: Text('Gracz'),
                        ),
                        DropdownMenuItem(
                          value: MotivationType.explorer,
                          child: Text('Odkrywca'),
                        ),
                        DropdownMenuItem(
                          value: MotivationType.observer,
                          child: Text('Obserwator'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedMotivation = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Zainteresowania (oddzielone przecinkami)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
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
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      String newId = nameCtrl.text
                          .trim()
                          .toLowerCase()
                          .replaceAll(' ', '_');
                      List<String> interestsList = interestsCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      ChildProfileEntity newChild = ChildProfileEntity(
                        id: newId,
                        name: nameCtrl.text.trim(),
                        statusClass: classCtrl.text.trim().isEmpty
                            ? 'Klasa 4 SP'
                            : classCtrl.text.trim(),
                        motivationType: selectedMotivation,
                        interests: interestsList.isEmpty
                            ? ['Edukacja', 'Gry']
                            : interestsList,
                        weeklySchedule: {
                          1: ['Język polski', 'Matematyka'],
                          2: ['Matematyka', 'Język angielski'],
                        },
                        subjectsConfig: {
                          'Matematyka': SubjectConfiguration(
                            subjectName: 'Matematyka',
                            selectedTextbook: 'Matematyka z plusem (GWO)',
                          ),
                        },
                      );

                      setState(() {
                        globalProfiles.add(newChild);
                        _selectedProfileIndex = globalProfiles.length - 1;
                      });

                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✅ Pomyślnie dodano dziecko: ${newChild.name}!',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Dodaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = globalProfiles[_selectedProfileIndex];

    return Scaffold(
      body: Material(
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 190,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shield,
                          color: Color(0xFF2A6B52),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EduShield',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        side: const BorderSide(color: Color(0xFF2A6B52)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _showAddChildDialog,
                      icon: const Icon(
                        Icons.person_add_alt_1,
                        size: 16,
                        color: Color(0xFF2A6B52),
                      ),
                      label: const Text(
                        'Dodaj dziecko',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A6B52),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'Pulpit'),
                  _buildNavItem(
                    1,
                    Icons.calendar_today_outlined,
                    Icons.calendar_today,
                    'Plan lekcji',
                  ),
                  _buildNavItem(
                    2,
                    Icons.show_chart_outlined,
                    Icons.show_chart,
                    'Postępy',
                  ),
                  _buildNavItem(
                    3,
                    Icons.phonelink_setup_outlined,
                    Icons.phonelink_setup,
                    'Kontrola aplikacji',
                  ),
                  const Spacer(),
                  Divider(color: Colors.grey.shade200),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2A6B52),
                    ),
                    title: const Text(
                      'Tryb dziecka',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A6B52),
                      ),
                    ),
                    onTap: () => _returnToChildMode(context),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.minimize, color: Colors.grey),
                    title: const Text(
                      'Zminimalizuj',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: _minimizeApp,
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.power_settings_new,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Zamknij',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                    onTap: _closeApp,
                  ),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getSectionTitle(_selectedNavIndex),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              // ignore: deprecated_member_use
                              value:
                                  (_selectedProfileIndex >= 0 &&
                                      _selectedProfileIndex <
                                          globalProfiles.length)
                                  ? _selectedProfileIndex
                                  : 0,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF2A6B52),
                              ),
                              items: globalProfiles.asMap().entries.map((
                                entry,
                              ) {
                                int index = entry.key;
                                ChildProfileEntity child = entry.value;
                                return DropdownMenuItem<int>(
                                  value: index,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.face,
                                        size: 20,
                                        color: Color(0xFF2A6B52),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        child.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedProfileIndex = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedNavIndex,
                      children: [
                        _buildDashboardContent(activeProfile),
                        _buildScheduleContent(activeProfile),
                        _buildProgressContent(activeProfile),
                        _buildAppControlContent(activeProfile),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedNavIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: const Color(0xFFE8F5E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? const Color(0xFF2A6B52) : Colors.grey.shade600,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF2A6B52) : Colors.black87,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedNavIndex = index;
          });
        },
      ),
    );
  }

  String _getSectionTitle(int index) {
    switch (index) {
      case 0:
        return 'Pulpit Rodzica';
      case 1:
        return 'Zarządzanie Planem Lekcji';
      case 2:
        return 'Raport Postępów Edukacyjnych';
      case 3:
        return 'Kontrola Aplikacji i Czasu';
      default:
        return 'Pulpit';
    }
  }

  Widget _buildDashboardContent(ChildProfileEntity profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA8E6CF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.face,
                          size: 60,
                          color: Color(0xFF2A6B52),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.statusClass,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: profile.overallProgress / 100.0,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF52C41A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ogólny postęp zadań: ${profile.overallProgress.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedNavIndex = 1;
                          });
                        },
                        child: const Text(
                          'Zarządzaj planem lekcji',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () => _showTextbookSelectorModal(profile),
                        child: const Text(
                          'Wybierz podręczniki',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildScheduleContent(ChildProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harmonogram tygodniowy dla: ${profile.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A6B52),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showEditScheduleDayDialog(profile, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Dodaj lekcje'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: dayNamesMap.length,
              itemBuilder: (context, index) {
                int dayKey = index + 1;
                String dayName = dayNamesMap[dayKey]!;
                List<String> subjects = profile.weeklySchedule[dayKey] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          dayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          subjects.isEmpty
                              ? 'Brak zajęć w tym dniu'
                              : subjects.join(' • '),
                          style: TextStyle(
                            color: subjects.isEmpty
                                ? Colors.grey.shade400
                                : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF2A6B52),
                        ),
                        onPressed: () =>
                            _showEditScheduleDayDialog(profile, dayKey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent(ChildProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Postępy w rozwiązanych zadaniach: ${profile.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: profile.subjectsConfig.values.map((subj) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            subj.subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${subj.completedTasks} / ${subj.totalTasks} zadań (${subj.progressPercentage.toStringAsFixed(0)}%)',
                            style: const TextStyle(
                              color: Color(0xFF2A6B52),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: subj.progressPercentage / 100.0,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          color: const Color(0xFF2A6B52),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Podręcznik: ${subj.selectedTextbook}',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppControlContent(ChildProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blokady i zasady korzystania z komputera dla: ${profile.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildControlTile(
                  title: 'Godzina wieczorna (Blokada nocna)',
                  subtitle: 'Automatyczna blokada urządzenia o godzinie 20:00',
                  icon: Icons.nightlight_round,
                  value: true,
                ),
                _buildControlTile(
                  title: 'Przerwy na odpoczynek',
                  subtitle:
                      '15 minut wymuszonej przerwy po każdej godzinie grania',
                  icon: Icons.timer,
                  value: true,
                ),
                _buildControlTile(
                  title: 'Ścisła blokada startowa',
                  subtitle:
                      'Wymagaj rozwiązania zadań przy każdym uruchomieniu',
                  icon: Icons.lock,
                  value: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF2A6B52)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        value: value,
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2A6B52);
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2A6B52).withValues(alpha: 0.3);
          }
          return Colors.grey.shade300;
        }),
        onChanged: (val) {},
      ),
    );
  }

  void _showEditScheduleDayDialog(ChildProfileEntity child, int? dayKey) {
    int selectedDay = dayKey ?? 1;
    List<String> currentSubjs = child.weeklySchedule[selectedDay] ?? [];
    TextEditingController controller = TextEditingController(
      text: currentSubjs.join(', '),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Edycja planu: ${dayNamesMap[selectedDay]}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Przedmioty (oddzielone przecinkami)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6B52),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                List<String> updated = controller.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                setState(() {
                  child.weeklySchedule[selectedDay] = updated;
                  child.syncSubjectsFromSchedule();
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  void _showTextbookSelectorModal(ChildProfileEntity profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                '📚 Wybór podręczników dla: ${profile.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...profile.subjectsConfig.values.map((subj) {
                String safeValue =
                    availableTextbooks.contains(subj.selectedTextbook)
                    ? subj.selectedTextbook
                    : availableTextbooks[0];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: safeValue,
                    decoration: InputDecoration(
                      labelText: subj.subjectName,
                      border: const OutlineInputBorder(),
                    ),
                    items: availableTextbooks
                        .map(
                          (book) => DropdownMenuItem(
                            value: book,
                            child: Text(
                              book,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          subj.selectedTextbook = val;
                        });
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

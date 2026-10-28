enum MotivationType { gamer, explorer, observer }

class SubjectConfiguration {
  final String subjectName;
  String selectedTextbook;
  int currentBookPage;
  int completedTasks;
  int totalTasks;

  SubjectConfiguration({
    required this.subjectName,
    required this.selectedTextbook,
    this.currentBookPage = 1,
    this.completedTasks = 0,
    this.totalTasks = 20,
  });

  double get progressPercentage =>
      totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;
}

class ChildProfileEntity {
  final String id;
  final String name;
  final String statusClass;
  final MotivationType motivationType;
  List<String> interests;
  Map<int, List<String>> weeklySchedule;
  String? schedulePhotoUrl;
  Map<String, SubjectConfiguration> subjectsConfig;

  ChildProfileEntity({
    required this.id,
    required this.name,
    required this.statusClass,
    required this.motivationType,
    required this.interests,
    required this.weeklySchedule,
    this.schedulePhotoUrl,
    required this.subjectsConfig,
  }) {
    syncSubjectsFromSchedule();
  }

  void syncSubjectsFromSchedule() {
    Set<String> scheduleSubjects = {};
    for (var daySubjects in weeklySchedule.values) {
      scheduleSubjects.addAll(daySubjects);
    }

    for (String subject in scheduleSubjects) {
      if (!subjectsConfig.containsKey(subject)) {
        subjectsConfig[subject] = SubjectConfiguration(
          subjectName: subject,
          selectedTextbook: 'Standardowy Podręcznik MEN / Wbudowany',
        );
      }
    }
  }

  double get overallProgress {
    if (subjectsConfig.isEmpty) return 0.0;
    double sum = subjectsConfig.values
        .map((e) => e.progressPercentage)
        .fold(0.0, (prev, element) => prev + element);
    return sum / subjectsConfig.values.length;
  }

  List<String> getNextDaySubjects() {
    int today = DateTime.now().weekday;
    int nextDay = today == 7 ? 1 : today + 1;
    return weeklySchedule[nextDay] ?? ['Matematyka', 'Język angielski'];
  }
}

class TaskEntity {
  final String id;
  final String childId;
  final String subject;
  final String taskText;
  final String correctAnswer;
  final String hint;
  final String explanation;

  TaskEntity({
    required this.id,
    required this.childId,
    required this.subject,
    required this.taskText,
    required this.correctAnswer,
    required this.hint,
    required this.explanation,
  });
}

List<ChildProfileEntity> globalProfiles = [
  ChildProfileEntity(
    id: 'mieszko',
    name: 'Mieszko',
    statusClass: 'Klasa 4 SP',
    motivationType: MotivationType.gamer,
    interests: ['Minecraft', 'Roblox', 'BMX', 'Rugby'],
    weeklySchedule: {
      1: ['Język polski', 'Matematyka', 'Historia'],
      2: ['Matematyka', 'Przyroda', 'Język angielski'],
      3: ['Język polski', 'Matematyka', 'W-F'],
      4: ['Historia', 'Plastyka', 'Język angielski'],
      5: ['Język polski', 'Przyroda', 'Informatyka'],
      6: [],
      7: ['Język polski', 'Matematyka', 'Historia'],
    },
    subjectsConfig: {
      'Język angielski': SubjectConfiguration(
          subjectName: 'Język angielski',
          selectedTextbook: 'English Class (Pearson) - Poziom A1+',
          completedTasks: 16,
          totalTasks: 20),
      'Matematyka': SubjectConfiguration(
          subjectName: 'Matematyka',
          selectedTextbook: 'Matematyka z plusem (GWO)',
          completedTasks: 12,
          totalTasks: 20),
    },
  ),
];

List<TaskEntity> globalTasks = [
  TaskEntity(
      id: 'E1',
      childId: 'mieszko',
      subject: 'Język angielski',
      taskText: 'Ile lat ma Tom według tekstu? Wpisz liczbę słownie po angielsku.',
      correctAnswer: 'twelve',
      hint: 'To liczba o jeden większa niż 11.',
      explanation: 'W tekście Tom mówi: "I\'m twelve years old" (mam 12 lat).'),
  TaskEntity(
      id: 'M1',
      childId: 'mieszko',
      subject: 'Matematyka',
      taskText: 'Potrzebujesz 64 bloków drewna na budowę, a masz już 38. Ile bloków ci brakuje?',
      correctAnswer: '26',
      hint: 'Wykonaj odejmowanie: 64 - 38.',
      explanation: '64 minus 38 daje 26 brakujących bloków.'),
];
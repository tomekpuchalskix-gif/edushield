// ignore_for_file: unnecessary_import

class ParentAccount {
  static String pin = '1234';
}

enum MotivationType { explorer, achiever }

class SchoolSubjects {
  // Pełna, zaktualizowana lista przedmiotów dla Szkoły Podstawowej (z rozdzieloną plastyką i muzyką)
  static const List<String> primarySchool = [
    'Język polski',
    'Matematyka',
    'Język angielski',
    'Geografia',
    'Biologia',
    'Historia',
    'Informatyka',
    'Plastyka',
    'Muzyka',
    'Technika',
    'Edukacja zdrowotna',
    'Religia',
    'Wychowanie fizyczne',
    'Godzina wychowawcza',
  ];

  // Lista przedmiotów dla Szkoły Średniej / Technikum
  static const List<String> highSchool = [
    'Język polski',
    'Matematyka',
    'Język angielski',
    'Język obcy drugi (np. niemiecki)',
    'Przedmioty zawodowe / techniczne',
    'Fizyka',
    'Chemia',
    'Biologia',
    'Geografia',
    'Historia',
    'WOS',
    'Informatyka',
    'Wychowanie fizyczne',
  ];

  static List<String> getForSchoolType(String schoolType) {
    if (schoolType.contains('podstawowa')) {
      return primarySchool;
    } else {
      return highSchool;
    }
  }
}

class ChildProfileEntity {
  final String id;
  final String? parentId;
  final String name;
  final String schoolType;
  final String statusClass;
  final MotivationType motivationType;
  final List<String>
  interests; // Zainteresowania dziecka (np. do personalizacji zadań)
  final Map<String, dynamic> weeklySchedule;
  final Map<String, dynamic> subjectsConfig;

  ChildProfileEntity({
    required this.id,
    this.parentId,
    required this.name,
    required this.schoolType,
    required this.statusClass,
    required this.motivationType,
    required this.interests,
    required this.weeklySchedule,
    required this.subjectsConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'schoolType': schoolType,
      'statusClass': statusClass,
      'motivationType': motivationType.index,
      'interests': interests,
      'weeklySchedule': weeklySchedule,
      'subjectsConfig': subjectsConfig,
    };
  }

  factory ChildProfileEntity.fromMap(Map<String, dynamic> map) {
    return ChildProfileEntity(
      id: map['id'] ?? '',
      parentId: map['parentId'],
      name: map['name'] ?? '',
      schoolType: map['schoolType'] ?? 'Szkoła podstawowa',
      statusClass: map['statusClass'] ?? 'Klasa 5 SP',
      motivationType: MotivationType.values[map['motivationType'] ?? 0],
      interests: List<String>.from(map['interests'] ?? []),
      weeklySchedule: Map<String, dynamic>.from(map['weeklySchedule'] ?? {}),
      subjectsConfig: Map<String, dynamic>.from(map['subjectsConfig'] ?? {}),
    );
  }
}

// Model sprawdzianu zapisywany w bazie
class ExamEntity {
  final String id;
  final String childId;
  final String subject;
  final String title;
  final String date;
  final String scope; // Zakres materiału

  ExamEntity({
    required this.id,
    required this.childId,
    required this.subject,
    required this.title,
    required this.date,
    required this.scope,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'subject': subject,
      'title': title,
      'date': date,
      'scope': scope,
    };
  }

  factory ExamEntity.fromMap(Map<String, dynamic> map) {
    return ExamEntity(
      id: map['id'] ?? '',
      childId: map['childId'] ?? '',
      subject: map['subject'] ?? '',
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      scope: map['scope'] ?? '',
    );
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

List<ChildProfileEntity> globalProfiles = [];

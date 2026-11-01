import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'polish_questions.dart';
import 'english_questions.dart';
import 'informatics_questions.dart';
import 'math_questions.dart';
import 'biology_questions.dart';
import 'geography_questions.dart';
import 'history_questions.dart';

class DailyQuizManager {
  static Future<Map<String, List<Map<String, dynamic>>>>
  getDailyQuestionsPerSubject() async {
    final prefs = await SharedPreferences.getInstance();

    final todayString = DateTime.now().toIso8601String().split('T')[0];

    final lastSavedDate = prefs.getString('last_custom_quiz_date');

    int weekday = DateTime.now().weekday;

    List<String> targetSubjects = [];

    switch (weekday) {
      case DateTime.sunday:
      case DateTime.saturday:
        targetSubjects = [
          'Język angielski',
          'Historia',
          'Język polski',
          'Matematyka',
        ];
        break;

      case DateTime.monday:
        targetSubjects = [
          'Biologia',
          'Matematyka',
          'Muzyka',
          'Język polski',
          'Edukacja zdrowotna',
          'Wychowanie fizyczne',
        ];
        break;

      case DateTime.tuesday:
        targetSubjects = [
          'Język angielski',
          'Matematyka',
          'Wych-Fiz',
          'Religia',
        ];
        break;

      case DateTime.wednesday:
        targetSubjects = [
          'Plastyka',
          'Geografia',
          'Matematyka',
          'Język polski',
        ];
        break;

      case DateTime.thursday:
        targetSubjects = [
          'Technika',
          'Wych-Fiz',
          'Historia',
          'Informatyka',
          'Język angielski',
          'Język polski',
          'Godz-Wychow',
        ];
        break;

      default:
        targetSubjects = ['Matematyka', 'Język polski'];
    }

    final allDatabases = _getAllDatabases();

    Map<String, List<Map<String, dynamic>>> dailySet = {};

    bool isNewDay = lastSavedDate != todayString;

    for (var subjectName in targetSubjects) {
      final List<Map<String, dynamic>> fullPool =
          allDatabases[subjectName] ??
          [
            {
              'id': '${subjectName}_default_1',
              'subject': subjectName,
              'taskText':
                  'Zadanie specjalne ($subjectName): Podaj wynik działania 5 + 5 * 2',
              'correctAnswer': '15',
              'hint': 'Pamiętaj o kolejności wykonywania działań (mnożenie pierwsze!).',
              'explanation':
                  'Najpierw mnożymy 5 * 2 = 10, a potem dodajemy 5 = 15.',
              'options': ['15', '20', '10', '25'],
            },
          ];

      if (isNewDay) {
        final shuffled = List<Map<String, dynamic>>.from(fullPool)
          ..shuffle(Random());

        int takeCount = shuffled.length > 10 ? 10 : shuffled.length;

        final List<Map<String, dynamic>> selectedQuestions = shuffled
            .take(takeCount)
            .toList();

        List<String> selectedIds = selectedQuestions
            .map((q) => q['id'].toString())
            .toList();

        await prefs.setStringList('daily_subject_$subjectName', selectedIds);

        dailySet[subjectName] = selectedQuestions;
      } else {
        final List<String>? savedIds = prefs.getStringList(
          'daily_subject_$subjectName',
        );

        if (savedIds != null) {
          dailySet[subjectName] = fullPool
              .where((q) => savedIds.contains(q['id'].toString()))
              .toList();
        } else {
          final shuffled = List<Map<String, dynamic>>.from(fullPool)
            ..shuffle(Random());

          int takeCount = shuffled.length > 10 ? 10 : shuffled.length;

          dailySet[subjectName] = shuffled.take(takeCount).toList();
        }
      }
    }

    if (isNewDay) {
      await prefs.setString('last_custom_quiz_date', todayString);
    }

    return dailySet;
  }

  static Map<String, List<Map<String, dynamic>>> _getAllDatabases() {
    return {
      'Matematyka': MathQuestionsDatabase.questions,
      'Język polski': PolishQuestionsDatabase.questions,
      'Język angielski': EnglishQuestionsDatabase.questions,
      'Angielski': EnglishQuestionsDatabase.questions,
      'Informatyka': InformaticsQuestionsDatabase.questions,
      'Biologia': BiologyQuestionsDatabase.questions,
      'Geografia': GeographyQuestionsDatabase.questions,
      'Historia': HistoryQuestionsDatabase.questions,
    };
  }
}

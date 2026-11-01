import '../models.dart';

class GeografiaRozdzial1 {
  static List<TaskEntity> getTasks(String childId) {
    return [
      TaskEntity(
        id: 'geo_sp5_r1_1',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Co to jest geografia i co oznacza jej nazwa w języku starożytnych Greków?',
        correctAnswer: 'opis Ziemi',
        hint: 'Nauka o świecie; nazwa oznacza dosłownie opis naszej planety.',
        explanation: 'Geografia to nauka badająca świat, a jej grecka nazwa oznacza „opis Ziemi”.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_2',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Co jest głównym przedmiotem badań geografii?',
        correctAnswer: 'środowisko geograficzne',
        hint: 'Składa się z przyrody oraz elementów wytworzonych przez człowieka.',
        explanation: 'Przedmiotem badań jest środowisko geograficzne łączące przyrodę i działalność człowieka.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_3',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Jak nazywamy obraz powierzchni Ziemi lub jej fragmentu widziany z góry w pomniejszeniu?',
        correctAnswer: 'mapa',
        hint: 'Korzystamy z niej, szukając drogi lub państw.',
        explanation: 'Mapa to obraz powierzchni Ziemi widziany z góry, przedstawiony na płaszczyźnie i w pomniejszeniu.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_4',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Jakie są najważniejsze elementy mapy? Wpisz jeden z nich (np. legenda, skala...).',
        correctAnswer: 'legenda',
        hint: 'Zawiera zestawienie wszystkich znaków kartograficznych i ich wyjaśnienie.',
        explanation:
            'Najważniejsze elementy mapy to treść, skala, legenda oraz tytuł.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_5',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Na jakie trzy grupy dzielimy znaki kartograficzne na mapie?',
        correctAnswer: 'punktowe, liniowe, powierzchniowe',
        hint: 'Zależą od kształtu obiektów: kropka, linia lub obszar.',
        explanation: 'Znaki kartograficzne dzielimy na punktowe, liniowe i powierzchniowe.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_6',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Co informuje skala mapy?',
        correctAnswer: 'ile razy pomniejszono odległości',
        hint: 'Mówi o stopniu pomniejszenia rzeczywistych wymiarów w terenie.',
        explanation: 'Skala informuje, ile razy pomniejszono na mapie rzeczywiste odległości lub wymiary obiektów.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_7',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Jakie znasz trzy rodzaje skali? Wpisz je po przecinku.',
        correctAnswer: 'skala liczbowa, skala mianowana, podziałka liniowa',
        hint: 'Jedna z nich to np. 1:1000, druga podaje konkretne jednostki.',
        explanation:
            'Wyróżniamy skalę liczbową, mianowaną oraz podziałkę liniową.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_8',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Przekształć skalę mianowaną 1 cm - 100 000 cm na kilometry. Ile to kilometrów?',
        correctAnswer: '1 km',
        hint: '100 000 cm po zamianie daje 1.',
        explanation: '100 000 cm zamieniamy na 1000 m, co daje dokładnie 1 km.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_9',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Co najlepiej posłuży do zmierzenia długości krętej drogi lub rzeki na mapie?',
        correctAnswer: 'nitka',
        hint: 'Miękki sznureczek układany wzdłuż zakrętów.',
        explanation: 'Do pomiaru krętych tras (np. rzek) stosuje się nitkę oraz podziałkę liniową.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_10',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Jak nazywa się wysokość punktu mierzona od poziomu morza (w skrócie m n.p.m.)?',
        correctAnswer: 'wysokość bezwzględna',
        hint: 'Mierzona zawsze od wyjściowego poziomu morza.',
        explanation: 'Wysokość bezwzględna to wysokość każdego punktu mierzona od poziomu morza (m n.p.m.).',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_11',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Jak nazywają się wyobrażone linie na mapie łączące punkty o tej samej wysokości bezwzględnej?',
        correctAnswer: 'poziomice',
        hint: 'Inaczej nazywane są izohipsami.',
        explanation: 'Poziomice to linie łączące punkty leżące w terenie na takiej samej wysokości n.p.m.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_12',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Jak nazywa się obniżenie terenu znajdujące się między dwoma wierzchołkami góry?',
        correctAnswer: 'przełęcz',
        hint:
            'Miejsce w górach, przez które często prowadzą szlaki turystyczne.',
        explanation: 'Przełęcz to obniżenie terenu znajdujące się między dwoma wierzchołkami.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_13',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Jakie barwy odpowiadają nizinom na mapach hipsometrycznych?',
        correctAnswer: 'odcienie zieleni',
        hint: 'Obszary od 0 do 300 m n.p.m. zaznacza się na...',
        explanation: 'Niziny (0-300 m n.p.m.) na mapach hipsometrycznych oznaczane są odcieniami zieleni.',
      ),
      TaskEntity(
        id: 'geo_sp5_r1_14',
        childId: childId,
        subject: 'Geografia',
        taskText: 'Co to znaczy „zorientować mapę w terenie”?',
        correctAnswer: 'ułożyć tak, aby kierunki pokrywały się z terenem',
        hint: 'Dopasowanie kierunków świata mapy do rzeczywistości.',
        explanation: 'Zorientować mapę w terenie oznacza takie jej ułożenie, aby kierunki na niej pokrywały się z kierunkami w terenie.',
      ),
    ];
  }

  static final Map<String, int> _childMistakesCount = {};

  // Bezpieczna obsługa – przyjmuje zarówno string (ID), jak i obiekt TaskEntity
  static void recordMistake(dynamic taskOrId) {
    String taskId = taskOrId is TaskEntity ? taskOrId.id : taskOrId.toString();
    _childMistakesCount[taskId] = (_childMistakesCount[taskId] ?? 0) + 1;
  }

  static int getMistakesForTask(String taskId) {
    return _childMistakesCount[taskId] ?? 0;
  }

  static List<TaskEntity> getAdaptiveTasksForChild(String childId) {
    List<TaskEntity> allTasks = getTasks(childId);
    // Jawnie podane typy (TaskEntity a, TaskEntity b) całkowicie eliminują błąd typu Object
    allTasks.sort(
      (TaskEntity a, TaskEntity b) =>
          getMistakesForTask(b.id).compareTo(getMistakesForTask(a.id)),
    );
    return allTasks;
  }
}

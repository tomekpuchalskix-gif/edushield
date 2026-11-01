// Plik: interests_data.dart
// Opis: Zawiera bezpieczną listę kategorii zainteresowań dla dzieci oraz
// mechanizm sprawdzający wpisywane przez użytkownika teksty (filtr bezpieczeństwa).

class ContentFilter {
  // Lista słów i fraz absolutnie zakazanych ze względów bezpieczeństwa
  static final List<String> forbiddenWords = [
    'zabijanie',
    'zabij',
    'smierc',
    'przemoc',
    'patologia',
    'agresja',
    // Tutaj możesz dopisywać kolejne niedozwolone wyrazy
  ];

  /// Sprawdza, czy podany tekst jest bezpieczny i nie zawiera zakazanych słów.
  static bool isSafe(String input) {
    String lowerInput = input.toLowerCase();
    for (String word in forbiddenWords) {
      if (lowerInput.contains(word)) {
        return false; // Znaleziono niedozwolone słowo
      }
    }
    return true; // Tekst jest bezpieczny
  }
}

class InterestsData {
  // Domyślna, bogata lista zainteresowań do wyboru w Panelu Rodzica
  static const List<String> defaultInterests = [
    'Roblox',
    'Minecraft',
    'LEGO',
    'Piłka nożna',
    'Rower / BMX',
    'Gry wideo',
    'Modelarstwo',
    'Militaria',
    'Kosmos',
    'Programowanie',
    'Rysowanie / Plastyka',
    'Komiksy',
    'Muzyka',
    'Sport',
  ];
}

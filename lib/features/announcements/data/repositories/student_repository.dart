import '../models/student_model.dart';

/// In-memory repository of all SMS-recipient students in TOPAR-115.
///
/// Phone numbers are in Turkmen E.164 format (+993XXXXXXXXX).
/// The Group Leader (Starstwa) is the app user and is NOT included in this
/// list — they compose and dispatch messages, not receive them via this flow.
abstract final class StudentRepository {
  static const List<Student> classStudents = [
    Student(id: 's01', index: 0,  name: 'Tagyýewa Bibihatyja',          phone: '+99363890901'),
    Student(id: 's02', index: 1,  name: 'Köwşenowa Gunça',              phone: '+99371383004'),
    Student(id: 's03', index: 2,  name: 'Ötemowa Nazira',               phone: '+99371548406'),
    Student(id: 's04', index: 3,  name: 'Batyrow Gaýrat',               phone: '+99364228425'),
    Student(id: 's05', index: 4,  name: 'Annanyýazow Annanyýaz',        phone: '+99362131888'),
    Student(id: 's06', index: 5,  name: 'Ataýew Gurbanmyrat',           phone: '+99363553616'),
    Student(id: 's07', index: 6,  name: 'Islimow Kemal',                phone: '+99364618342'),
    Student(id: 's08', index: 7,  name: 'Sapargulyýew Nazar',           phone: '+99365568490'),
    Student(id: 's09', index: 8,  name: 'Akmämmedow Muhammet',          phone: '+99362964450'),
    Student(id: 's10', index: 9,  name: 'Muhammedow Batyr',             phone: '+99365852785'),
    Student(id: 's11', index: 10, name: 'Süleýmanow Tahyr',             phone: '+99361957294'),
    Student(id: 's12', index: 11, name: 'Döwletgulyýew Abdyrahman',     phone: '+99365254766'),
    Student(id: 's13', index: 0,  name: 'Myradowa Oguljan',             phone: '+99371582120'),
    Student(id: 's14', index: 1,  name: 'Meredowa Arazjemal',           phone: '+99365670096'),
    Student(id: 's15', index: 2,  name: 'Tuşiýewa Abadan',              phone: '+99361762819', isGroupLeader: true),
    Student(id: 's16', index: 3,  name: 'Omarowa Güljahan',             phone: '+99371150806'),
    Student(id: 's17', index: 4,  name: 'Baýramowa Nurana',             phone: '+99362765960'),
    Student(id: 's18', index: 5,  name: 'Geldimyradow Gurbammuhammet',  phone: '+99362175665'),
    Student(id: 's19', index: 6,  name: 'Şyhmyradow Serdar',           phone: '+99364013815'),
    Student(id: 's20', index: 7,  name: 'Maksumow Eziz',               phone: '+99365374938'),
    Student(id: 's21', index: 8,  name: 'Esenow Nurmuhammet',           phone: '+99365155197'),
    Student(id: 's22', index: 9,  name: 'Baýrammyradow Atamyrat',      phone: '+99371930947'),
    Student(id: 's23', index: 10, name: 'Hojabalkanow Berdimyrat',      phone: '+99361032689'),
    Student(id: 's24', index: 11, name: 'Ýaňabergenow Ulugbek',        phone: '+99362244528'),
    Student(id: 's25', index: 0,  name: 'Öwezow Baba',                  phone: '+99361915665'),
  ];

  /// Normalizes phone number strings to pure digits (e.g. "+993 61 76 28 19" -> "61762819").
  static String normalizePhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('993')) {
      digits = digits.substring(3);
    }
    return digits;
  }

  /// Normalizes name strings for flexible matching (case-insensitive & token matching).
  static String normalizeName(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Finds a student by separate first name, last name, and phone number.
  static Student? findStudentByFields({
    required String firstName,
    required String lastName,
    required String phone,
  }) {
    final combined = '$lastName $firstName'.trim();
    return findStudent(combined, phone);
  }

  /// Finds a student by name string (full or tokens) and phone number.
  static Student? findStudent(String nameInput, String phoneInput) {
    final normPhoneInput = normalizePhone(phoneInput);
    final normNameInput = normalizeName(nameInput);
    final inputTokens = normNameInput.split(' ').where((t) => t.isNotEmpty).toList();

    for (final s in classStudents) {
      final sPhoneNorm = normalizePhone(s.phone);
      final sNameNorm = normalizeName(s.name);
      final sTokens = sNameNorm.split(' ');

      // Phone check
      bool phoneMatch = sPhoneNorm == normPhoneInput;
      if (!phoneMatch && normPhoneInput.length >= 8 && sPhoneNorm.endsWith(normPhoneInput)) {
        phoneMatch = true;
      }

      if (!phoneMatch) continue;

      if (inputTokens.isEmpty) return s;

      // Name check: exact, contained, or token match
      if (sNameNorm == normNameInput) {
        return s;
      }

      final allTokensMatch = inputTokens.every(
        (t) => sTokens.any((st) => st.contains(t) || t.contains(st)),
      );
      if (allTokensMatch) {
        return s;
      }
    }

    return null;
  }

  /// Finds a student purely by normalized phone number (for session restore).
  static Student? findStudentByPhone(String phoneInput) {
    final norm = normalizePhone(phoneInput);
    for (final s in classStudents) {
      final sNorm = normalizePhone(s.phone);
      if (sNorm == norm || (norm.length >= 8 && sNorm.endsWith(norm))) {
        return s;
      }
    }
    return null;
  }
}

import '../models/student_model.dart';

/// In-memory repository of all SMS-recipient students in TOPAR-115.
///
/// Phone numbers are in Turkmen E.164 format (+993XXXXXXXXX).
/// Passwords are unique 6-character alphanumeric codes assigned by admin.
abstract final class StudentRepository {
  static const List<Student> classStudents = [
    Student(id: 's01', index: 0,  name: 'Tagyýewa Bibihatyja',          phone: '+99363890901',  password: 'TK8421'),
    Student(id: 's02', index: 1,  name: 'Köwşenowa Gunça',              phone: '+99371383004',  password: 'KG5937'),
    Student(id: 's03', index: 2,  name: 'Ötemowa Nazira',               phone: '+99371548406',  password: 'ON3762'),
    Student(id: 's04', index: 3,  name: 'Batyrow Gaýrat',               phone: '+99364228425',  password: 'BG9154'),
    Student(id: 's05', index: 4,  name: 'Annanyýazow Annanyýaz',        phone: '+99362131888',  password: 'AA2683'),
    Student(id: 's06', index: 5,  name: 'Ataýew Gurbanmyrat',           phone: '+99363553616',  password: 'AG7045'),
    Student(id: 's07', index: 6,  name: 'Islimow Kemal',                phone: '+99364618342',  password: 'IK6318'),
    Student(id: 's08', index: 7,  name: 'Sapargulyýew Nazar',           phone: '+99365568490',  password: 'SN4729'),
    Student(id: 's09', index: 8,  name: 'Akmämmedow Muhammet',          phone: '+99362964450',  password: 'AM8536'),
    Student(id: 's10', index: 9,  name: 'Muhammedow Batyr',             phone: '+99365852785',  password: 'MB1947'),
    Student(id: 's11', index: 10, name: 'Süleýmanow Tahyr',             phone: '+99361957294',  password: 'ST3281'),
    Student(id: 's12', index: 11, name: 'Döwletgulyýew Abdyrahman',     phone: '+99365254766',  password: 'DA5674'),
    Student(id: 's13', index: 0,  name: 'Myradowa Oguljan',             phone: '+99371582120',  password: 'MO7392'),
    Student(id: 's14', index: 1,  name: 'Meredowa Arazjemal',           phone: '+99365670096',  password: 'MA4815'),
    Student(id: 's15', index: 2,  name: 'Tuşiýewa Abadan',              phone: '+99361762819',  password: 'TA9263', isGroupLeader: true),
    Student(id: 's16', index: 3,  name: 'Omarowa Güljahan',             phone: '+99371150806',  password: 'OG6148'),
    Student(id: 's17', index: 4,  name: 'Baýramowa Nurana',             phone: '+99362765960',  password: 'BN2537'),
    Student(id: 's18', index: 5,  name: 'Geldimyradow Gurbammuhammet',  phone: '+99362175665',  password: 'GG8094'),
    Student(id: 's19', index: 6,  name: 'Şyhmyradow Serdar',           phone: '+99364013815',  password: 'SS1463'),
    Student(id: 's20', index: 7,  name: 'Maksumow Eziz',               phone: '+99365374938',  password: 'ME7825'),
    Student(id: 's21', index: 8,  name: 'Esenow Nurmuhammet',           phone: '+99365155197',  password: 'EN3916'),
    Student(id: 's22', index: 9,  name: 'Baýrammyradow Atamyrat',      phone: '+99371930947',  password: 'BA5247'),
    Student(id: 's23', index: 10, name: 'Hojabalkanow Berdimyrat',      phone: '+99361032689',  password: 'HB6038'),
    Student(id: 's24', index: 11, name: 'Ýaňabergenow Ulugbek',        phone: '+99362244528',  password: 'YU9471'),
    Student(id: 's25', index: 0,  name: 'Öwezow Baba',                  phone: '+99361915665',  password: 'OB2853'),
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

  /// Finds a student by separate first name, last name, phone number, and password.
  /// All four fields must match for login to succeed.
  static Student? findStudentByFields({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) {
    final combined = '$lastName $firstName'.trim();
    return findStudent(combined, phone, password);
  }

  /// Finds a student by name string (full or tokens), phone number, and password.
  static Student? findStudent(String nameInput, String phoneInput, String passwordInput) {
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

      // Name check: exact, contained, or token match
      bool nameMatch = false;
      if (inputTokens.isEmpty) {
        nameMatch = true;
      } else if (sNameNorm == normNameInput) {
        nameMatch = true;
      } else {
        final allTokensMatch = inputTokens.every(
          (t) => sTokens.any((st) => st.contains(t) || t.contains(st)),
        );
        if (allTokensMatch) nameMatch = true;
      }
      if (!nameMatch) continue;

      // Password check — case-sensitive exact match
      if (s.password == passwordInput.trim()) {
        return s;
      }
    }

    return null;
  }

  /// Finds a student purely by ID (for session restore).
  static Student? findStudentById(String id) {
    for (final s in classStudents) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Finds a student purely by normalized phone number (legacy fallback).
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


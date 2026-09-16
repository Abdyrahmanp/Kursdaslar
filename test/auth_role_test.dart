import 'package:flutter_test/flutter_test.dart';
import 'package:topar_115/features/announcements/data/repositories/student_repository.dart';

void main() {
  group('TOPAR-115 Authentication & Role Matching Tests', () {
    test('Tuşiýewa Abadan login identifies as Starşy (Group Leader)', () {
      final match = StudentRepository.findStudent('Tuşiýewa Abadan', '+993 61 76 28 19');
      expect(match, isNotNull);
      expect(match!.name, contains('Tuşiýewa Abadan'));
      expect(match.isGroupLeader, isTrue);
    });

    test('Flexible phone format and reverse name order matching for Starşy', () {
      final match = StudentRepository.findStudent('Abadan Tuşiýewa', '61762819');
      expect(match, isNotNull);
      expect(match!.isGroupLeader, isTrue);
    });

    test('Normal student login identifies as regular student (not Starşy)', () {
      final match = StudentRepository.findStudent('Tagyýewa Bibihatyja', '+99363890901');
      expect(match, isNotNull);
      expect(match!.name, equals('Tagyýewa Bibihatyja'));
      expect(match.isGroupLeader, isFalse);
    });

    test('Invalid credentials return null', () {
      final match = StudentRepository.findStudent('Nätanyş Ulanyjy', '+99360000000');
      expect(match, isNull);
    });

    test('findStudentByFields identifies Starşy with separate name fields', () {
      final match = StudentRepository.findStudentByFields(
        firstName: 'Abadan',
        lastName: 'Tuşiýewa',
        phone: '+993 61 76 28 19',
      );
      expect(match, isNotNull);
      expect(match!.isGroupLeader, isTrue);
    });

    test('findStudentByFields identifies normal student with separate fields', () {
      final match = StudentRepository.findStudentByFields(
        firstName: 'Bibihatyja',
        lastName: 'Tagyýewa',
        phone: '+99363890901',
      );
      expect(match, isNotNull);
      expect(match!.isGroupLeader, isFalse);
    });

    test('Class list contains 25 students', () {
      expect(StudentRepository.classStudents.length, equals(25));
    });
  });
}

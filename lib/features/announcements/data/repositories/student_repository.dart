import '../models/student_model.dart';

/// In-memory repository of all 25 SMS-recipient students in TOPAR-115.
///
/// Phone numbers use placeholder Turkmen E.164 format (+993 6X XXX XXXX).
/// Replace each [phone] with the real number before production deployment.
///
/// The Group Leader (Starstwa) is the app user and is NOT included in this
/// list — they compose and dispatch messages, not receive them via this flow.
abstract final class StudentRepository {
  static const List<Student> classStudents = [
    Student(id: 's01', index: 0,  name: 'Aýna Berdiyewa',        phone: '+99361100001'),
    Student(id: 's02', index: 1,  name: 'Merjen Amanowa',         phone: '+99361100002'),
    Student(id: 's03', index: 2,  name: 'Ogulgerek Muhammedowa',  phone: '+99361100003'),
    Student(id: 's04', index: 3,  name: 'Şöhrat Durdyýew',        phone: '+99361100004'),
    Student(id: 's05', index: 4,  name: 'Döwran Nurmuhammedow',   phone: '+99361100005'),
    Student(id: 's06', index: 5,  name: 'Maksat Myradow',         phone: '+99361100006'),
    Student(id: 's07', index: 6,  name: 'Hydyr Geldiýew',         phone: '+99361100007'),
    Student(id: 's08', index: 7,  name: 'Selbi Annaýewa',         phone: '+99361100008'),
    Student(id: 's09', index: 8,  name: 'Güljahan Orazowa',       phone: '+99361100009'),
    Student(id: 's10', index: 9,  name: 'Akmyrat Aşyrow',         phone: '+99361100010'),
    Student(id: 's11', index: 10, name: 'Gurban Hojamämmedow',    phone: '+99361100011'),
    Student(id: 's12', index: 11, name: 'Maral Hallyýewa',        phone: '+99361100012'),
    Student(id: 's13', index: 0,  name: 'Zöhre Çaryýewa',         phone: '+99361100013'),
    Student(id: 's14', index: 1,  name: 'Aýşat Annageldiyewa',    phone: '+99361100014'),
    Student(id: 's15', index: 2,  name: 'Bagtygül Jumaýewa',      phone: '+99361100015'),
    Student(id: 's16', index: 3,  name: 'Mekan Öwezow',           phone: '+99361100016'),
    Student(id: 's17', index: 4,  name: 'Yhlas Arazow',           phone: '+99361100017'),
    Student(id: 's18', index: 5,  name: 'Merdan Rejepow',         phone: '+99361100018'),
    Student(id: 's19', index: 6,  name: 'Enejan Myratdurdyýewa',  phone: '+99361100019'),
    Student(id: 's20', index: 7,  name: 'Gülnara Söýünowa',       phone: '+99361100020'),
    Student(id: 's21', index: 8,  name: 'Saparmyrat Hallyýew',    phone: '+99361100021'),
    Student(id: 's22', index: 9,  name: 'Nurgözel Mämmedowa',     phone: '+99361100022'),
    Student(id: 's23', index: 10, name: 'Amangeldi Ataýew',       phone: '+99361100023'),
    Student(id: 's24', index: 11, name: 'Ogulsenem Nurlyýewa',    phone: '+99361100024'),
    Student(id: 's25', index: 0,  name: 'Altyn Muhammedowa',      phone: '+99361100025'),
  ];
}

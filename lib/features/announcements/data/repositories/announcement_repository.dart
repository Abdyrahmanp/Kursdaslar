import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';

class AnnouncementNotifier extends StateNotifier<List<Announcement>> {
  AnnouncementNotifier() : super(_initialAnnouncements);

  static final List<Announcement> _initialAnnouncements = [
    Announcement(
      id: 'ann_01',
      title: '📢 Ertirki Ders Wagty Özgerdi',
      content: 'Salam topar! Ertir ir bilen sagat 09:00-da bolmaly dersimiz sagat 10:30-a geçirildi. Ähliňiz wagtynda geliň.',
      senderName: 'Tuşiýewa Abadan (Starşy)',
      senderPhone: '+993 61 76 28 19',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      recipientCount: 25,
      isUrgent: true,
    ),
    Announcement(
      id: 'ann_02',
      title: '📚 Öý Işi we Amaly Ýapgylar',
      content: 'Matematika we Kompýuter Ylymlary dersi boýunça berlen 3-nji amaly işi şu anna gününe çenli tabşyrmaly.',
      senderName: 'Tuşiýewa Abadan (Starşy)',
      senderPhone: '+993 61 76 28 19',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      recipientCount: 25,
      isUrgent: false,
    ),
    Announcement(
      id: 'ann_03',
      title: '🎓 Topar Ýygnagy',
      content: 'Şenbe güni sagat 14:00-da fakultet zalynda umumy topar ýygnagy bolar. Gatnaşmak ähli talyplar üçin hökmanydyr.',
      senderName: 'Tuşiýewa Abadan (Starşy)',
      senderPhone: '+993 61 76 28 19',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      recipientCount: 25,
      isUrgent: false,
    ),
  ];

  void addAnnouncement({
    required String content,
    int recipientCount = 25,
    bool isUrgent = false,
  }) {
    final title = content.length > 30
        ? '${content.substring(0, 30)}…'
        : content;

    final newAnn = Announcement(
      id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      senderName: 'Tuşiýewa Abadan (Starşy)',
      senderPhone: '+993 61 76 28 19',
      timestamp: DateTime.now(),
      recipientCount: recipientCount,
      isUrgent: isUrgent,
    );

    state = [newAnn, ...state];
  }
}

final announcementProvider =
    StateNotifierProvider<AnnouncementNotifier, List<Announcement>>((ref) {
  return AnnouncementNotifier();
});

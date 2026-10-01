import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/network/byethost_http_client.dart';
import '../models/timetable_model.dart';

class TimetableApiService {
  final http.Client _client;

  TimetableApiService({http.Client? client})
      : _client = client ?? ByethostHttpClient();

  static final Uri _timetableUri = Uri.parse(AppConstants.timetableUrl);

  /// Fetch full schedule from backend (MySQL / data_timetable.json)
  Future<Map<int, List<ClassEntry>>?> fetchTimetable() async {
    try {
      final response = await _client
          .get(_timetableUri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        dynamic dataMap;
        if (decoded is Map && decoded['data'] != null) {
          dataMap = decoded['data'];
        } else if (decoded is Map) {
          dataMap = decoded;
        }

        if (dataMap is Map) {
          final Map<int, List<ClassEntry>> result = {};
          dataMap.forEach((key, val) {
            final dayInt = int.tryParse(key.toString());
            if (dayInt != null && val is List) {
              result[dayInt] = val
                  .map((e) => ClassEntry.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          });
          return result;
        }
      }
      debugPrint('[TimetableApiService] fetch failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[TimetableApiService] fetchTimetable error: $e');
      return null;
    }
  }

  /// Save full schedule to backend
  Future<bool> saveSchedule(Map<int, List<ClassEntry>> schedule) async {
    try {
      final payload = {
        'schedule': schedule.map((key, list) =>
            MapEntry(key.toString(), list.map((e) => e.toJson()).toList())),
      };

      final response = await _client
          .post(
            _timetableUri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[TimetableApiService] saveSchedule error: $e');
      return false;
    }
  }

  /// Save single day schedule to backend
  Future<bool> saveDay(int day, List<ClassEntry> lessons) async {
    try {
      final payload = {
        'day': day,
        'lessons': lessons.map((e) => e.toJson()).toList(),
      };

      final response = await _client
          .post(
            _timetableUri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[TimetableApiService] saveDay error: $e');
      return false;
    }
  }

  void dispose() => _client.close();
}

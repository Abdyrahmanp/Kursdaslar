import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../features/subjects/data/models/topic_model.dart';

/// Universal file picker bridge:
/// - On Android / iOS: Calls the native platform file chooser (`com.fifteen.app/file_picker`).
/// - On Linux / Desktop: Invokes native file dialog (zenity) so files can be picked on PC as well.
/// Returns both the raw bytes (for server upload) and metadata.
class DeviceFilePicker {
  static const MethodChannel _channel = MethodChannel('com.fifteen.app/file_picker');

  /// Prompts system file chooser to pick a real file from storage.
  /// Returns a [PickedFile] with raw bytes + metadata, or null if cancelled.
  static Future<PickedFile?> pickRawFile({String filterType = '*/*'}) async {
    // 1. Desktop Linux support (zenity)
    if (!kIsWeb && Platform.isLinux) {
      try {
        final result = await Process.run('zenity', [
          '--file-selection',
          '--title=Faýly saýlaň (PDF, PPTX, Resim)',
        ]);
        if (result.exitCode == 0) {
          final filePath = result.stdout.toString().trim();
          if (filePath.isNotEmpty) {
            final file = File(filePath);
            if (await file.exists()) {
              final fileName = file.uri.pathSegments.last;
              final fileLength = await file.length();
              final bytes = await file.readAsBytes();
              final type = _detectType(fileName);
              return PickedFile(
                name: fileName,
                type: type,
                size: _formatSize(fileLength),
                bytes: bytes,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('[DeviceFilePicker] Desktop file pick fallback: $e');
      }
      return null;
    }

    // 2. Android / Mobile platform channel
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickFile', {
        'type': filterType,
      });

      if (res == null) return null;

      final name = res['name']?.toString() ?? 'Faýl';
      final size = res['size']?.toString() ?? '1 MB';
      final type = res['type']?.toString().toLowerCase() ?? 'pdf';
      final dataBase64 = res['data']?.toString() ?? '';

      // The native side sends base64-encoded bytes
      Uint8List? bytes;
      if (dataBase64.isNotEmpty) {
        try {
          // Strip data URI prefix if present
          final raw = dataBase64.contains('base64,')
              ? dataBase64.split('base64,').last
              : dataBase64;
          bytes = base64Decode(raw);
        } catch (_) {}
      }

      return PickedFile(
        name: name,
        type: type,
        size: size,
        bytes: bytes,
        fallbackDataUri: dataBase64,
      );
    } catch (e) {
      debugPrint('[DeviceFilePicker] Mobile picker error: $e');
      return null;
    }
  }

  /// Legacy: Pick a file and return a TopicAttachment with base64 urlOrData.
  /// Only used as fallback when server upload fails (images only).
  static Future<TopicAttachment?> pickFileFromDevice({String filterType = '*/*'}) async {
    final picked = await pickRawFile(filterType: filterType);
    if (picked == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    String urlOrData = '';
    if (picked.bytes != null) {
      final mimePrefix = _mimePrefix(picked.type, picked.name);
      urlOrData = mimePrefix + base64Encode(picked.bytes!);
    } else if (picked.fallbackDataUri != null) {
      urlOrData = picked.fallbackDataUri!;
    }

    return TopicAttachment(
      id: 'local_$now',
      name: picked.name,
      type: picked.type,
      size: picked.size,
      urlOrData: urlOrData,
      pageCount: picked.type == 'pptx' ? 10 : (picked.type == 'pdf' ? 6 : 1),
      slideTitles: picked.type == 'pptx'
          ? List.generate(10, (i) => '${picked.name} — Slaýd ${i + 1}')
          : (picked.type == 'pdf' ? List.generate(6, (i) => '${picked.name} — Sahypa ${i + 1}') : []),
    );
  }

  static String _detectType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png') || lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') || lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return 'image';
    }
    if (lower.endsWith('.pdf')) {
      return 'pdf';
    }
    if (lower.endsWith('.pptx') || lower.endsWith('.ppt')) {
      return 'pptx';
    }
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) {
      return 'doc';
    }
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      return 'xlsx';
    }
    return 'file';
  }

  static String _mimePrefix(String type, String name) {
    final lower = name.toLowerCase();
    if (type == 'image') {
      if (lower.endsWith('.png')) return 'data:image/png;base64,';
      if (lower.endsWith('.gif')) return 'data:image/gif;base64,';
      if (lower.endsWith('.webp')) return 'data:image/webp;base64,';
      return 'data:image/jpeg;base64,';
    }
    if (type == 'pdf') return 'data:application/pdf;base64,';
    if (type == 'pptx') {
      return 'data:application/vnd.openxmlformats-officedocument.presentationml.presentation;base64,';
    }
    return 'data:application/octet-stream;base64,';
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).round()} KB';
    }
    return '$bytes B';
  }
}

/// Represents a raw file picked from device storage
class PickedFile {
  final String name;
  final String type;
  final String size;
  final Uint8List? bytes;
  final String? fallbackDataUri; // used if bytes not available

  const PickedFile({
    required this.name,
    required this.type,
    required this.size,
    this.bytes,
    this.fallbackDataUri,
  });
}

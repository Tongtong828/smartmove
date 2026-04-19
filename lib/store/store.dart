import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/record.dart';

class CheckInStore extends ChangeNotifier {
  CheckInStore._();

  static final CheckInStore instance = CheckInStore._();

  static const String _storageKey = 'checkin_records';

  final List<CheckInRecord> _records = [];

  List<CheckInRecord> get records => List.unmodifiable(_records);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return;

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    _records
      ..clear()
      ..addAll(
        decoded.map(
          (e) => CheckInRecord.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_records.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> addRecord(CheckInRecord record) async {
    _records.insert(0, record);
    await _save();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  CheckInRecord? getById(String id) {
    try {
      return _records.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CheckInRecord> filteredByTag(String? tagKey) {
    if (tagKey == null || tagKey == 'all') {
      return records;
    }
    return records.where((e) => e.tags.contains(tagKey)).toList();
  }

  int countByTag(String tagKey) {
    return _records.where((e) => e.tags.contains(tagKey)).length;
  }
}
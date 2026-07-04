import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceStore {
  static const _kTotalFunds = 'cso_total_funds';
  static const _kAllocations = 'cso_allocations_remaining';
  static const _kHistory = 'cso_history';

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final totalFunds = prefs.getDouble(_kTotalFunds) ?? 0.0;

    Map<String, double>? remaining;
    final allocRaw = prefs.getString(_kAllocations);
    if (allocRaw != null) {
      final decoded = jsonDecode(allocRaw) as Map<String, dynamic>;
      remaining = decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    List<Map<String, dynamic>> history = [];
    final historyRaw = prefs.getString(_kHistory);
    if (historyRaw != null) {
      final decodedList = jsonDecode(historyRaw) as List<dynamic>;
      history = decodedList.map((item) {
        final entry = Map<String, dynamic>.from(item as Map);
        entry['time'] = DateTime.parse(entry['time'] as String);
        entry['amount'] = (entry['amount'] as num).toDouble();
        return entry;
      }).toList();
    }

    return {
      'totalFunds': totalFunds,
      'remaining': remaining,
      'history': history,
    };
  }

  static Future<void> save({
    required double totalFunds,
    required Map<String, Map<String, dynamic>> allocations,
    required List<Map<String, dynamic>> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_kTotalFunds, totalFunds);

    final remainingMap = allocations.map(
      (key, value) => MapEntry(key, value['remaining'] as double),
    );
    await prefs.setString(_kAllocations, jsonEncode(remainingMap));

    final historyEncodable = history.map((entry) {
      final copy = Map<String, dynamic>.from(entry);
      copy['time'] = (copy['time'] as DateTime).toIso8601String();
      return copy;
    }).toList();
    await prefs.setString(_kHistory, jsonEncode(historyEncodable));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTotalFunds);
    await prefs.remove(_kAllocations);
    await prefs.remove(_kHistory);
  }
}

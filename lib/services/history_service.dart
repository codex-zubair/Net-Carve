import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/ipv4.dart';
import '../core/subnet.dart';

/// A single saved calculation shown on the History screen.
class HistoryEntry {
  final String cidr;
  final DateTime timestamp;

  const HistoryEntry({required this.cidr, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'cidr': cidr,
    'ts': timestamp.millisecondsSinceEpoch,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    cidr: json['cidr'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
  );
}

/// Persists a small, local-only calculation history.
///
/// Nothing is ever transmitted: this uses [SharedPreferences] on-device.
class HistoryService {
  static const String _key = 'netcarve.history.v1';
  static const int _maxEntries = 50;

  /// Loads stored entries, newest first.
  static Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    }
  }

  /// Adds a new entry, de-duplicating and trimming to [_maxEntries].
  static Future<List<HistoryEntry>> add(String cidr) async {
    final entries = await load();
    entries.removeWhere((e) => e.cidr == cidr);
    entries.insert(0, HistoryEntry(cidr: cidr, timestamp: DateTime.now()));
    final trimmed = entries.take(_maxEntries).toList();
    await _save(trimmed);
    return trimmed;
  }

  /// Clears the history.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Removes a single entry by its CIDR string.
  static Future<List<HistoryEntry>> remove(String cidr) async {
    final entries = await load();
    entries.removeWhere((e) => e.cidr == cidr);
    await _save(entries);
    return entries;
  }

  static Future<void> _save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}

/// A small convenience wrapper around [SubnetCalculator] used by the UI when
/// loading a history item back into the calculator.
class HistoryParser {
  const HistoryParser._();

  static SubnetInfo parse(String cidr) => SubnetCalculator.parseCidr(cidr);

  static bool isValid(String cidr) {
    try {
      SubnetCalculator.parseCidr(cidr);
      return true;
    } on FormatException {
      return false;
    } on ArgumentError {
      return false;
    }
  }

  static Ipv4Address? hostAddress(String cidr) {
    try {
      return SubnetCalculator.parseCidr(cidr).firstHost;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}

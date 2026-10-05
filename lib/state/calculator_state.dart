import 'package:flutter/foundation.dart';

import '../core/ipv4.dart';
import '../core/subnet.dart';
import '../services/history_service.dart';

/// A minimal preset shown as a quick-fill chip.
class CidrPreset {
  final String label;
  final String cidr;

  const CidrPreset(this.label, this.cidr);
}

/// Holds the state of the IPv4 subnet calculator and local history.
class CalculatorState extends ChangeNotifier {
  static const List<CidrPreset> presets = [
    CidrPreset('Private /24', '192.168.1.0/24'),
    CidrPreset('Home /16', '10.0.0.0/16'),
    CidrPreset('Cloud VPC /20', '172.16.0.0/20'),
    CidrPreset('Point-to-point /30', '10.10.10.0/30'),
    CidrPreset('Host route /32', '203.0.113.7/32'),
  ];

  String _input = '192.168.1.0/24';
  SubnetInfo? _result;
  String? _error;
  List<HistoryEntry> _history = const [];
  bool _loadingHistory = true;

  String get input => _input;
  SubnetInfo? get result => _result;
  String? get error => _error;
  List<HistoryEntry> get history => _history;
  bool get loadingHistory => _loadingHistory;
  bool get hasResult => _result != null;

  CalculatorState() {
    _recalculate(record: false);
    _loadHistory();
  }

  /// Updates the raw input text and recomputes the result instantly.
  void updateInput(String value) {
    _input = value;
    _recalculate(record: false);
    notifyListeners();
  }

  /// Applies a preset and recalculates.
  void applyPreset(CidrPreset preset) {
    _input = preset.cidr;
    _recalculate(record: false);
    notifyListeners();
  }

  /// Validates, calculates and records the current input into history.
  Future<void> commit() async {
    _recalculate(record: false);
    if (_result != null) {
      _history = await HistoryService.add(_result!.cidr);
    }
    notifyListeners();
  }

  void _recalculate({required bool record}) {
    final trimmed = _input.trim();
    if (trimmed.isEmpty) {
      _result = null;
      _error = null;
      return;
    }
    try {
      _result = SubnetCalculator.parseCidr(trimmed);
      _error = null;
    } on FormatException catch (e) {
      _result = null;
      _error = e.message;
    } on ArgumentError catch (e) {
      _result = null;
      _error = '${e.message}';
    }
  }

  Future<void> _loadHistory() async {
    _history = await HistoryService.load();
    _loadingHistory = false;
    notifyListeners();
  }

  Future<void> removeHistory(String cidr) async {
    _history = await HistoryService.remove(cidr);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await HistoryService.clear();
    _history = const [];
    notifyListeners();
  }

  /// Restores a history entry into the input field.
  void loadHistoryEntry(HistoryEntry entry) {
    _input = entry.cidr;
    _recalculate(record: false);
    notifyListeners();
  }

  /// Parses an arbitrary IPv4 address for the bit inspector.
  Ipv4Address? parseAddress(String value) {
    try {
      return Ipv4Address.parse(value);
    } on FormatException {
      return null;
    }
  }
}

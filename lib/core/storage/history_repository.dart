import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/history_entry_model.dart';

class HistoryRepository {
  static const String _historyFileName = 'transfer_history.json';
  File? _historyFile;
  List<HistoryEntryModel> _cachedEntries = [];

  /// Load and parse history entries from the local JSON file database.
  Future<void> init() async {
    try {
      final directory = await getApplicationSupportDirectory();
      _historyFile = File('${directory.path}/$_historyFileName');

      if (await _historyFile!.exists()) {
        final rawJson = await _historyFile!.readAsString();
        if (rawJson.trim().isNotEmpty) {
          final List<dynamic> jsonList = json.decode(rawJson);
          _cachedEntries = jsonList
              .map((item) => HistoryEntryModel.fromJson(item as Map<String, dynamic>))
              .toList();
          
          // Sort by timestamp descending (most recent first)
          _cachedEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      }
    } catch (_) {
      _cachedEntries = [];
    }
  }

  /// Get the list of all history entries.
  List<HistoryEntryModel> getHistory() {
    return List.unmodifiable(_cachedEntries);
  }

  /// Add a new history entry and write to the local database file.
  Future<void> addEntry(HistoryEntryModel entry) async {
    _cachedEntries.insert(0, entry);
    await _saveToFile();
  }

  /// Clear all transfer history records.
  Future<void> clearHistory() async {
    _cachedEntries.clear();
    await _saveToFile();
  }

  Future<void> _saveToFile() async {
    if (_historyFile == null) return;
    
    try {
      final jsonList = _cachedEntries.map((e) => e.toJson()).toList();
      final rawJson = json.encode(jsonList);
      await _historyFile!.writeAsString(rawJson);
    } catch (_) {
      // Ignore write errors to history log
    }
  }
}

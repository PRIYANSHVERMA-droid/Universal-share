import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/history_entry_model.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/history_repository.dart';

class HistoryListNotifier extends StateNotifier<List<HistoryEntryModel>> {
  final HistoryRepository _repository;

  HistoryListNotifier(this._repository) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repository.getHistory();
  }

  Future<void> clearAll() async {
    await _repository.clearHistory();
    refresh();
  }

  Future<void> addEntry(HistoryEntryModel entry) async {
    await _repository.addEntry(entry);
    refresh();
  }
}

final historyListProvider =
    StateNotifierProvider<HistoryListNotifier, List<HistoryEntryModel>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  return HistoryListNotifier(repo);
});

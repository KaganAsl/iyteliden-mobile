import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchHistoryKey) ?? [];
    return history;
  }

  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchHistoryKey) ?? [];
    
    // Remove the query if it already exists (to avoid duplicates)
    history.remove(query);
    
    // Add the new query at the beginning
    history.insert(0, query);
    
    // Keep only the most recent searches
    if (history.length > _maxHistoryItems) {
      history.removeLast();
    }
    
    await prefs.setStringList(_searchHistoryKey, history);
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  Future<void> removeFromSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchHistoryKey) ?? [];
    history.remove(query);
    await prefs.setStringList(_searchHistoryKey, history);
  }
} 
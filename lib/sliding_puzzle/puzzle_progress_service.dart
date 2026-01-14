import 'package:shared_preferences/shared_preferences.dart';

class PuzzleProgressService {
  // Key for unlocked level, e.g., 'progress_3'
  static String _progressKey(int gridSize) => 'progress_$gridSize';

  // Key for best time, e.g., 'best_time_3_1' for grid 3, level 1
  static String _bestTimeKey(int gridSize, int level) => 'best_time_${gridSize}_$level';

  // Gets the highest unlocked level for a given difficulty.
  static Future<int> getUnlockedLevel(int gridSize) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_progressKey(gridSize)) ?? 1;
  }

  // Unlocks the next level.
  static Future<void> unlockNextLevel(int gridSize, int completedLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUnlockedLevel = await getUnlockedLevel(gridSize);
    final nextLevel = completedLevel + 1;

    if (nextLevel > currentUnlockedLevel) {
      await prefs.setInt(_progressKey(gridSize), nextLevel);
    }
  }

  // Gets the best time for a specific level.
  static Future<int?> getBestTime(int gridSize, int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestTimeKey(gridSize, level));
  }
  
  // Gets all best times for a given difficulty as a map.
  static Future<Map<int, int>> getAllBestTimes(int gridSize) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, int> bestTimes = {};
    final keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('best_time_${gridSize}_')) {
        final level = int.tryParse(key.split('_').last);
        final time = prefs.getInt(key);
        if (level != null && time != null) {
          bestTimes[level] = time;
        }
      }
    }
    return bestTimes;
  }

  // Saves a new best time if it's better than the old one.
  // Returns true if a new record was set.
  static Future<bool> saveBestTime(int gridSize, int level, int newTime) async {
    final prefs = await SharedPreferences.getInstance();
    final oldBestTime = await getBestTime(gridSize, level);

    if (oldBestTime == null || newTime < oldBestTime) {
      await prefs.setInt(_bestTimeKey(gridSize, level), newTime);
      return true; // New record!
    }
    return false; // Not a new record.
  }
}

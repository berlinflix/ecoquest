class LevelUtils {
  // Calculates the user's level based on an increasing task requirement.
  // 1 task = 50 EXP.
  // Level 1 -> 2 requires 1 task (50 EXP)
  // Level 2 -> 3 requires 2 tasks (100 EXP)
  // ... Max cap at 10 tasks (500 EXP) per level.
  static int calculateLevel(int totalExp) {
    int level = 1;
    int currentExpThreshold = 0;
    while (true) {
      int tasksRequired = level < 10 ? level : 10;
      int expRequiredForNextLevel = tasksRequired * 50;
      
      if (totalExp >= currentExpThreshold + expRequiredForNextLevel) {
        level++;
        currentExpThreshold += expRequiredForNextLevel;
      } else {
        break;
      }
    }
    return level;
  }

  // Returns a double between 0.0 and 1.0 representing progress to the next level.
  static double calculateProgress(int totalExp) {
    int level = 1;
    int currentExpThreshold = 0;
    int expRequiredForNextLevel = 0;
    
    while (true) {
      int tasksRequired = level < 10 ? level : 10;
      expRequiredForNextLevel = tasksRequired * 50;
      
      if (totalExp >= currentExpThreshold + expRequiredForNextLevel) {
        level++;
        currentExpThreshold += expRequiredForNextLevel;
      } else {
        break;
      }
    }
    
    int expInCurrentLevel = totalExp - currentExpThreshold;
    return expInCurrentLevel / expRequiredForNextLevel;
  }
}

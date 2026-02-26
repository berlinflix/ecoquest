void main() {
  var tests = [0, 49, 50, 99, 100, 150];
  for (var exp in tests) {
    print('EXP \$exp -> Level \${calculateLevel(exp)} Progress \${calculateProgress(exp)}');
  }
}

  int calculateLevel(int totalExp) {
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

  double calculateProgress(int totalExp) {
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

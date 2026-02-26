import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';

class QuestState extends ChangeNotifier {
  static final QuestState _instance = QuestState._internal();
  factory QuestState() => _instance;
  QuestState._internal();

  File? beforeImage;
  File? afterImage;
  DateTime? endTime;
  Timer? _timer;

  bool get isActive => endTime != null && DateTime.now().isBefore(endTime!);

  int get remainingSeconds {
    if (!isActive) return 0;
    return endTime!.difference(DateTime.now()).inSeconds;
  }

  void startQuest(File image, int durationMinutes) {
    beforeImage = image;
    afterImage = null; // Reset after image if restarting
    endTime = DateTime.now().add(Duration(minutes: durationMinutes));
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
      if (!isActive) {
        timer.cancel(); // Stop timer when time is up
      }
    });
    
    notifyListeners();
  }

  void setAfterImage(File image) {
    afterImage = image;
    notifyListeners();
  }

  void clearQuest() {
    beforeImage = null;
    afterImage = null;
    endTime = null;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

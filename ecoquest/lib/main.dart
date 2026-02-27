import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation strictly to portrait-up.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Hide system UI for a truly full-screen experience.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()),
  );
}

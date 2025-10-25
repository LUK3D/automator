import 'package:automator/features/emulator/emulator_provider.dart';
import 'package:automator/features/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EmulatorProvider(),
        ),
      ],
      builder: (context, child) {
        return const MaterialApp(
          home: Scaffold(
            body: HomeView(),
          ),
        );
      }
    );
  }
}

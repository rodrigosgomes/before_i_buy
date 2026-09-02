import 'package:flutter/material.dart';
import 'features/creator/creator_flow.dart';

class BeforeIBuyApp extends StatelessWidget {
  const BeforeIBuyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Before I Buy',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfffaf9f6),
      colorScheme: const ColorScheme.light(
        primary: Color(0xffa94f38),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xff4f5d65),
      ),
    ),
    home: const CreatorFlow(),
  );
}

import 'package:flutter/material.dart';
import 'package:open_chat/extensions/context_extension.dart';
import 'package:open_chat/screens/desktop/desktop_home_screen.dart';

/// The home screen entry point.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      // TODO: implement mobile layout
      return const Placeholder();
    } else {
      return const DesktopHomeScreen();
    }
  }
}

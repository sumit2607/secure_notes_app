/// Root application widget.
library;

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../presentation/pages/home_page.dart';
import 'theme.dart';

import '../presentation/widgets/security_wrapper.dart';

class SecureNotesApp extends StatelessWidget {
  const SecureNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return SecurityWrapper(child: child!);
      },
      home: const HomePage(),
    );
  }
}

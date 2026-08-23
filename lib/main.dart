import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  setupLocator();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UtangLista',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppPalette.primary),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

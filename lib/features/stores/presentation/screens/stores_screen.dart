import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/shared/main_app_bar.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: Center(child: Text("Stores")),
    );
  }
}

/*
  COMPONENT FOLDER: Common widgets that are reusable to the entire application

  Main appbar for appbar argument in the 
  Scaffold widget as a PreferredSizeWidget

  Note:
    Leading should be the official logo of the app

    Title can be the App name, or a tab's title

    Actions should have a Profile button that leads to a route for profile
    page.


  Usage:
    appbar: ScaffoldAppBar(title: string),
*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

class MainAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  State<MainAppBar> createState() => _MainAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _MainAppBarState extends State<MainAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppPalette.primaryDark,
      foregroundColor: AppPalette.surface,
      title: Text(
        "UtangLista",
        style: AppTextStyles.body1.copyWith(
          color: AppPalette.surface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

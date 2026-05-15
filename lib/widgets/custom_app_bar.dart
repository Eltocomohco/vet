import 'package:flutter/material.dart';
import '../utils/constantes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      automaticallyImplyLeading: showBackButton,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

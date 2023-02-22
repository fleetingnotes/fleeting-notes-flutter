import 'package:flutter/material.dart';

import '../utils/responsive.dart';

const double dialogElevation = 3;

class DialogPage<T> extends Page<T> {
  final Widget child;
  final Color? barrierColor;

  const DialogPage({required this.child, this.barrierColor, super.key});

  AppBar updateAppBar(AppBar bar) {
    return AppBar();
  }

  @override
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      barrierColor: barrierColor,
      context: context,
      settings: this,
      builder: (context) => DynamicDialog(child: child),
    );
  }
}

class DynamicDialog extends StatelessWidget {
  const DynamicDialog({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Scaffold(body: Dialog.fullscreen(child: child));
    }
    return Dialog(
      elevation: dialogElevation,
      clipBehavior: Clip.hardEdge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: SizedBox(
        width: mobileLimit,
        child: child,
      ),
    );
  }
}

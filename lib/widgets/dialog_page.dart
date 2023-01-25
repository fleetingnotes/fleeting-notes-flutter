import 'package:flutter/material.dart';

import '../utils/responsive.dart';

const double dialogElevation = 3;

class DialogPage<T> extends Page<T> {
  final Widget child;

  const DialogPage({required this.child, super.key});

  AppBar updateAppBar(AppBar bar) {
    return AppBar();
  }

  @override
  Route<T> createRoute(BuildContext context) => DialogRoute<T>(
        context: context,
        settings: this,
        builder: (context) {
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
        },
      );
}

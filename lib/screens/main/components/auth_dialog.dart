import 'package:flutter/material.dart';

import '../../settings/components/auth.dart';

class AuthDialog extends StatelessWidget {
  const AuthDialog({super.key, required this.context, this.width});

  final BuildContext context;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('Register / Sign In'),
        content: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: Auth(
              onLogin: (_) => Navigator.pop(context),
            ),
          ),
        ));
  }
}

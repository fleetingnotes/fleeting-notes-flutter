import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_dialog.dart';

enum AuthAction { signIn, signUp }

class Auth extends ConsumerStatefulWidget {
  const Auth({Key? key, this.onLogin}) : super(key: key);

  final Function? onLogin;
  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends ConsumerState<Auth> {
  bool isLoading = false;
  AuthAction _authAction = AuthAction.signUp;

  void onDialogContinue(String email, String password) async {
    final db = ref.read(dbProvider);
    Navigator.pop(context);
    await db.login(email, password);
  }

  void onSeePricing() {
    Uri pricingUrl = Uri.parse("https://fleetingnotes.app/pricing?ref=app");
    launchUrl(pricingUrl, mode: LaunchMode.externalApplication);
  }

  Future<void> onLoginPress(String email, String password) async {
    final db = ref.read(dbProvider);
    try {
      var user = await db.login(email, password);
      var subTier = await db.supabase.getSubscriptionTier();
      if (user != null && subTier == SubscriptionTier.freeSub) {
        await db.supabase.logout();
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return LoginDialog(
              onContinue: () => onDialogContinue(email, password),
              onSeePricing: onSeePricing,
              userId: user.id,
            );
          },
        );
      }
      widget.onLogin?.call(email);
    } on FleetingNotesException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _register(String email, String password) async {
    final db = ref.read(dbProvider);
    try {
      await db.register(email, password);
      await db.login(email, password);
      await db.setInitialNotes().catchError((e) {});
      widget.onLogin?.call(email);
    } on FleetingNotesException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void onSubmit(String email, String password) async {
    setState(() {
      isLoading = true;
    });
    if (_authAction == AuthAction.signIn) {
      await onLoginPress(email, password);
    } else if (_authAction == AuthAction.signUp) {
      await _register(email, password);
    }
    setState(() {
      isLoading = false;
    });
  }

  List<Widget> getColumnChildren() {
    final db = ref.read(dbProvider);
    if (isLoading) {
      return [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else {
      return [
        (_authAction == AuthAction.signIn)
            ? AuthFlow(
                text: "Don't have an account? ",
                linkedText: "Register",
                onTap: () {
                  setState(() {
                    _authAction = AuthAction.signUp;
                  });
                },
              )
            : AuthFlow(
                text: "Already have an account? ",
                linkedText: "Sign in",
                onTap: () {
                  setState(() {
                    _authAction = AuthAction.signIn;
                  });
                },
              ),
        EmailForm(
          action: _authAction,
          onSubmit: onSubmit,
          onResetPassword: db.supabase.resetPassword,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: getColumnChildren(),
    );
  }
}

class AuthFlow extends StatelessWidget {
  const AuthFlow({
    Key? key,
    required this.text,
    required this.linkedText,
    required this.onTap,
  }) : super(key: key);

  final String text;
  final String linkedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
      child: RichText(
        key: const Key('SignInText'),
        text: TextSpan(children: [
          TextSpan(text: text, style: Theme.of(context).textTheme.bodyMedium),
          TextSpan(
            text: linkedText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue,
                ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ]),
      ),
    );
  }
}

class EmailForm extends StatefulWidget {
  const EmailForm({
    Key? key,
    required this.action,
    required this.onSubmit,
    required this.onResetPassword,
  }) : super(key: key);

  final AuthAction action;
  final Function onSubmit;
  final Function onResetPassword;

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  String email = '';
  String password = '';
  String confirmPassword = '';
  final _formKey = GlobalKey<FormState>();

  String? validateEmailField() {
    if (email.isEmpty) {
      return 'Email is required';
    }
    // https://stackoverflow.com/a/4964766/13659833
    if (!RegExp(r"^\S+@\S+\.\S+$").hasMatch(email)) {
      return 'Invalid email';
    }
    return null;
  }

  String? validatePasswordField() {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPasswordField() {
    if (confirmPassword.isEmpty) {
      return 'Confirm password is required';
    }
    if (confirmPassword != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Enter your email',
              border: OutlineInputBorder(),
            ),
            onChanged: (String value) {
              setState(() {
                email = value;
              });
            },
            validator: (_) => validateEmailField(),
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            onChanged: (String value) {
              setState(() {
                password = value;
              });
            },
            validator: (_) => validatePasswordField(),
          ),
          (widget.action == AuthAction.signUp)
              ? Column(
                  children: [
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onChanged: (String value) {
                        setState(() {
                          confirmPassword = value;
                        });
                      },
                      validator: (_) => validateConfirmPasswordField(),
                    ),
                  ],
                )
              : const SizedBox(height: 0),
          const SizedBox(height: 20),
          OutlinedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmit(email, password);
                }
              },
              child: (widget.action == AuthAction.signUp)
                  ? const Text('Register', style: TextStyle(fontSize: 15))
                  : const Text('Sign in', style: TextStyle(fontSize: 15))),
          if (widget.action == AuthAction.signIn) const SizedBox(height: 10),
          if (widget.action == AuthAction.signIn)
            TextButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (_) {
                        return RecoverPasswordDialog(
                          email: email,
                          onResetPassword: widget.onResetPassword,
                        );
                      });
                },
                child: const Text('Trouble signing in?')),
        ],
      ),
    );
  }
}

class RecoverPasswordDialog extends StatefulWidget {
  const RecoverPasswordDialog({
    Key? key,
    required this.email,
    required this.onResetPassword,
  }) : super(key: key);

  final String email;
  final Function onResetPassword;

  @override
  State<RecoverPasswordDialog> createState() => _RecoverPasswordDialogState();
}

class _RecoverPasswordDialogState extends State<RecoverPasswordDialog> {
  String errMessage = '';
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _emailController.text = widget.email;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recover Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Get instructions sent to this email that explain how to reset your password'),
          const SizedBox(height: 30),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (_) {
                if (errMessage.isEmpty) {
                  return null;
                }
                return errMessage;
              },
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Send'),
          onPressed: () async {
            try {
              await widget.onResetPassword(_emailController.text);
              Navigator.of(context).pop();
            } on FleetingNotesException catch (e) {
              setState(() {
                errMessage = e.message;
              });
              _formKey.currentState!.validate();
            }
          },
        )
      ],
    );
  }
}

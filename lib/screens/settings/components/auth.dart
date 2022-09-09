import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../database.dart';
import 'login_dialog.dart';

enum AuthAction { signIn, signUp }

class Auth extends StatefulWidget {
  const Auth({Key? key, required this.db, this.onLogin}) : super(key: key);

  final Database db;
  final Function? onLogin;
  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  bool isLoading = false;
  AuthAction _authAction = AuthAction.signUp;

  void onDialogContinue(String email, String password) async {
    Navigator.pop(context);
    await widget.db.login(email, password);
    widget.db.firebase.analytics.logEvent(name: 'login_dialog_continue');
  }

  void onSeePricing() {
    String pricingUrl = "https://fleetingnotes.app/pricing?ref=app";
    launch(pricingUrl);
    widget.db.firebase.analytics.logEvent(name: 'login_dialog_see_pricing');
  }

  Future<void> onLoginPress(String email, String password) async {
    bool isLoggedIn = await _login(email, password);
    if (isLoggedIn && !await widget.db.firebase.isCurrUserPaying()) {
      await widget.db.firebase.logoutAllSessions();
      try {
        // refresh user token to tell client to logout
        await widget.db.firebase.currUser?.getIdToken(true);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'user-token-expired') {
          rethrow;
        }
      }
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoginDialog(
            onContinue: () => onDialogContinue(email, password),
            onSeePricing: onSeePricing,
          );
        },
      );
    }
    if (isLoggedIn) {
      if (widget.onLogin != null) widget.onLogin!(email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Login failed'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<bool> _login(String email, String password) async {
    bool isLoggedIn = await widget.db.login(email, password);
    return isLoggedIn;
  }

  Future<void> _register(String email, String password) async {
    bool isRegistered = await widget.db.register(email, password);
    if (isRegistered) {
      bool isLoggedIn = await _login(email, password);
      if (isLoggedIn) {
        await widget.db.firebase.setInitialNotes().catchError((e) {});
        widget.onLogin?.call(email);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registration failed'),
        duration: Duration(seconds: 2),
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
          onResetPassword: widget.db.firebase.auth.sendPasswordResetEmail,
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
        text: TextSpan(children: [
          TextSpan(text: text, style: Theme.of(context).textTheme.bodyText1!),
          TextSpan(
            text: linkedText,
            style: Theme.of(context).textTheme.bodyText1!.copyWith(
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
    if (!RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email)) {
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
              await widget.onResetPassword(email: _emailController.text);
              Navigator.of(context).pop();
            } on FirebaseAuthException catch (e) {
              setState(() {
                if (e.code == 'user-not-found') {
                  errMessage =
                      "The email address doesn't match an existing account";
                } else if (e.code == 'invalid-email') {
                  errMessage = "The email address isn't correct";
                } else {
                  errMessage = 'Password reset failed';
                }
              });
              _formKey.currentState!.validate();
            }
          },
        )
      ],
    );
  }
}

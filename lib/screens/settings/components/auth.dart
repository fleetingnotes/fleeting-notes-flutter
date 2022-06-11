import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../database.dart';
import 'login_dialog.dart';
import 'package:flutterfire_ui/auth.dart';

class Auth extends StatefulWidget {
  const Auth({Key? key, required this.db, this.onLogin}) : super(key: key);

  final Database db;
  final Function? onLogin;
  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  bool isLoading = false;
  AuthAction _authAction = AuthAction.signIn;

  void onDialogContinue(String email, String password) async {
    Navigator.pop(context);
    await widget.db.firebase.logoutAllSessions();
    widget.db.login(email, password);
    widget.db.firebase.analytics.logEvent(name: 'login_dialog_continue');
  }

  void onSeePricing() {
    String pricingUrl = "https://fleetingnotes.app/pricing?ref=app";
    launch(pricingUrl);
    widget.db.firebase.analytics.logEvent(name: 'login_dialog_see_pricing');
  }

  Future<void> onLoginPress(String email, String password) async {
    bool isLoggedIn = await _login(email, password);
    if (isLoggedIn && !await widget.db.firebase.isCurrUserPremium()) {
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
      if (isLoggedIn && widget.onLogin != null) widget.onLogin!(email);
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

  @override
  Widget build(BuildContext context) {
    return (isLoading)
        ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              ),
            ],
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
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 10),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(text: text),
            TextSpan(
              text: linkedText,
              style: const TextStyle(color: Colors.blue),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ]),
        ));
  }
}

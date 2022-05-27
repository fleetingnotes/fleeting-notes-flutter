import 'package:flutter/material.dart';
import '../../../database.dart';

class Auth extends StatefulWidget {
  const Auth({Key? key, required this.db, this.onLogin}) : super(key: key);

  final Database db;
  final Function? onLogin;
  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  String email = '';
  String password = '';
  bool isLoading = false;

  bool validEmail() {
    return email.isNotEmpty;
  }

  bool validPassword() {
    return password.isNotEmpty;
  }

  Future<void> onLoginPress() async {
    setState(() {
      isLoading = true;
    });
    bool isLoggedIn = await _login();
    if (isLoggedIn && !await widget.db.firebase.isCurrUserPremium()) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout of all other sessions'),
            content: const Text(
                'As a free user, you can only log in with one account at a time.'),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.db.firebase.logoutAllSessions();
                    widget.db.firebase.reauthenticateCurrUser(email, password);
                  },
                  child: const Text('Continue'))
            ],
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
    setState(() {
      isLoading = false;
    });
  }

  Future<bool> _login() async {
    if (!validPassword() || !validEmail()) {
      return false;
    }
    bool isLoggedIn = await widget.db.login(email, password);
    return isLoggedIn;
  }

  Future<void> _register() async {
    if (!validPassword() || !validEmail()) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    bool isRegistered = await widget.db.register(email, password);
    if (isRegistered) {
      _login();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registration failed'),
        duration: Duration(seconds: 2),
      ));
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Email',
            ),
            keyboardType: TextInputType.emailAddress,
            enableSuggestions: false,
            autocorrect: false,
            onChanged: (String val) {
              setState(() {
                email = val;
              });
            },
          ),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Password',
            ),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            onChanged: (String val) {
              setState(() {
                password = val;
              });
            },
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    child: const Text('Login'),
                    onPressed: (isLoading) ? null : onLoginPress),
                ElevatedButton(
                  child: const Text('Register'),
                  onPressed: (isLoading) ? null : _register,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

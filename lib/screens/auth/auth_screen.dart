import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';

import '../../realm_db.dart';
import '../main/main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final RealmApp app = RealmApp();
  String email = '';
  String password = '';

  bool validEmail() {
    return email.isNotEmpty;
  }

  bool validPassword() {
    return password.isNotEmpty;
  }

  Future<void> _login(BuildContext context) async {
    if (!validPassword() || !validEmail()) {
      return;
    }
    var user = await app.login(Credentials.emailPassword(email, password));
    RealmDB db = RealmDB(app: app);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage(db: db)),
    );
  }

  Future<void> _register(BuildContext context) async {
    if (!validPassword() || !validEmail()) {
      return;
    }
    await app.registerUser(email, password);
    _login(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Email',
              ),
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
                      onPressed: () => _login(context)),
                  ElevatedButton(
                    child: const Text('Register'),
                    onPressed: () => _register(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

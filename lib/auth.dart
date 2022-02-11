import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';

import 'realm_db.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    // TODO: Add check for user to ensure its valid
    MongoRealmClient client = MongoRealmClient();
    MongoCollection collection =
        client.getDatabase("todo").getCollection("Note");
    RealmDB db = RealmDB(collection: collection);
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
              margin: EdgeInsets.only(top: 20),
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
              )),
        ],
      )),
    );
  }
}

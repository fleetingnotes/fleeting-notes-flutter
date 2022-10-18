// TODO: remove this file once we want to get rid of migration
import 'package:firedart/auth/user_gateway.dart';
import 'package:firedart/firedart.dart';

class FireDart {
  String apiKey = 'AIzaSyAXzFkFSgQo0PYcIDJZg2gJBaxy1cqy1oc';
  String projectId = 'fleetingnotes-22f77';
  late FirebaseAuth auth;
  FireDart() {
    FirebaseAuth.initialize(apiKey, VolatileStore());
    auth = FirebaseAuth.instance;
  }

  Future<User> login(String email, String password) async {
    return await auth.signIn(email, password);
  }

  Future<User> register(String email, String password) async {
    return await auth.signUp(email, password);
  }
}

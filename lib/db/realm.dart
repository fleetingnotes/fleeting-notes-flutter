import 'dart:io';
import 'package:fleeting_notes_flutter/db/db_interface.dart';

import '../models/Note.dart';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
// ignore: library_prefixes
import 'package:path/path.dart' as Path;

class RealmDB implements DatabaseInterface {
  @override
  String userId = 'local';
  String? _accessToken;
  String? _refreshToken;
  DateTime _expirationDate = DateTime.now();
  String apiUrl =
      'https://realm.mongodb.com/api/client/v2.0/app/fleeting-notes-knojs/';

  @override
  bool isLoggedIn() {
    return userId != 'local';
  }

  Future<dynamic> graphQLRequest(query) async {
    if (DateTime.now().isAfter(_expirationDate)) {
      if (!await refreshToken()) return null;
    }
    try {
      var url = Path.join(apiUrl, 'graphql');
      Response res = await Dio().post(
        url,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
          "Authorization": "Bearer $_accessToken",
        }),
        data: {
          "query": query,
        },
      );
      return jsonDecode(res.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Note>> getAllNotes() async {
    var query =
        'query {  notes(query: {_isDeleted_ne: true}, sortBy: TIMESTAMP_DESC) {_id  title  content  source  timestamp}}';
    try {
      var res = await graphQLRequest(query);
      var noteMapList = res['data']['notes'];
      List<Note> notes = [for (var note in noteMapList) fromMap(note)];
      return notes;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> insertNote(Note note) async {
    try {
      Note encodedNote = encodeNote(note);
      var query =
          'mutation { insertOneNote(data: {_id: ${encodedNote.id}, _partition: ${jsonEncode(userId)},title: ${encodedNote.title}, content: ${encodedNote.content}, source: ${encodedNote.source}, timestamp: ${encodedNote.timestamp}, _isDeleted: ${encodedNote.isDeleted}}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      if (res['data'] == null) return false;
      note = fromMap(res["data"]["insertOneNote"]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateNote(Note note) async {
    try {
      Note encodedNote = encodeNote(note);
      var query =
          'mutation { updateOneNote(query: {_id: ${encodedNote.id}}, set: {title: ${encodedNote.title}, content: ${encodedNote.content}, source: ${encodedNote.source}}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      if (res['data'] == null) return false;
      note = fromMap(res["data"]["updateOneNote"]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateNotes(List<Note> notes) async {
    try {
      List queryList = notes.map((note) {
        Note encodedNote = encodeNote(note);
        String noteQuery =
            '{_id: ${encodedNote.id}, _partition: ${jsonEncode(userId)},title: ${encodedNote.title}, content: ${encodedNote.content}, source: ${encodedNote.source}, timestamp: ${encodedNote.timestamp}, _isDeleted: ${encodedNote.isDeleted}}';
        return noteQuery;
      }).toList();
      String query =
          'mutation { insertManyNotes(data: ${queryList.toString()}) { insertedIds } }';
      var res = await graphQLRequest(query);
      if (res['data'] == null) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteNote(Note note) async {
    try {
      Note encodedNote = encodeNote(note);
      var query =
          'mutation { updateOneNote(query: {_id: ${encodedNote.id}}, set: {_isDeleted: true}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      if (res['data'] == null) return false;
      note = fromMap(res["data"]["updateOneNote"]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> register(String email, String password) async {
    var url = Path.join(apiUrl, 'auth/providers/local-userpass/register');
    try {
      await Dio().post(
        url,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
        }),
        data: jsonEncode({
          "email": email,
          "password": password,
        }),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> logout() async {
    userId = 'local';
    _accessToken = null;
    return true;
  }

  Future<bool> refreshToken() async {
    try {
      var url =
          Path.join('https://realm.mongodb.com/api/client/v2.0/auth/session');
      var res = await Dio().post(
        url,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
          "Authorization": "Bearer $_refreshToken",
        }),
      );
      _accessToken = res.data['access_token'];
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      var authUrl = Path.join(apiUrl, 'auth/providers/local-userpass/login');
      var res = await Dio().post(
        authUrl,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
        }),
        data: jsonEncode({
          "username": email,
          "password": password,
        }),
      );
      _accessToken = res.data['access_token'];
      userId = res.data['user_id'];
      _refreshToken = res.data['refresh_token'];
      DateTime currentTime = DateTime.now();
      _expirationDate = currentTime.add(const Duration(minutes: 30));
      return true;
    } catch (e) {
      return false;
    }
  }

  Note fromMap(dynamic note) {
    Map noteMap = Map.from(note);
    return Note(
      id: noteMap["_id"].toString(),
      title: noteMap["title"].toString(),
      content: noteMap["content"].toString(),
      source: noteMap["source"].toString(),
      timestamp: noteMap["timestamp"].toString(),
    );
  }

  Note encodeNote(Note note) {
    return Note(
      id: jsonEncode(note.id),
      title: jsonEncode(note.title),
      content: jsonEncode(note.content),
      source: jsonEncode(note.source),
      timestamp: jsonEncode(note.timestamp),
      isDeleted: note.isDeleted,
      hasAttachment: note.hasAttachment,
    );
  }
}

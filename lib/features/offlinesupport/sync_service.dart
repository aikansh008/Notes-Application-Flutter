import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'notes_db.dart';

class SyncService {
  static Future<void> syncPendingNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final pending = await NotesDB.instance.fetchPendingNotes();
    for (final note in pending) {
      try {
        if (note['action'] == 'create') {
          final resp = await http.post(
            Uri.parse(
              'https://notes-application-backend-3gsg.onrender.com/notes',
            ),
            headers: headers,
            body: jsonEncode({
              'title': note['title'],
              'description': note['description'],
            }),
          );
          if (resp.statusCode == 201) {
            final data = jsonDecode(resp.body);
            await NotesDB.instance.upsertNote({
              'id': data['id'],
              'title': data['title'],
              'description': data['description'],
              'isSynced': 1,
            });
            await NotesDB.instance.deletePendingNote(note['id']);
          }
        } else if (note['action'] == 'update') {
          final resp = await http.put(
            Uri.parse(
              'https://notes-application-backend-3gsg.onrender.com/notes/${note['noteId']}',
            ),
            headers: headers,
            body: jsonEncode({
              'title': note['title'],
              'description': note['description'],
            }),
          );
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            await NotesDB.instance.upsertNote({
              'id': data['id'],
              'title': data['title'],
              'description': data['description'],
              'isSynced': 1,
            });
            await NotesDB.instance.deletePendingNote(note['id']);
          }
        } else if (note['action'] == 'delete') {
          final resp = await http.delete(
            Uri.parse(
              'https://notes-application-backend-3gsg.onrender.com/notes/${note['noteId']}',
            ),
            headers: headers,
          );
          if (resp.statusCode == 200 || resp.statusCode == 204) {
            await NotesDB.instance.deleteNoteLocal(note['noteId']);
            await NotesDB.instance.deletePendingNote(note['id']);
          }
        }
      } catch (_) {
        // Keep pending if network error
      }
    }
  }

  static void startMonitoring() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPendingNotes();
      }
    });
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notetaking_app/core/theme/app_colors.dart';
import 'package:notetaking_app/features/offlinesupport/notes_db.dart';
import 'package:notetaking_app/features/offlinesupport/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UpdateNoteScreen extends StatefulWidget {
  final String noteId;
  final String initialTitle;
  final String initialBody;

  const UpdateNoteScreen({
    super.key,
    required this.noteId,
    required this.initialTitle,
    required this.initialBody,
  });

  @override
  State<UpdateNoteScreen> createState() => _UpdateNoteScreenState();
}

class _UpdateNoteScreenState extends State<UpdateNoteScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _body = TextEditingController(text: widget.initialBody);

    // Start monitoring connectivity for pending notes
    SyncService.startMonitoring();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  InputDecoration _filledInput(String hint, ColorScheme scheme) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textcolor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _updateNote() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final connectivity = await Connectivity().checkConnectivity();

      if (connectivity == ConnectivityResult.none) {
        await NotesDB.instance.addPendingNote(
          _title.text.trim(),
          _body.text.trim(),
          action: "update",
          noteId: widget.noteId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: Update saved locally.')),
        );
        if (mounted) Navigator.of(context).maybePop(true);
        return;
      }

      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse(
        'https://notes-application-backend-3gsg.onrender.com/notes/${widget.noteId}',
      );

      final resp = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({
          'title': _title.text.trim(),
          'description': _body.text.trim(),
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
        if (mounted) Navigator.of(context).maybePop(true);
      } else {
        await NotesDB.instance.addPendingNote(
          _title.text.trim(),
          _body.text.trim(),
          action: "update",
          noteId: widget.noteId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server rejected update, saved offline: ${resp.statusCode}',
            ),
          ),
        );
        if (mounted) Navigator.of(context).maybePop(true);
      }
    } catch (_) {
      await NotesDB.instance.addPendingNote(
        _title.text.trim(),
        _body.text.trim(),
        action: "update",
        noteId: widget.noteId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error, saved offline')),
      );
      if (mounted) Navigator.of(context).maybePop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteNote() async {
    setState(() => _submitting = true);
    try {
      final connectivity = await Connectivity().checkConnectivity();

      if (connectivity == ConnectivityResult.none) {
        await NotesDB.instance.addPendingNote(
          widget.initialTitle,
          widget.initialBody,
          action: "delete",
          noteId: widget.noteId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: Delete saved locally.')),
        );
        if (mounted) Navigator.of(context).maybePop(true);
        return;
      }

      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse(
        'https://notes-application-backend-3gsg.onrender.com/notes/${widget.noteId}',
      );

      final resp = await http.delete(uri, headers: headers);

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await NotesDB.instance.deleteNoteLocal(widget.noteId);
        if (mounted) Navigator.of(context).maybePop(true);
      } else {
        await NotesDB.instance.addPendingNote(
          widget.initialTitle,
          widget.initialBody,
          action: "delete",
          noteId: widget.noteId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server rejected delete, saved offline: ${resp.statusCode}',
            ),
          ),
        );
        if (mounted) Navigator.of(context).maybePop(true);
      }
    } catch (_) {
      await NotesDB.instance.addPendingNote(
        widget.initialTitle,
        widget.initialBody,
        action: "delete",
        noteId: widget.noteId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error, saved offline')),
      );
      if (mounted) Navigator.of(context).maybePop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Update Note'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _title,
                      decoration: _filledInput('Title', scheme),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _body,
                      minLines: 8,
                      maxLines: null,
                      decoration: _filledInput('Description', scheme),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: Color(0xFFE8F2ED), // changed to black
                        foregroundColor:
                            Colors.black, // text color white for contrast
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _submitting ? null : _deleteNote,
                      child: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF38E078),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _submitting ? null : _updateNote,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update'),
                    ),
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

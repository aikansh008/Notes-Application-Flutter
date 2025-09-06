import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notetaking_app/core/theme/app_colors.dart';
import 'package:notetaking_app/features/offlinesupport/notes_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NewNoteScreen extends StatefulWidget {
  const NewNoteScreen({super.key});

  @override
  State<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  // Do NOT set filled/fillColor here; inherit from theme.
  InputDecoration _filledInput(String hint, ColorScheme scheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textcolor),
      // filled/fillColor are provided by theme
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // shape unchanged
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      // Check internet before API call
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        await NotesDB.instance.addPendingNote(
          _title.text.trim(),
          _body.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved offline. Will sync later.')),
        );
        if (mounted) Navigator.of(context).maybePop(true);
        return;
      }

      // 1) Read JWT from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // 2) Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // 3) POST request
      final uri = Uri.parse(
        'https://notes-application-backend-3gsg.onrender.com/notes',
      );
      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'title': _title.text.trim(),
          'description': _body.text.trim(),
        }),
      );

      if (resp.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).maybePop(true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Note created')));
        }
      } else {
        // Save offline if server rejected
        await NotesDB.instance.addPendingNote(
          _title.text.trim(),
          _body.text.trim(),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved offline: ${resp.body}')));
        if (mounted) Navigator.of(context).maybePop(true);
      }
    } catch (e) {
      await NotesDB.instance.addPendingNote(
        _title.text.trim(),
        _body.text.trim(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved offline (error): $e')));
      if (mounted) Navigator.of(context).maybePop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const Text(
                      'New Note',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Form
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _title,
                      decoration: _filledInput('Title', scheme),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _body,
                      minLines: 8,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: _filledInput(
                        'Write your note here...',
                        scheme,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                children: [
                  SizedBox(
                    height: 40,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.bgcolor,
                        foregroundColor: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // unchanged
                        ),
                      ),
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: const Text('Discard'),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF38E078),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // unchanged
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _submitting ? null : _saveNote,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
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

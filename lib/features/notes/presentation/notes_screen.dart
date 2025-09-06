import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notetaking_app/features/notes/presentation/notesupdate_screen.dart';
import 'package:notetaking_app/features/offlinesupport/image_db.dart';
import 'package:notetaking_app/features/offlinesupport/notes_db.dart';
import 'package:notetaking_app/features/profile/presentation/profile_screen.dart';
import 'package:notetaking_app/core/theme/app_colors.dart';
import 'package:notetaking_app/features/notes/presentation/notes_add.dart';
import 'package:notetaking_app/features/setting/presentation/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();
  List<dynamic> _notes = [];
  List<dynamic> _filteredNotes = [];
  bool _loading = true;
  File? _profileAvatar;

  @override
  void initState() {
    super.initState();
    _loadProfileAvatar();
    _fetchNotes();

    // Listen for search changes
    _search.addListener(() {
      _filterNotes(_search.text);
    });
  }

  Future<void> _loadProfileAvatar() async {
    final path = await ProfileDB.instance.getImagePath();
    if (path != null && mounted) {
      setState(() {
        _profileAvatar = File(path);
      });
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Fetch notes from API and sync local DB
  Future<void> _fetchNotes() async {
    final localNotes = await NotesDB.instance.fetchNotes();
    setState(() {
      _notes = localNotes;
      _filteredNotes = localNotes;
      _loading = false;
    });

    try {
      final token = await getToken();
      final resp = await http.get(
        Uri.parse('https://notes-application-backend-3gsg.onrender.com/notes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        for (final n in data) {
          await NotesDB.instance.upsertNote({
            'id': n['id'],
            'title': n['title'],
            'description': n['description'],
            'isSynced': 1,
          });
        }
        final updated = await NotesDB.instance.fetchNotes();
        setState(() {
          _notes = updated;
          _filteredNotes = updated;
        });
      }
    } catch (_) {}
  }

  void _filterNotes(String query) {
    final filtered = _notes.where((note) {
      final title = note["title"]?.toString().toLowerCase() ?? '';
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredNotes = filtered;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  InputDecoration _searchDecoration(ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: 'Search notes',
      hintStyle: TextStyle(color: AppColors.textcolor),
      prefixIcon: Icon(Icons.search, color: AppColors.textcolor),
      filled: true,
      fillColor: isDark ? const Color(0xFF264533) : const Color(0xFFE8F2ED),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _roundedDocIcon(ColorScheme scheme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: NoteSquareTile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SafeArea(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ).then((_) => _loadProfileAvatar());
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.primary.withOpacity(0.25),
                    backgroundImage: _profileAvatar != null
                        ? FileImage(_profileAvatar!)
                        : null,
                    child: _profileAvatar == null
                        ? const Text(
                            'S',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ).then((_) => _loadProfileAvatar());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: _searchDecoration(scheme),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredNotes.isEmpty
                    ? const Center(child: Text("No notes found"))
                    : ListView.builder(
                        itemCount: _filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = _filteredNotes[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UpdateNoteScreen(
                                    noteId: note["id"] ?? "",
                                    initialTitle: note["title"] ?? "Untitled",
                                    initialBody: note["description"] ?? "",
                                  ),
                                ),
                              ).then((_) => _fetchNotes());
                            },
                            child: _NoteTile(
                              leading: _roundedDocIcon(scheme),
                              title: note["title"] ?? "Untitled",
                              subtitle: note["description"] ?? "",
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 56,
        width: 56,
        child: FloatingActionButton(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewNoteScreen()),
            ).then((_) => _fetchNotes());
          },
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;

  const _NoteTile({
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF52946B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoteSquareTile extends StatelessWidget {
  const NoteSquareTile({
    super.key,
    this.size = 56, // tile side length
    this.bgColor = const Color(0xFF0E2C22), // dark green background
    this.iconColor = Colors.white, // used if using Icon
  });

  final double size;
  final Color bgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Color(0xFFE8F2ED) // light background
            : Color(0xFF264533), // dark background
        borderRadius: BorderRadius.circular(14), // rounded square
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8.0), // breathing room from edges
        child: Image.asset(
          'assets/file.png', // <- replace with your asset path
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

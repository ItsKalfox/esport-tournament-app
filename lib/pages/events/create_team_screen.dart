import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../models/team_model.dart';
import '../../services/tournament_service.dart';
import '../../services/image_upload_service.dart';

const List<String> _kEmojis = [
  '🎮', '⚔️', '🔥', '🏆', '👾', '💀', '🐉', '🦅', '⚡', '🌪️',
  '🎯', '🛡️', '🚀', '🐺', '🦁', '💎', '🔱', '☠️', '🦊', '🐯',
];

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen>
    with SingleTickerProviderStateMixin {
  final _service = TournamentService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  late final TabController _logoTabCtrl;

  String _selectedEmoji = '🎮';
  File? _logoFile;
  int _maxMembers = 4;
  final List<String> _pendingEmails = [];
  bool _loading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _logoTabCtrl = TabController(length: 2, vsync: this);
    _logoTabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _logoTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImageUploadService.showPickerSheet(
      context: context,
      cropStyle: CropStyle.circle,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxBytes: kMaxLogoSizeBytes,
      toolbarTitle: 'Crop Team Logo',
    );
    if (file != null) setState(() => _logoFile = file);
  }

  void _addEmail() {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) return;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _snack('Enter a valid email'); return;
    }
    if (_pendingEmails.contains(email)) { _snack('Already added'); return; }
    final max = _maxMembers - 1; // captain already counts
    if (_pendingEmails.length >= max) {
      _snack('Max $max teammates for a $_maxMembers-player team'); return;
    }
    final me = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email == me) { _snack("Can't invite yourself"); return; }
    setState(() { _pendingEmails.add(email); _emailCtrl.clear(); });
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) { _snack('Enter a team name'); return; }
    if (_logoTabCtrl.index == 1 && _logoFile == null) {
      _snack('Pick a logo image or switch to emoji'); return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final captain = TeamMember(
        uid: user.uid,
        displayName: user.displayName ?? 'Captain',
        email: user.email ?? '',
      );
      final team = TeamModel(
        id: '',
        tournamentId: '',
        name: _nameCtrl.text.trim(),
        logoEmoji: _selectedEmoji,
        captainUid: user.uid,
        captainName: user.displayName ?? 'Captain',
        members: [captain],
        pendingEmails: _pendingEmails,
        advancedToFinals: false,
        maxMembers: _maxMembers,
        createdAt: DateTime.now(),
      );
      final teamId = await _service.createGlobalTeam(team);

      // Upload logo image if chosen
      if (_logoTabCtrl.index == 1 && _logoFile != null) {
        setState(() => _uploadProgress = 0.01);
        final url = await ImageUploadService.uploadImage(
          file: _logoFile!,
          storagePath: 'team_logos/global_${teamId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
        );
        await _service.updateGlobalTeamLogoUrl(teamId, url);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Team created! 🎮'),
          backgroundColor: Color(0xFF2A8C00),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      _snack('Error: $e');
      setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF333333),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                const Expanded(child: Text('Create Team', style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
              ]),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Team Size ────────────────────────────────────────────
                    const _Label('Team Size'),
                    const SizedBox(height: 4),
                    const Text('How many players per team? (including yourself)',
                        style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
                    const SizedBox(height: 10),
                    _MemberCountPicker(
                      value: _maxMembers,
                      onChanged: (v) => setState(() {
                        _maxMembers = v;
                        // Trim excess pending emails
                        while (_pendingEmails.length >= v) {
                          _pendingEmails.removeLast();
                        }
                      }),
                    ),
                    const SizedBox(height: 20),

                    // ── Team Name ────────────────────────────────────────────
                    const _Label('Team Name *'),
                    _DarkInput(
                      controller: _nameCtrl,
                      hint: 'e.g. Shadow Wolves',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // ── Logo ─────────────────────────────────────────────────
                    const _Label('Team Logo'),
                    const SizedBox(height: 4),
                    const Text('Emoji icon or custom image (max 2 MB)',
                        style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
                    const SizedBox(height: 10),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _logoTabCtrl,
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFC8860A), Color(0xFFF0A500)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.black,
                        unselectedLabelColor: const Color(0xFF777777),
                        labelStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        tabs: const [Tab(text: '😀 Emoji'), Tab(text: '🖼️ Image')],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_logoTabCtrl.index == 0)
                      _EmojiGrid(
                          selected: _selectedEmoji,
                          onSelect: (e) => setState(() => _selectedEmoji = e))
                    else
                      _LogoImagePicker(file: _logoFile, onPick: _pickLogo),
                    const SizedBox(height: 20),

                    // ── Preview ──────────────────────────────────────────────
                    _TeamPreviewCard(
                      name: _nameCtrl.text.trim().isEmpty ? 'Your Team' : _nameCtrl.text.trim(),
                      emoji: _selectedEmoji,
                      logoFile: _logoTabCtrl.index == 1 ? _logoFile : null,
                      maxMembers: _maxMembers,
                    ),
                    const SizedBox(height: 24),

                    // ── Invite Members ───────────────────────────────────────
                    _Label('Invite Members (up to ${_maxMembers - 1})'),
                    const SizedBox(height: 4),
                    const Text("Enter emails. They'll get an in-app invite.",
                        style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
                    const SizedBox(height: 10),

                    Row(children: [
                      Expanded(child: _DarkInput(
                        controller: _emailCtrl,
                        hint: 'member@email.com',
                        keyboardType: TextInputType.emailAddress,
                      )),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _addEmail,
                        child: Container(
                          height: 46, width: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFC8860A), Color(0xFFF0A500)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.black, size: 22),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    ..._pendingEmails.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF2A2200)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.email_outlined, color: Color(0xFFF0A500), size: 16),
                              const SizedBox(width: 10),
                              Expanded(child: Text(e.value,
                                  style: const TextStyle(color: Colors.white, fontSize: 13))),
                              GestureDetector(
                                onTap: () => setState(() => _pendingEmails.removeAt(e.key)),
                                child: const Icon(Icons.close, color: Color(0xFF555555), size: 16),
                              ),
                            ]),
                          ),
                        )),

                    const SizedBox(height: 8),
                    Text(
                      '${1 + _pendingEmails.length}/$_maxMembers players',
                      style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Create Button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _loading
                  ? _UploadProgress(progress: _uploadProgress)
                  : GestureDetector(
                      onTap: _create,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFC8860A), Color(0xFFF0A500)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFFF0A500).withOpacity(0.3),
                            blurRadius: 16, offset: const Offset(0, 4),
                          )],
                        ),
                        child: const Center(child: Text('Create Team',
                          style: TextStyle(color: Colors.black,
                              fontWeight: FontWeight.w800, fontSize: 16))),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Member Count Picker ──────────────────────────────────────────────────────

class _MemberCountPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _MemberCountPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(9, (i) {
          final n = i + 2; // 2 to 10
          final selected = n == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF2A1800) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFFF0A500) : const Color(0xFF2A2A2A),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected ? [BoxShadow(
                    color: const Color(0xFFF0A500).withOpacity(0.3),
                    blurRadius: 8,
                  )] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$n',
                      style: TextStyle(
                        color: selected ? const Color(0xFFF0A500) : Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('vs', style: TextStyle(
                      color: selected ? const Color(0xFFC8860A) : const Color(0xFF555555),
                      fontSize: 9,
                    )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Emoji Grid ───────────────────────────────────────────────────────────────

class _EmojiGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _EmojiGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: _kEmojis.map((emoji) {
        final sel = emoji == selected;
        return GestureDetector(
          onTap: () => onSelect(emoji),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF2A1800) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? const Color(0xFFF0A500) : const Color(0xFF2A2A2A),
                width: sel ? 2 : 1,
              ),
              boxShadow: sel ? [BoxShadow(
                color: const Color(0xFFF0A500).withOpacity(0.3), blurRadius: 8,
              )] : null,
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Image Logo Picker ────────────────────────────────────────────────────────

class _LogoImagePicker extends StatelessWidget {
  final File? file;
  final VoidCallback onPick;
  const _LogoImagePicker({required this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1A),
            border: Border.all(
              color: file != null ? const Color(0xFFF0A500) : const Color(0xFF2A2A2A),
              width: file != null ? 2.5 : 1.5,
            ),
            image: file != null
                ? DecorationImage(image: FileImage(file!), fit: BoxFit.cover)
                : null,
            boxShadow: file != null ? [BoxShadow(
              color: const Color(0xFFF0A500).withOpacity(0.3), blurRadius: 16,
            )] : null,
          ),
          child: file == null
              ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: Color(0xFF555555), size: 28),
                  SizedBox(height: 4),
                  Text('Upload', style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
                ])
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 6),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(55)),
                    ),
                    child: const Text('Change', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Team Preview Card ────────────────────────────────────────────────────────

class _TeamPreviewCard extends StatelessWidget {
  final String name;
  final String emoji;
  final File? logoFile;
  final int maxMembers;
  const _TeamPreviewCard({required this.name, required this.emoji,
      this.logoFile, required this.maxMembers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1000), Color(0xFF141414)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2200)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFF2A2200)),
            image: logoFile != null
                ? DecorationImage(image: FileImage(logoFile!), fit: BoxFit.cover)
                : null,
          ),
          child: logoFile == null
              ? Center(child: Text(emoji, style: const TextStyle(fontSize: 28)))
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$maxMembers players · Preview',
                style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1800),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A2A00)),
          ),
          child: Text('$maxMembers',
              style: const TextStyle(color: Color(0xFFF0A500),
                  fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

// ─── Upload Progress ──────────────────────────────────────────────────────────

class _UploadProgress extends StatelessWidget {
  final double progress;
  const _UploadProgress({required this.progress});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    const SizedBox(height: 24, width: 24,
        child: CircularProgressIndicator(color: Color(0xFFF0A500), strokeWidth: 2.5)),
    if (progress > 0) ...[
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: progress,
          backgroundColor: const Color(0xFF222222),
          valueColor: const AlwaysStoppedAnimation(Color(0xFFF0A500)))),
      const SizedBox(height: 4),
      Text('Uploading… ${(progress * 100).toInt()}%',
          style: const TextStyle(color: Color(0xFF777777), fontSize: 10)),
    ],
  ]);
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(
            color: Color(0xFFC8860A), fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  const _DarkInput({required this.controller, required this.hint,
      this.keyboardType = TextInputType.text, this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2A2A))),
        child: TextField(
          controller: controller, keyboardType: keyboardType, onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        ),
      );
}

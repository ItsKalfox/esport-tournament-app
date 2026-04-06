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

class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _service = TournamentService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TeamModel?>(
      stream: _service.getGlobalTeamStream(widget.teamId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFF0A500))),
          );
        }
        final team = snap.data;
        if (team == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(child: Text('Team not found',
                style: TextStyle(color: Color(0xFF555555)))),
          );
        }
        final isCaptain = team.captainUid == _uid;
        return _TeamDetailView(team: team, isCaptain: isCaptain, service: _service);
      },
    );
  }
}

// ─── Main View (separated to rebuild on stream) ───────────────────────────────

class _TeamDetailView extends StatefulWidget {
  final TeamModel team;
  final bool isCaptain;
  final TournamentService service;
  const _TeamDetailView({required this.team, required this.isCaptain, required this.service});

  @override
  State<_TeamDetailView> createState() => _TeamDetailViewState();
}

class _TeamDetailViewState extends State<_TeamDetailView> {
  bool _editing = false;
  late final TextEditingController _nameCtrl;
  String _editEmoji = '🎮';
  File? _newLogoFile;
  double _uploadProgress = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team.name);
    _editEmoji = widget.team.logoEmoji;
  }

  @override
  void didUpdateWidget(_TeamDetailView old) {
    super.didUpdateWidget(old);
    if (!_editing) {
      _nameCtrl.text = widget.team.name;
      _editEmoji = widget.team.logoEmoji;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _pickLogo() async {
    final file = await ImageUploadService.showPickerSheet(
      context: context,
      cropStyle: CropStyle.circle,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxBytes: kMaxLogoSizeBytes,
      toolbarTitle: 'Crop Team Logo',
    );
    if (file != null) setState(() => _newLogoFile = file);
  }

  Future<void> _saveEdits() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Team name cannot be empty'); return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.updateGlobalTeamInfo(
          widget.team.id, _nameCtrl.text.trim(), _editEmoji);
      if (_newLogoFile != null) {
        setState(() => _uploadProgress = 0.01);
        final url = await ImageUploadService.uploadImage(
          file: _newLogoFile!,
          storagePath: 'team_logos/global_${widget.team.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
        );
        await widget.service.updateGlobalTeamLogoUrl(widget.team.id, url);
      }
      if (mounted) setState(() { _editing = false; _newLogoFile = null; _uploadProgress = 0; });
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeMember(TeamMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Remove Member', style: TextStyle(color: Colors.white)),
        content: Text('Remove ${member.displayName} from the team?',
            style: const TextStyle(color: Color(0xFF999999))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF777777)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: Color(0xFFff4444)))),
        ],
      ),
    );
    if (ok == true) {
      await widget.service.removeTeamMember(widget.team.id, member);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: const Color(0xFF333333),
    behavior: SnackBarBehavior.floating,
  ));

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
    final hasImage = (_newLogoFile == null) && team.logoUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(children: [
          // ── Header ─────────────────────────────────────────────────────
          _Header(
            team: team,
            isCaptain: widget.isCaptain,
            editing: _editing,
            onBack: () => Navigator.pop(context),
            onEdit: () => setState(() => _editing = !_editing),
          ),
          Expanded(
            child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo & Name Area ──────────────────────────────────────
                Center(child: Column(children: [
                  // Logo
                  GestureDetector(
                    onTap: _editing ? _pickLogo : null,
                    child: Stack(children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A1A),
                          border: Border.all(
                            color: _editing ? const Color(0xFFF0A500) : const Color(0xFF2A2A2A),
                            width: _editing ? 2 : 1.5,
                          ),
                          image: _newLogoFile != null
                              ? DecorationImage(image: FileImage(_newLogoFile!), fit: BoxFit.cover)
                              : hasImage
                                  ? DecorationImage(image: NetworkImage(team.logoUrl), fit: BoxFit.cover)
                                  : null,
                          boxShadow: [BoxShadow(
                            color: const Color(0xFFF0A500).withOpacity(0.15), blurRadius: 20,
                          )],
                        ),
                        child: (_newLogoFile != null || hasImage)
                            ? null
                            : Center(child: Text(
                                _editing ? _editEmoji : team.logoEmoji,
                                style: const TextStyle(fontSize: 46))),
                      ),
                      if (_editing)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 30, height: 30,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0xFFF0A500),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Name (editable)
                  if (_editing) ...[
                    SizedBox(width: 260, child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: TextField(
                        controller: _nameCtrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    )),
                    const SizedBox(height: 12),
                    // Emoji picker (when editing)
                    Wrap(
                      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                      children: _kEmojis.map((em) {
                        final sel = em == _editEmoji && _newLogoFile == null;
                        return GestureDetector(
                          onTap: () => setState(() { _editEmoji = em; _newLogoFile = null; }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: sel ? const Color(0xFF2A1800) : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel ? const Color(0xFFF0A500) : const Color(0xFF2A2A2A),
                              ),
                            ),
                            child: Center(child: Text(em, style: const TextStyle(fontSize: 20))),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Text(team.name, style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${team.maxMembers}-player team  ·  ${team.members.length} members',
                        style: const TextStyle(color: Color(0xFF555555), fontSize: 13)),
                  ],
                ])),
                const SizedBox(height: 24),

                // ── Members ───────────────────────────────────────────────
                const _SectionTitle('Members'),
                const SizedBox(height: 10),
                ...team.members.map((member) => _MemberTile(
                  member: member,
                  isCaptain: member.uid == team.captainUid,
                  canRemove: widget.isCaptain && member.uid != team.captainUid,
                  onRemove: () => _removeMember(member),
                )),

                if (team.pendingEmails.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _SectionTitle('Pending Invites'),
                  const SizedBox(height: 10),
                  ...team.pendingEmails.map((email) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF222222)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.hourglass_empty, color: Color(0xFF777777), size: 16),
                        const SizedBox(width: 10),
                        Expanded(child: Text(email,
                            style: const TextStyle(color: Color(0xFF777777), fontSize: 13))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Pending',
                              style: TextStyle(color: Color(0xFF777777), fontSize: 10)),
                        ),
                      ]),
                    ),
                  )),
                ],

                const SizedBox(height: 24),

                // ── Save / Cancel buttons (edit mode) ─────────────────────
                if (_editing) ...[
                  if (_saving)
                    _UploadProgress(progress: _uploadProgress)
                  else
                    Column(children: [
                      GestureDetector(
                        onTap: _saveEdits,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFC8860A), Color(0xFFF0A500)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('Save Changes',
                              style: TextStyle(color: Colors.black,
                                  fontWeight: FontWeight.w800, fontSize: 15))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => setState(() { _editing = false; _newLogoFile = null; }),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: const Center(child: Text('Cancel',
                              style: TextStyle(color: Color(0xFF777777),
                                  fontWeight: FontWeight.w700, fontSize: 15))),
                        ),
                      ),
                    ]),
                ],
                const SizedBox(height: 32),
              ],
            )),
          ),
        ]),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TeamModel team;
  final bool isCaptain;
  final bool editing;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  const _Header({required this.team, required this.isCaptain,
      required this.editing, required this.onBack, required this.onEdit});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
    ),
    child: Row(children: [
      IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      ),
      const Expanded(child: Text('Team Details',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
      if (isCaptain)
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: editing ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: editing ? const Color(0xFF444444) : const Color(0xFFF0A500),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(editing ? Icons.close : Icons.edit_outlined,
                  color: editing ? const Color(0xFF777777) : const Color(0xFFF0A500), size: 14),
              const SizedBox(width: 4),
              Text(editing ? 'Cancel' : 'Edit',
                  style: TextStyle(
                    color: editing ? const Color(0xFF777777) : const Color(0xFFF0A500),
                    fontSize: 12, fontWeight: FontWeight.w700,
                  )),
            ]),
          ),
        ),
    ]),
  );
}

// ─── Member Tile ──────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final TeamMember member;
  final bool isCaptain;
  final bool canRemove;
  final VoidCallback onRemove;
  const _MemberTile({required this.member, required this.isCaptain,
      required this.canRemove, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCaptain ? const Color(0xFF1A1000) : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCaptain ? const Color(0xFF2A2200) : const Color(0xFF222222),
        ),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCaptain ? const Color(0xFF2A1800) : const Color(0xFF1A1A1A),
            border: Border.all(color: isCaptain ? const Color(0xFFC8860A) : const Color(0xFF333333)),
          ),
          child: Center(child: Text(
            member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color: isCaptain ? const Color(0xFFF0A500) : Colors.white,
              fontSize: 16, fontWeight: FontWeight.w800,
            ),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(member.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            if (isCaptain) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1800),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Captain',
                    style: TextStyle(color: Color(0xFFF0A500), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(member.email,
              style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
        ])),
        if (canRemove)
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1A0000),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4A0000)),
              ),
              child: const Icon(Icons.person_remove, color: Color(0xFFff4444), size: 14),
            ),
          ),
      ]),
    ),
  );
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
      color: Color(0xFFC8860A), fontSize: 12, fontWeight: FontWeight.w700));
}

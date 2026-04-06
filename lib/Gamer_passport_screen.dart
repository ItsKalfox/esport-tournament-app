import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const GamerApp());
}

class GamerApp extends StatelessWidget {
  const GamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'USER';
  String _location = '';
  String _bio = '';
  String _level = 'S8';
  List<String> _favoriteGames = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String name = 'USER';
    String location = '';
    String bio = '';
    String level = 'S8';
    List<String> games = [];

    if ((user.displayName ?? '').trim().isNotEmpty) {
      name = user.displayName!.trim();
    } else {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      final displayName = (data['displayName'] as String?)?.trim();
      if (displayName != null && displayName.isNotEmpty) {
        name = displayName;
      } else {
        final firstName = (data['firstName'] as String?)?.trim();
        if (firstName != null && firstName.isNotEmpty) {
          name = firstName;
        } else {
          final email = (user.email ?? '').trim();
          if (email.isNotEmpty) name = email.split('@').first;
        }
      }
      location = (data['location'] as String?) ?? '';
      bio = (data['bio'] as String?) ?? '';
      level = (data['level'] as String?) ?? 'S8';
      games = (data['favoriteGames'] as List<dynamic>?)?.cast<String>() ?? [];
    }
    if (mounted) {
      setState(() {
        _userName = name;
        _location = location;
        _bio = bio;
        _level = level;
        _favoriteGames = games;
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    final initials = parts.take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    return initials.isNotEmpty ? initials : 'GX';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(_userName),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          "Gamer Passport",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Section
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_userName),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "GAMER PASSPORT",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "LEVEL S8 [PRO GAMER]",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _userName.toUpperCase().replaceAll(' ', '_'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Gamer Passport Locked Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock, color: Colors.orange, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    "RECEIVE GAMER PASSPORT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Unlock by purchasing more than\nRs.10,000 in the store",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Rs. 0 / Rs. 10,000",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        initialName: _userName,
                        initialLocation: _location,
                        initialBio: _bio,
                        initialLevel: _level,
                        initialFavoriteGames: _favoriteGames,
                        onSave: (name, location, bio, level, games) {
                          setState(() {
                            _userName = name;
                            _location = location;
                            _bio = bio;
                            _level = level;
                            _favoriteGames = games;
                          });
                        },
                      ),
                    ),
                  );
                },
                child: const Text(
                  "EDIT PROFILE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Stats Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Active Leagues",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard("RANK", "DIAMOND II", 0.6, Icons.diamond),
                _buildStatCard("WIN RATE", "68%", 0.68, Icons.emoji_events),
                _buildStatCard(
                  "TOTAL EARNING",
                  "\$1,250",
                  0.5,
                  Icons.attach_money,
                ),
                _buildTrophyCard(),
              ],
            ),
            const SizedBox(height: 25),

            // Skills Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Skills",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            _buildSkillCard("FPS: Apex", 0.8),
            const SizedBox(height: 10),
            _buildSkillCard("Strategy: LOL", 0.6),
            const SizedBox(height: 25),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text(
                  "LOGOUT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    double progress,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Icon(icon, color: Colors.blueAccent, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TROPHIES", style: TextStyle(fontSize: 10, color: Colors.grey)),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.military_tech, color: Colors.orange),
              Icon(Icons.military_tech, color: Colors.blueGrey),
              Icon(Icons.military_tech, color: Colors.brown),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(String skill, double level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(skill, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: level,
          backgroundColor: Colors.white12,
          color: Colors.orange,
          minHeight: 8,
        ),
      ],
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialLocation;
  final String initialBio;
  final String initialLevel;
  final List<String> initialFavoriteGames;
  final Function(String name, String location, String bio, String level, List<String> games) onSave;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialLocation,
    required this.initialBio,
    required this.initialLevel,
    required this.initialFavoriteGames,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  late TextEditingController _levelController;
  late List<String> _favoriteGames;
  final TextEditingController _gameController = TextEditingController();
  bool _isSaving = false;

  final List<String> _levelOptions = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _locationController = TextEditingController(text: widget.initialLocation);
    _bioController = TextEditingController(text: widget.initialBio);
    _levelController = TextEditingController(text: widget.initialLevel);
    _favoriteGames = List.from(widget.initialFavoriteGames);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _levelController.dispose();
    _gameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        'level': _levelController.text.trim(),
        'favoriteGames': _favoriteGames,
      });
      
      if (user.displayName != _nameController.text.trim()) {
        await user.updateDisplayName(_nameController.text.trim());
      }
    }

    widget.onSave(
      _nameController.text.trim(),
      _locationController.text.trim(),
      _bioController.text.trim(),
      _levelController.text.trim(),
      _favoriteGames,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _addGame() {
    final game = _gameController.text.trim();
    if (game.isNotEmpty && !_favoriteGames.contains(game)) {
      setState(() {
        _favoriteGames.add(game);
        _gameController.clear();
      });
    }
  }

  void _removeGame(String game) {
    setState(() {
      _favoriteGames.remove(game);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Name",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Location",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: "e.g. Colombo, Sri Lanka",
                hintStyle: const TextStyle(color: Color(0xFF777777)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Level",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _levelOptions.contains(_levelController.text) ? _levelController.text : 'S8',
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  items: _levelOptions.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _levelController.text = value;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Favorite Games",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "Add a game",
                      hintStyle: const TextStyle(color: Color(0xFF777777)),
                    ),
                    onSubmitted: (_) => _addGame(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _addGame,
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _favoriteGames.map((game) {
                return Chip(
                  label: Text(game, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: const Color(0xFF2A2A2A),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                  onDeleted: () => _removeGame(game),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              "Bio",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: "Tell us about yourself...",
                hintStyle: const TextStyle(color: Color(0xFF777777)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "SAVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

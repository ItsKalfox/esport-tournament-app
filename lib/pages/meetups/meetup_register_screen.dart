import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetupRegisterScreen extends StatefulWidget {
  final String meetupId;
  final String meetupTitle;

  const MeetupRegisterScreen({
    super.key,
    required this.meetupId,
    required this.meetupTitle,
  });

  @override
  State<MeetupRegisterScreen> createState() => _MeetupRegisterScreenState();
}

class _MeetupRegisterScreenState extends State<MeetupRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gamertagCtrl = TextEditingController();
  final _discordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedGame = '';
  bool _isLoading = false;

  final _games = [
    'VALORANT',
    'CS2',
    'League of Legends',
    'Dota 2',
    'PUBG Mobile',
    'Free Fire',
    'Fighter Community',
    'Mobile Legends',
    'Other',
  ];

  @override
  void dispose() {
    _gamertagCtrl.dispose();
    _discordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGame.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a game')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to register')),
          );
        }
        return;
      }

      if (widget.meetupId.startsWith('mock_')) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration confirmed! This is a demo event.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('meetups')
          .doc(widget.meetupId)
          .update({
        'attendees': FieldValue.arrayUnion([
          {
            'uid': user.uid,
            'gamertag': _gamertagCtrl.text.trim(),
            'discord': _discordCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'game': _selectedGame,
            'registeredAt': DateTime.now(),
          }
        ]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully registered!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE9E9E9)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Register for Meetup',
          style: TextStyle(
            color: Color(0xFFE9E9E9),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2A2A2A),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: Color(0xFFFF8A00),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.meetupTitle,
                            style: const TextStyle(
                              color: Color(0xFFE9E9E9),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sri Lanka',
                            style: TextStyle(
                              color: const Color(0xFF9A9A9A),
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Gamer Tag / IGN',
                style: TextStyle(
                  color: Color(0xFF9A9A9A),
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gamertagCtrl,
                style: const TextStyle(
                  color: Color(0xFFE9E9E9),
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: 'Your in-game name',
                  hintStyle: const TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFF8A00)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your gamer tag';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Game',
                style: TextStyle(
                  color: Color(0xFF9A9A9A),
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: DropdownButton<String>(
                  value: _selectedGame.isEmpty ? null : _selectedGame,
                  hint: const Text(
                    'Select game',
                    style: TextStyle(color: Color(0xFF555555)),
                  ),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(
                    color: Color(0xFFE9E9E9),
                    fontFamily: 'Poppins',
                  ),
                  underline: const SizedBox(),
                  items: _games.map((game) {
                    return DropdownMenuItem(
                      value: game,
                      child: Text(game),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGame = value ?? '');
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Discord Username',
                style: TextStyle(
                  color: Color(0xFF9A9A9A),
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _discordCtrl,
                style: const TextStyle(
                  color: Color(0xFFE9E9E9),
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: 'username#0000',
                  hintStyle: const TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFF8A00)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Phone Number',
                style: TextStyle(
                  color: Color(0xFF9A9A9A),
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  color: Color(0xFFE9E9E9),
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: '+94 7x xxx xxxx',
                  hintStyle: const TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFF8A00)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'You will receive confirmation after registration',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontFamily: 'Poppins',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
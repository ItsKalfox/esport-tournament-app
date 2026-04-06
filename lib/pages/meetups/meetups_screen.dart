import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'meetup_register_screen.dart';

final _mockMeetups = [
  {
    'title': 'Colombo Gaming Cafe Meetup',
    'description': 'Join us for an evening of competitive gaming and networking with fellow gamers in Colombo.',
    'game': 'VALORANT',
    'location': 'GamerZone Cafe, Colombo 04',
    'date': DateTime(2026, 4, 15),
    'country': 'Sri Lanka',
    'attendees': ['user1', 'user2', 'user3'],
    'maxAttendees': 20,
  },
  {
    'title': 'Kandy Esports LAN Party',
    'description': 'First ever esports LAN party in Kandy! Come compete in tournaments and meet local gamers.',
    'game': 'CS2',
    'location': 'Cyber Arena, Kandy',
    'date': DateTime(2026, 4, 22),
    'country': 'Sri Lanka',
    'attendees': ['user1'],
    'maxAttendees': 32,
  },
  {
    'title': 'Mobile Gaming Session - Galle',
    'description': 'Mobile esports meetup. Bring your phone and compete in PUBG Mobile and Free Fire tournaments.',
    'game': 'PUBG MOBILE',
    'location': 'Galle Fort Lounge',
    'date': DateTime(2026, 5, 1),
    'country': 'Sri Lanka',
    'attendees': ['user1', 'user2'],
    'maxAttendees': 50,
  },
  {
    'title': 'Fighting Game Championship',
    'description': 'Street Fighter 6 and Tekken 8 tournament. Winner takes home LKR 10,000!',
    'game': 'FGC',
    'location': 'Battle Arena, Negombo',
    'date': DateTime(2026, 5, 8),
    'country': 'Sri Lanka',
    'attendees': [],
    'maxAttendees': 24,
  },
];

Future<void> _seedMeetups() async {
  final docs = await FirebaseFirestore.instance.collection('meetups').get();
  if (docs.docs.isEmpty) {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < _mockMeetups.length; i++) {
      final docRef = FirebaseFirestore.instance.collection('meetups').doc();
      batch.set(docRef, {
        ..._mockMeetups[i],
        'date': _mockMeetups[i]['date'],
        'createdAt': DateTime.now(),
      });
    }
    await batch.commit();
  }
}

class MeetupsScreen extends StatefulWidget {
  const MeetupsScreen({super.key});

  @override
  State<MeetupsScreen> createState() => _MeetupsScreenState();
}

class _MeetupsScreenState extends State<MeetupsScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMeetups();
  }

  Future<void> _initializeMeetups() async {
    if (_initialized) return;
    _initialized = true;
    await _seedMeetups();
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
          'Gamer Meetups Sri Lanka',
          style: TextStyle(
            color: Color(0xFFE9E9E9),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('meetups')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF8A00),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFF9A9A9A),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final allMeetups = snapshot.data?.docs ?? [];
          final firestoreMeetups = allMeetups
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final country = data['country'] as String? ?? '';
                return country.toLowerCase() == 'sri lanka';
              })
              .toList();

          final List meetups = firestoreMeetups.isEmpty ? _mockMeetups : firestoreMeetups;

          if (meetups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    color: Color(0xFF9A9A9A),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No meetups in Sri Lanka yet',
                    style: TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to organize one!',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetups.length,
            itemBuilder: (context, index) {
final item = meetups[index];
              final isFirestore = item is QueryDocumentSnapshot;
              final docId = isFirestore ? (item as QueryDocumentSnapshot).id : 'mock_$index';
              final data = isFirestore 
                  ? (item as QueryDocumentSnapshot).data() as Map<String, dynamic>
                  : item as Map<String, dynamic>;
              final date = data['date'];
              final title = data['title'] as String? ?? 'Untitled';
              final location = data['location'] as String? ?? 'TBD';
              final description = data['description'] as String? ?? '';
              final game = data['game'] as String? ?? '';
              final attendees = (data['attendees'] as List?) ?? [];
              DateTime? meetupDate;
              if (date is DateTime) {
                meetupDate = date;
              } else if (date is Timestamp) {
                meetupDate = date.toDate();
              }
              final maxAttendees = data['maxAttendees'] as int? ?? 20;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2A2A2A),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A00).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              game,
                              style: const TextStyle(
                                color: Color(0xFFFF8A00),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (meetupDate != null)
                            Text(
                              '${meetupDate.day}/${meetupDate.month}/${meetupDate.year}',
                              style: const TextStyle(
                                color: Color(0xFF9A9A9A),
                                fontFamily: 'Poppins',
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFE9E9E9),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF9A9A9A),
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF9A9A9A),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                color: Color(0xFF9A9A9A),
                                fontFamily: 'Poppins',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.people_outline,
                            color: Color(0xFF9A9A9A),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${attendees.length}/$maxAttendees',
                            style: const TextStyle(
                              color: Color(0xFF9A9A9A),
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MeetupRegisterScreen(
                                meetupId: docId,
                                meetupTitle: title,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A00),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Join Meetup',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
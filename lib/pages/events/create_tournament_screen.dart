import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tournament_model.dart';
import '../../services/tournament_service.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _service = TournamentService();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _loading = false;

  // Step 1 — Basic Info
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rulesCtrl =
      TextEditingController(text: TournamentModel.defaultRules);
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  String _time = '18:00';

  // Step 2 — Config
  int _maxTeams = 25;
  int _playersPerTeam = 4;
  int _killPoints = 15;
  late Map<int, TextEditingController> _placementCtrls;
  late Map<int, int> _placementPoints;

  // Step 3 — Prize Pool
  int _winnerCount = 3;
  final List<Map<String, dynamic>> _prizeSlots = [];
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _placementPoints = Map.fromEntries(
      PointConfig.defaults()
          .placementPoints
          .entries
          .map((e) => MapEntry(e.key, e.value)),
    );
    _placementCtrls = {
      for (final e in _placementPoints.entries)
        e.key: TextEditingController(text: e.value.toString())
    };
    // Initialize default prize slots
    for (int i = 1; i <= 3; i++) {
      _prizeSlots.add({
        'place': i,
        'amountCtrl': TextEditingController(
            text: i == 1 ? '1000' : i == 2 ? '500' : '250'),
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _rulesCtrl.dispose();
    for (final c in _placementCtrls.values) {
      c.dispose();
    }
    for (final s in _prizeSlots) {
      (s['amountCtrl'] as TextEditingController).dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showSnack('Please enter a tournament name');
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _createTournament();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF0A500),
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF0A500),
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _time =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  void _addPrizeSlot() {
    final nextPlace = _prizeSlots.length + 1;
    setState(() {
      _prizeSlots.add({
        'place': nextPlace,
        'amountCtrl': TextEditingController(text: '0'),
      });
    });
  }

  void _removePrizeSlot(int index) {
    final ctrl = _prizeSlots[index]['amountCtrl'] as TextEditingController;
    ctrl.dispose();
    setState(() {
      _prizeSlots.removeAt(index);
      // Re-number places
      for (int i = 0; i < _prizeSlots.length; i++) {
        _prizeSlots[i]['place'] = i + 1;
      }
    });
  }

  Future<void> _createTournament() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final placementPts = <int, int>{};
      for (final e in _placementCtrls.entries) {
        placementPts[e.key] = int.tryParse(e.value.text) ?? 0;
      }

      final prizeSlots = _prizeSlots
          .map((s) => PrizeSlot(
                place: s['place'] as int,
                amount: double.tryParse(
                        (s['amountCtrl'] as TextEditingController).text) ??
                    0,
                currency: _currency,
              ))
          .toList();

      final tournament = TournamentModel(
        id: '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        rules: _rulesCtrl.text.trim(),
        date: _date,
        time: _time,
        status: TournamentStatus.upcoming,
        organizerUid: user.uid,
        organizerName: user.displayName ?? 'Organizer',
        maxTeams: _maxTeams,
        playersPerTeam: _playersPerTeam,
        totalPlayers: _maxTeams * _playersPerTeam,
        registeredTeams: 0,
        pointConfig: PointConfig(
          placementPoints: placementPts,
          killPoints: _killPoints,
        ),
        prizeSlots: prizeSlots,
        winnerCount: _winnerCount,
        createdAt: DateTime.now(),
      );

      await _service.createTournament(tournament);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament created successfully! 🏆'),
            backgroundColor: Color(0xFF2A8C00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showSnack('Error creating tournament: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'Create Tournament',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Step indicator
            _StepIndicator(currentStep: _currentStep),
            const SizedBox(height: 20),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1BasicInfo(
                    nameCtrl: _nameCtrl,
                    descCtrl: _descCtrl,
                    rulesCtrl: _rulesCtrl,
                    date: _date,
                    time: _time,
                    onPickDate: _pickDate,
                    onPickTime: _pickTime,
                  ),
                  _Step2Config(
                    maxTeams: _maxTeams,
                    playersPerTeam: _playersPerTeam,
                    killPoints: _killPoints,
                    placementCtrls: _placementCtrls,
                    onMaxTeamsChanged: (v) => setState(() => _maxTeams = v),
                    onPlayersChanged: (v) => setState(() => _playersPerTeam = v),
                    onKillPointsChanged: (v) => setState(() => _killPoints = v),
                  ),
                  _Step3PrizePool(
                    prizeSlots: _prizeSlots,
                    winnerCount: _winnerCount,
                    currency: _currency,
                    onWinnerCountChanged: (v) =>
                        setState(() => _winnerCount = v),
                    onCurrencyChanged: (v) => setState(() => _currency = v),
                    onAddSlot: _addPrizeSlot,
                    onRemoveSlot: _removePrizeSlot,
                  ),
                ],
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: _OutlineBtn(
                        label: 'Back',
                        onTap: _prevStep,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFF0A500)))
                        : _GoldBtn(
                            label: _currentStep == 2 ? 'Create 🏆' : 'Next →',
                            onTap: _nextStep,
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

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = ['Basic Info', 'Configure', 'Prizes'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == currentStep;
          final done = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: done || active
                              ? const Color(0xFFF0A500)
                              : const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: active
                              ? const Color(0xFFF0A500)
                              : done
                                  ? const Color(0xFFC8860A)
                                  : const Color(0xFF444444),
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < labels.length - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Basic Info ───────────────────────────────────────────────────────

class _Step1BasicInfo extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController rulesCtrl;
  final DateTime date;
  final String time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _Step1BasicInfo({
    required this.nameCtrl,
    required this.descCtrl,
    required this.rulesCtrl,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Tournament Name *'),
          _DarkField(controller: nameCtrl, hint: 'e.g. Iron Arena Season 1'),
          const SizedBox(height: 16),
          _FieldLabel('Description'),
          _DarkField(
            controller: descCtrl,
            hint: 'Short description of the tournament…',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Date'),
                    GestureDetector(
                      onTap: onPickDate,
                      child: _TapField(
                          icon: Icons.calendar_today, label: dateStr),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Time'),
                    GestureDetector(
                      onTap: onPickTime,
                      child:
                          _TapField(icon: Icons.access_time, label: time),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FieldLabel('Tournament Rules'),
          const SizedBox(height: 4),
          const Text(
            'Default rules are pre-filled. Edit as needed.',
            style: TextStyle(color: Color(0xFF555555), fontSize: 11),
          ),
          const SizedBox(height: 6),
          _DarkField(
            controller: rulesCtrl,
            hint: 'Tournament rules…',
            maxLines: 12,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Step 2: Config ───────────────────────────────────────────────────────────

class _Step2Config extends StatelessWidget {
  final int maxTeams;
  final int playersPerTeam;
  final int killPoints;
  final Map<int, TextEditingController> placementCtrls;
  final ValueChanged<int> onMaxTeamsChanged;
  final ValueChanged<int> onPlayersChanged;
  final ValueChanged<int> onKillPointsChanged;

  const _Step2Config({
    required this.maxTeams,
    required this.playersPerTeam,
    required this.killPoints,
    required this.placementCtrls,
    required this.onMaxTeamsChanged,
    required this.onPlayersChanged,
    required this.onKillPointsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Max Teams'),
          _StepperField(
            value: maxTeams,
            min: 2,
            max: 100,
            onChanged: onMaxTeamsChanged,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Players per Team'),
          _StepperField(
            value: playersPerTeam,
            min: 1,
            max: 10,
            onChanged: onPlayersChanged,
          ),
          const SizedBox(height: 4),
          Text(
            'Total players: ${maxTeams * playersPerTeam}',
            style: const TextStyle(color: Color(0xFFF0A500), fontSize: 12),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Kill Points (per kill)'),
          _StepperField(
            value: killPoints,
            min: 0,
            max: 100,
            onChanged: onKillPointsChanged,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Placement Points'),
          const SizedBox(height: 4),
          const Text(
            'Points awarded per rank. Other ranks get 0.',
            style: TextStyle(color: Color(0xFF555555), fontSize: 11),
          ),
          const SizedBox(height: 10),
          ...() {
            final sorted = placementCtrls.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));
            return sorted.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      _ordinal(e.key),
                      style: const TextStyle(
                        color: Color(0xFFC8860A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _DarkField(
                      controller: e.value,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('pts',
                      style: TextStyle(
                          color: Color(0xFF555555), fontSize: 12)),
                ],
              ),
            )).toList();
          }(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _ordinal(int n) {
    final suffix =
        n == 1 ? 'st' : n == 2 ? 'nd' : n == 3 ? 'rd' : 'th';
    return '#$n ($suffix place)';
  }
}

// ─── Step 3: Prize Pool ───────────────────────────────────────────────────────

class _Step3PrizePool extends StatelessWidget {
  final List<Map<String, dynamic>> prizeSlots;
  final int winnerCount;
  final String currency;
  final ValueChanged<int> onWinnerCountChanged;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onAddSlot;
  final ValueChanged<int> onRemoveSlot;

  const _Step3PrizePool({
    required this.prizeSlots,
    required this.winnerCount,
    required this.currency,
    required this.onWinnerCountChanged,
    required this.onCurrencyChanged,
    required this.onAddSlot,
    required this.onRemoveSlot,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Currency'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: DropdownButton<String>(
              value: currency,
              dropdownColor: const Color(0xFF1A1A1A),
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: ['USD', 'EUR', 'GBP', 'LKR', 'INR', 'Custom']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => onCurrencyChanged(v ?? 'USD'),
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Number of Winners'),
          _StepperField(
            value: winnerCount,
            min: 1,
            max: 25,
            onChanged: onWinnerCountChanged,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Prize Distribution'),
          const SizedBox(height: 4),
          const Text(
            'Set the prize amount for each placing team.',
            style: TextStyle(color: Color(0xFF555555), fontSize: 11),
          ),
          const SizedBox(height: 10),
          ...List.generate(prizeSlots.length, (i) {
            final slot = prizeSlots[i];
            final place = slot['place'] as int;
            final ctrl = slot['amountCtrl'] as TextEditingController;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: place == 1
                          ? const Color(0xFFFFD700).withOpacity(0.15)
                          : place == 2
                              ? const Color(0xFFC0C0C0).withOpacity(0.15)
                              : place == 3
                                  ? const Color(0xFFCD7F32).withOpacity(0.15)
                                  : const Color(0xFF1A1A1A),
                    ),
                    child: Center(
                      child: Text(
                        place == 1
                            ? '🥇'
                            : place == 2
                                ? '🥈'
                                : place == 3
                                    ? '🥉'
                                    : '#$place',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DarkField(
                      controller: ctrl,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      prefix: '$currency ',
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onRemoveSlot(i),
                    child: const Icon(Icons.remove_circle_outline,
                        color: Color(0xFF555555), size: 20),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onAddSlot,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF333333)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Color(0xFF777777), size: 18),
                  SizedBox(width: 6),
                  Text('Add Place',
                      style:
                          TextStyle(color: Color(0xFF777777), fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFC8860A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final String? prefix;

  const _DarkField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF444444), fontSize: 14),
            prefixText: prefix,
            prefixStyle:
                const TextStyle(color: Color(0xFF777777), fontSize: 14),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
}

class _TapField extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TapField({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF0A500), size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      );
}

class _StepperField extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperField({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove, size: 18),
              color: const Color(0xFFF0A500),
              disabledColor: const Color(0xFF333333),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add, size: 18),
              color: const Color(0xFFF0A500),
              disabledColor: const Color(0xFF333333),
            ),
          ],
        ),
      );
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GoldBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF333333)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
}

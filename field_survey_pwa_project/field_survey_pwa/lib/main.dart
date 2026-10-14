import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FieldSurveyApp());
}

class FieldSurveyApp extends StatelessWidget {
  const FieldSurveyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F766E);
    return MaterialApp(
      title: 'Field Survey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE6EBF0)),
          ),
        ),
      ),
      home: const SurveyDashboard(),
    );
  }
}

enum SurveyStatus {
  planned('Planned'),
  inProgress('In progress'),
  completed('Completed');

  const SurveyStatus(this.label);
  final String label;

  static SurveyStatus fromValue(String? value) {
    return SurveyStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SurveyStatus.planned,
    );
  }
}

class SurveyRecord {
  const SurveyRecord({
    required this.id,
    required this.location,
    required this.surveyor,
    required this.date,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String location;
  final String surveyor;
  final String date;
  final SurveyStatus status;
  final String notes;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'location': location,
        'surveyor': surveyor,
        'date': date,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt,
      };

  factory SurveyRecord.fromJson(Map<String, dynamic> json) {
    return SurveyRecord(
      id: json['id'] as String? ?? '',
      location: json['location'] as String? ?? '',
      surveyor: json['surveyor'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: SurveyStatus.fromValue(json['status'] as String?),
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  SurveyRecord copyWith({
    String? id,
    String? location,
    String? surveyor,
    String? date,
    SurveyStatus? status,
    String? notes,
    String? createdAt,
  }) {
    return SurveyRecord(
      id: id ?? this.id,
      location: location ?? this.location,
      surveyor: surveyor ?? this.surveyor,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SurveyStorage {
  static const _key = 'field_survey_records_v1';

  Future<List<SurveyRecord>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SurveyRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<SurveyRecord> records) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }
}

class SurveyDashboard extends StatefulWidget {
  const SurveyDashboard({super.key});

  @override
  State<SurveyDashboard> createState() => _SurveyDashboardState();
}

class _SurveyDashboardState extends State<SurveyDashboard> {
  final SurveyStorage _storage = SurveyStorage();
  final TextEditingController _searchController = TextEditingController();

  List<SurveyRecord> _records = [];
  bool _loading = true;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final records = await _storage.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _persist() => _storage.save(_records);

  List<SurveyRecord> get _visibleRecords {
    final query = _searchController.text.trim().toLowerCase();
    return _records.where((record) {
      final matchesStatus =
          _statusFilter == 'All' || record.status.label == _statusFilter;
      final haystack =
          '${record.location} ${record.surveyor} ${record.notes}'.toLowerCase();
      return matchesStatus && haystack.contains(query);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _openEditor({SurveyRecord? record}) async {
    final result = await showDialog<SurveyRecord>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SurveyEditorDialog(record: record),
    );
    if (result == null || !mounted) return;

    setState(() {
      final index = _records.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _records.insert(0, result);
      } else {
        _records[index] = result;
      }
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(record == null
            ? 'Survey record created.'
            : 'Survey record updated.'),
      ),
    );
  }

  Future<void> _deleteRecord(SurveyRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete survey?'),
        content: Text('Delete the survey for "${record.location}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _records.removeWhere((item) => item.id == record.id));
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Survey record deleted.')),
    );
  }

  void _showDetails(SurveyRecord record) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(record.location),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailLine(label: 'Surveyor', value: record.surveyor),
                _DetailLine(label: 'Survey date', value: record.date),
                _DetailLine(label: 'Status', value: record.status.label),
                _DetailLine(
                  label: 'Notes',
                  value: record.notes.isEmpty ? 'No notes provided' : record.notes,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openEditor(record: record);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _visibleRecords;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 650;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.travel_explore, size: 27),
            SizedBox(width: 10),
            Text('Field Survey', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (!compact)
            const Padding(
              padding: EdgeInsets.only(right: 24),
              child: Center(
                child: Text(
                  'FIELD OPERATIONS',
                  style: TextStyle(
                    letterSpacing: 1.2,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('New survey'),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.all(compact ? 16 : 32),
                  children: [
                    Text(
                      'Survey dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF152B35),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create and manage your field observations in one place.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth =
                            constraints.maxWidth < 520
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 24) / 3;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _MetricCard(
                                label: 'Total surveys',
                                value: '${_records.length}',
                                icon: Icons.assignment_outlined,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MetricCard(
                                label: 'In progress',
                                value: '${_records.where((r) => r.status == SurveyStatus.inProgress).length}',
                                icon: Icons.pending_actions_outlined,
                                color: const Color(0xFFB54708),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MetricCard(
                                label: 'Completed',
                                value: '${_records.where((r) => r.status == SurveyStatus.completed).length}',
                                icon: Icons.task_alt_outlined,
                                color: const Color(0xFF027A48),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Survey records',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (!compact)
                          FilledButton.icon(
                            onPressed: () => _openEditor(),
                            icon: const Icon(Icons.add),
                            label: const Text('New survey'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: compact ? double.infinity : 360,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search location, surveyor, notes...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: _searchController.clear,
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: compact ? double.infinity : 190,
                          child: DropdownButtonFormField<String>(
                            value: _statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Filter by status',
                            ),
                            items: [
                              'All',
                              ...SurveyStatus.values.map((s) => s.label),
                            ]
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(
                              () => _statusFilter = value ?? 'All',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (records.isEmpty)
                      _EmptyState(
                        hasFilters: _records.isNotEmpty,
                        onCreate: () => _openEditor(),
                      )
                    else
                      ...records.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SurveyCard(
                            record: record,
                            onTap: () => _showDetails(record),
                            onEdit: () => _openEditor(record: record),
                            onDelete: () => _deleteRecord(record),
                          ),
                        ),
                      ),
                    const SizedBox(height: 72),
                    const Center(
                      child: Text(
                        'Field Survey • Flutter Web',
                        style: TextStyle(color: Color(0xFF98A2B3), fontSize: 12),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SurveyEditorDialog extends StatefulWidget {
  const SurveyEditorDialog({super.key, this.record});
  final SurveyRecord? record;

  @override
  State<SurveyEditorDialog> createState() => _SurveyEditorDialogState();
}

class _SurveyEditorDialogState extends State<SurveyEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _location;
  late final TextEditingController _surveyor;
  late final TextEditingController _notes;
  late DateTime _date;
  late SurveyStatus _status;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _location = TextEditingController(text: record?.location ?? '');
    _surveyor = TextEditingController(text: record?.surveyor ?? '');
    _notes = TextEditingController(text: record?.notes ?? '');
    _date = DateTime.tryParse(record?.date ?? '') ?? DateTime.now();
    _status = record?.status ?? SurveyStatus.planned;
  }

  @override
  void dispose() {
    _location.dispose();
    _surveyor.dispose();
    _notes.dispose();
    super.dispose();
  }

  String get _dateText =>
      '${_date.year.toString().padLeft(4, '0')}-'
      '${_date.month.toString().padLeft(2, '0')}-'
      '${_date.day.toString().padLeft(2, '0')}';

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.record;
    Navigator.pop(
      context,
      SurveyRecord(
        id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        location: _location.text.trim(),
        surveyor: _surveyor.text.trim(),
        date: _dateText,
        status: _status,
        notes: _notes.text.trim(),
        createdAt: old?.createdAt ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.record == null ? 'Create survey' : 'Edit survey'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _location,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    hintText: 'e.g. District 1, Ho Chi Minh City',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a location.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _surveyor,
                  decoration: const InputDecoration(
                    labelText: 'Surveyor name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter the surveyor name.'
                      : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _chooseDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Survey date',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(_dateText)),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<SurveyStatus>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: SurveyStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Record observations or findings...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save survey'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
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

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({
    required this.record,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final SurveyRecord record;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (record.status) {
      SurveyStatus.planned => const Color(0xFF475467),
      SurveyStatus.inProgress => const Color(0xFFB54708),
      SurveyStatus.completed => const Color(0xFF027A48),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${record.surveyor}  •  ${record.date}',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 13,
                      ),
                    ),
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        record.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF475467),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      record.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Color(0xFFB42318),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(value),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasFilters,
    required this.onCreate,
  });

  final bool hasFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
        child: Column(
          children: [
            const Icon(
              Icons.travel_explore,
              size: 54,
              color: Color(0xFF98A2B3),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilters ? 'No matching surveys' : 'No surveys yet',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try another search term or status filter.'
                  : 'Create your first field survey to get started.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create first survey'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

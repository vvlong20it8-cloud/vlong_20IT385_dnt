import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

void main() {

  runApp(const FieldSurveyApp());

}

// For Flutter Web running on the same Windows PC as XAMPP.

// If Apache uses another port, change this URL.

// For a deployed PWA, use the real HTTPS URL of your PHP API.

const String apiBaseUrl = 'http://localhost/field_survey_api/api.php';

class Survey {

  const Survey({

    this.id,

    required this.location,

    required this.surveyor,

    required this.date,

    required this.status,

    required this.notes,

    this.createdAt = '',

  });

  final int? id;

  final String location;

  final String surveyor;

  final String date;

  final String status;

  final String notes;

  final String createdAt;

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(

        id: int.tryParse('${json['id']}'),

        location: '${json['location'] ?? ''}',

        surveyor: '${json['surveyor'] ?? ''}',

        date: '${json['date'] ?? ''}',

        status: '${json['status'] ?? 'Planned'}',

        notes: '${json['notes'] ?? ''}',

        createdAt: '${json['createdAt'] ?? ''}',

      );

  Map<String, dynamic> toJson() => {

        'location': location,

        'surveyor': surveyor,

        'date': date,

        'status': status,

        'notes': notes,

      };

}

class SurveyApi {

  Future<List<Survey>> list() async {

    final response = await http.get(Uri.parse(apiBaseUrl));

    final body = _decode(response);

    return (body['data'] as List<dynamic>)

        .map((item) => Survey.fromJson(Map<String, dynamic>.from(item as Map)))

        .toList();

  }

  Future<void> create(Survey survey) async {

    final response = await http.post(

      Uri.parse(apiBaseUrl),

      headers: {'Content-Type': 'application/json; charset=UTF-8'},

      body: jsonEncode(survey.toJson()),

    );

    _decode(response);

  }

  Future<void> update(Survey survey) async {

    final response = await http.put(

      Uri.parse('$apiBaseUrl?id=${survey.id}'),

      headers: {'Content-Type': 'application/json; charset=UTF-8'},

      body: jsonEncode(survey.toJson()),

    );

    _decode(response);

  }

  Future<void> delete(int id) async {

    final response = await http.delete(Uri.parse('$apiBaseUrl?id=$id'));

    _decode(response);

  }

  Map<String, dynamic> _decode(http.Response response) {

    Map<String, dynamic> json;

    try {

      json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);

    } catch (_) {

      throw Exception(

        'API returned an invalid response (HTTP ${response.statusCode}). '

        'Check Apache/PHP and the API URL.',

      );

    }

    if (response.statusCode < 200 ||

        response.statusCode >= 300 ||

        json['success'] != true) {

      throw Exception(json['message'] ?? 'API request failed.');

    }

    return json;

  }

}

class FieldSurveyApp extends StatelessWidget {

  const FieldSurveyApp({super.key});

  @override

  Widget build(BuildContext context) => MaterialApp(

        title: 'Field Survey',

        debugShowCheckedModeBanner: false,

        theme: ThemeData(

          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),

          scaffoldBackgroundColor: const Color(0xFFF5F7FA),

        ),

        home: const SurveyHomePage(),

      );

}

class SurveyHomePage extends StatefulWidget {

  const SurveyHomePage({super.key});

  @override

  State<SurveyHomePage> createState() => _SurveyHomePageState();

}

class _SurveyHomePageState extends State<SurveyHomePage> {

  final SurveyApi _api = SurveyApi();

  final TextEditingController _search = TextEditingController();

  List<Survey> _surveys = [];

  bool _loading = true;

  String? _error;

  String _filter = 'All';

  @override

  void initState() {

    super.initState();

    _search.addListener(() => setState(() {}));

    _load();

  }

  @override

  void dispose() {

    _search.dispose();

    super.dispose();

  }

  Future<void> _load() async {

    setState(() {

      _loading = true;

      _error = null;

    });

    try {

      final result = await _api.list();

      if (!mounted) return;

      setState(() {

        _surveys = result;

        _loading = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _error = e.toString().replaceFirst('Exception: ', '');

        _loading = false;

      });

    }

  }

  List<Survey> get _visible {

    final q = _search.text.trim().toLowerCase();

    return _surveys.where((s) {

      final matchesQuery =

          '${s.location} ${s.surveyor} ${s.notes}'.toLowerCase().contains(q);

      return matchesQuery && (_filter == 'All' || s.status == _filter);

    }).toList();

  }

  Future<void> _edit({Survey? survey}) async {

    final result = await showDialog<Survey>(

      context: context,

      builder: (_) => SurveyForm(survey: survey),

    );

    if (result == null) return;

    try {

      if (survey == null) {

        await _api.create(result);

      } else {

        await _api.update(result);

      }

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(survey == null ? 'Survey saved to MySQL.' : 'Survey updated in MySQL.')),

      );

    } catch (e) {

      _showError(e);

    }

  }

  Future<void> _delete(Survey survey) async {

    final yes = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Delete survey?'),

        content: Text('Delete "${survey.location}" permanently?'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),

          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),

        ],

      ),

    );

    if (yes != true || survey.id == null) return;

    try {

      await _api.delete(survey.id!);

      await _load();

    } catch (e) {

      _showError(e);

    }

  }

  void _showError(Object error) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(error.toString().replaceFirst('Exception: ', '')),

        backgroundColor: Colors.red.shade700,

        duration: const Duration(seconds: 6),

      ),

    );

  }

  void _details(Survey s) {

    showDialog<void>(

      context: context,

      builder: (context) => AlertDialog(

        title: Text(s.location),

        content: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text('Surveyor: ${s.surveyor}'),

            Text('Date: ${s.date}'),

            Text('Status: ${s.status}'),

            const SizedBox(height: 8),

            Text('Notes: ${s.notes.isEmpty ? 'None' : s.notes}'),

          ],

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),

          FilledButton(onPressed: () { Navigator.pop(context); _edit(survey: s); }, child: const Text('Edit')),

        ],

      ),

    );

  }

  @override

  Widget build(BuildContext context) {

    final compact = MediaQuery.sizeOf(context).width < 650;

    final visible = _visible;

    return Scaffold(

      appBar: AppBar(

        backgroundColor: const Color(0xFF0F766E),

        foregroundColor: Colors.white,

        title: const Row(children: [

          Icon(Icons.travel_explore),

          SizedBox(width: 10),

          Text('Field Survey', style: TextStyle(fontWeight: FontWeight.bold)),

        ]),

        actions: [

          IconButton(onPressed: _load, tooltip: 'Refresh from database', icon: const Icon(Icons.refresh)),

          const SizedBox(width: 8),

        ],

      ),

      floatingActionButton: compact

          ? FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('New survey'))

          : null,

      body: Center(

        child: ConstrainedBox(

          constraints: const BoxConstraints(maxWidth: 1100),

          child: ListView(

            padding: EdgeInsets.all(compact ? 16 : 30),

            children: [

              Text('Survey dashboard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),

              const SizedBox(height: 6),

              const Text('Survey records are loaded from the MySQL database through a PHP API.'),

              const SizedBox(height: 20),

              Wrap(spacing: 12, runSpacing: 12, children: [

                _Metric(label: 'Total surveys', value: '${_surveys.length}', icon: Icons.assignment_outlined),

                _Metric(label: 'In progress', value: '${_surveys.where((s) => s.status == 'In progress').length}', icon: Icons.pending_actions_outlined),

                _Metric(label: 'Completed', value: '${_surveys.where((s) => s.status == 'Completed').length}', icon: Icons.task_alt_outlined),

              ]),

              const SizedBox(height: 26),

              Row(children: [

                const Expanded(child: Text('Survey records', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),

                if (!compact) FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('New survey')),

              ]),

              const SizedBox(height: 14),

              Wrap(spacing: 12, runSpacing: 12, children: [

                SizedBox(width: compact ? double.infinity : 350, child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search surveys...'))),

                SizedBox(width: compact ? double.infinity : 190, child: DropdownButtonFormField<String>(

                  value: _filter,

                  decoration: const InputDecoration(labelText: 'Status'),

                  items: ['All', 'Planned', 'In progress', 'Completed'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),

                  onChanged: (v) => setState(() => _filter = v ?? 'All'),

                )),

              ]),

              const SizedBox(height: 16),

              if (_loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))

              else if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [

                const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.red),

                const SizedBox(height: 10),

                const Text('Could not connect to the API', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

                const SizedBox(height: 8),

                SelectableText(_error!, textAlign: TextAlign.center),

                const SizedBox(height: 12),

                const Text('Check that Apache and MySQL are running, import the SQL file, and copy the PHP API folder into htdocs.', textAlign: TextAlign.center),

                const SizedBox(height: 12),

                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again')),

              ])))

              else if (visible.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [

                const Icon(Icons.location_searching, size: 48, color: Colors.grey),

                const SizedBox(height: 10),

                Text(_surveys.isEmpty ? 'No surveys yet' : 'No matching surveys', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 8),

                const Text('Create a survey to save a record in MySQL.', textAlign: TextAlign.center),

                const SizedBox(height: 12),

                FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Create survey')),

              ])))

              else ...visible.map((s) => Card(

                margin: const EdgeInsets.only(bottom: 12),

                child: ListTile(

                  onTap: () => _details(s),

                  leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),

                  title: Text(s.location, style: const TextStyle(fontWeight: FontWeight.bold)),

                  subtitle: Text('${s.surveyor} • ${s.date}\n${s.status}${s.notes.isEmpty ? '' : ' • ${s.notes}'}', maxLines: 2, overflow: TextOverflow.ellipsis),

                  isThreeLine: true,

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _edit(survey: s),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _delete(s),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),

                ),

              )),

            ],

          ),

        ),

      ),

    );

  }

}

class SurveyForm extends StatefulWidget {

  const SurveyForm({super.key, this.survey});

  final Survey? survey;

  @override

  State<SurveyForm> createState() => _SurveyFormState();

}

class _SurveyFormState extends State<SurveyForm> {

  final _key = GlobalKey<FormState>();

  late final TextEditingController _location;

  late final TextEditingController _surveyor;

  late final TextEditingController _notes;

  late DateTime _date;

  late String _status;

  @override

  void initState() {

    super.initState();

    final s = widget.survey;

    _location = TextEditingController(text: s?.location ?? '');

    _surveyor = TextEditingController(text: s?.surveyor ?? '');

    _notes = TextEditingController(text: s?.notes ?? '');

    _date = DateTime.tryParse(s?.date ?? '') ?? DateTime.now();

    _status = s?.status ?? 'Planned';

  }

  @override

  void dispose() {

    _location.dispose();

    _surveyor.dispose();

    _notes.dispose();

    super.dispose();

  }

  String get _dateText => '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {

    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));

    if (picked != null) setState(() => _date = picked);

  }

  void _save() {

    if (!_key.currentState!.validate()) return;

    Navigator.pop(context, Survey(

      id: widget.survey?.id,

      location: _location.text.trim(),

      surveyor: _surveyor.text.trim(),

      date: _dateText,

      status: _status,

      notes: _notes.text.trim(),

      createdAt: widget.survey?.createdAt ?? '',

    ));

  }

  @override

  Widget build(BuildContext context) => AlertDialog(

    title: Text(widget.survey == null ? 'New survey' : 'Edit survey'),

    content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(

      key: _key,

      child: Column(mainAxisSize: MainAxisSize.min, children: [

        TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location *'), validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null),

        const SizedBox(height: 12),

        TextFormField(controller: _surveyor, decoration: const InputDecoration(labelText: 'Surveyor *'), validator: (v) => v == null || v.trim().isEmpty ? 'Surveyor is required' : null),

        const SizedBox(height: 12),

        InkWell(onTap: _pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Survey date'), child: Row(children: [Expanded(child: Text(_dateText)), const Icon(Icons.calendar_month)]))),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(

          value: _status,

          decoration: const InputDecoration(labelText: 'Status'),

          items: ['Planned', 'In progress', 'Completed'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),

          onChanged: (v) => setState(() => _status = v ?? 'Planned'),

        ),

        const SizedBox(height: 12),

        TextFormField(controller: _notes, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Notes')),

      ]),

    ))),

    actions: [

      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),

      FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save')),

    ],

  );

}

class _Metric extends StatelessWidget {

  const _Metric({required this.label, required this.value, required this.icon});

  final String label;

  final String value;

  final IconData icon;

  @override

  Widget build(BuildContext context) => SizedBox(

    width: MediaQuery.sizeOf(context).width < 650 ? double.infinity : 230,

    child: Card(child: Padding(

      padding: const EdgeInsets.all(18),

      child: Row(children: [

        Icon(icon, size: 30, color: const Color(0xFF0F766E)),

        const SizedBox(width: 12),

        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

          Text(label, style: const TextStyle(color: Colors.black54)),

        ]),

      ]),

    )),

  );

}
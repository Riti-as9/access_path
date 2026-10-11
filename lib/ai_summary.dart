import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

// Passed at run time with --dart-define so the key is never stored in the code
const _apiKey = String.fromEnvironment('GEMINI_KEY');
const _model =
String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.8-flash');

String _buildPrompt(Place place, Profile profile) {
  final reviews = [...place.reviews]..sort((a, b) => b.date.compareTo(a.date));
  final b = StringBuffer();
  b.writeln('You summarise community accessibility reviews for a public place.');
  b.writeln('Place: ${place.name} (${place.category}).');
  b.writeln('The reader is: ${profile.label}. Focus on what matters most to them.');
  b.writeln('Write exactly 3 short sentences for a person planning a visit: '
      '1) what works well, 2) the main barriers, 3) one practical tip. '
      'If a lift or step-free barrier was reported in the last 30 days, say so. '
      'If reviewers disagree about something, say so instead of hiding it. '
      'Plain language, no markdown, no bullet points.');
  b.writeln('Average ratings out of 5:');
  for (final k in criteria) {
    final a = place.criterionAvg(k);
    b.writeln('- ${criteriaLabels[k]}: ${a == null ? "no ratings" : a.toStringAsFixed(1)}');
  }
  b.writeln('Reviews, newest first:');
  for (final r in reviews.take(15)) {
    final days = DateTime.now().difference(r.date).inDays;
    b.writeln('- $days days ago: "${r.comment}"');
  }
  return b.toString();
}

Future<String> _callGemini(Place place, Profile profile) async {
  final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent');
  final res = await http
      .post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': _apiKey,
    },
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _buildPrompt(place, profile)}
          ]
        }
      ]
    }),
  )
      .timeout(const Duration(seconds: 8));
  if (res.statusCode != 200) {
    throw Exception('Gemini error ${res.statusCode}: ${res.body}');
  }
  final data = jsonDecode(res.body);
  final parts = data['candidates'][0]['content']['parts'] as List;
  final text = parts
      .where((p) => p['text'] != null && p['thought'] != true)
      .map((p) => p['text'] as String)
      .join(' ')
      .trim();
  if (text.isEmpty) throw Exception('Empty response');
  return text;
}

class SummaryBody extends StatefulWidget {
  final Place place;
  final String fallback; // offline summary used when AI is unavailable
  final Profile profile;
  const SummaryBody({
    super.key,
    required this.place,
    required this.fallback,
    required this.profile,
  });

  @override
  State<SummaryBody> createState() => _SummaryBodyState();
}

class _SummaryBodyState extends State<SummaryBody> {
  static final Map<String, String> _cache = {};
  String? _text;
  bool _loading = false;
  bool _isAi = false;

  String get _cacheKey =>
      '${widget.place.id}_${widget.place.reviews.length}_${widget.profile.label}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SummaryBody old) {
    super.didUpdateWidget(old);
    if (old.place.reviews.length != widget.place.reviews.length ||
        old.profile != widget.profile) {
      _load();
    }
  }

  Future<void> _load({bool force = false}) async {
    if (_apiKey.isEmpty || widget.place.reviews.isEmpty) {
      setState(() {
        _text = widget.fallback;
        _isAi = false;
        _loading = false;
      });
      return;
    }
    if (!force && _cache.containsKey(_cacheKey)) {
      setState(() {
        _text = _cache[_cacheKey];
        _isAi = true;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final t = await _callGemini(widget.place, widget.profile);
      if (!mounted) return;
      _cache[_cacheKey] = t;
      setState(() {
        _text = t;
        _isAi = true;
        _loading = false;
      });
    } catch (e) {
      debugPrint('AI summary failed: $e');
      if (!mounted) return;
      setState(() {
        _text = widget.fallback;
        _isAi = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading)
          const Row(
            children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Summarising community feedback...'),
            ],
          )
        else
          Text(_text ?? widget.fallback),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _isAi ? 'AI summary by Gemini' : 'Auto summary (offline)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (_apiKey.isNotEmpty)
              TextButton.icon(
                onPressed: _loading ? null : () => _load(force: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
          ],
        ),
      ],
    );
  }
}

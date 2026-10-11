import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';

class ReviewScreen extends StatefulWidget {
  final String placeId;
  const ReviewScreen({super.key, required this.placeId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // Only criteria the user rated are stored. A missing key means N/A.
  final Map<String, int> _ratings = {};
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    if (_ratings.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Rate at least one item')));
      return;
    }
    context.read<AppStore>().addReview(
          widget.placeId,
          Review(
            ratings: Map.of(_ratings),
            comment: _comment.text.trim(),
            date: DateTime.now(),
          ),
        );
    messenger.showSnackBar(
        const SnackBar(content: Text('Thanks! Your review was added.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final place = context.read<AppStore>().byId(widget.placeId);
    return Scaffold(
      appBar: AppBar(title: Text('Review ${place?.name ?? ''}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Rate what you experienced (1 = very poor, 5 = excellent). '
              'Choose N/A for anything you did not use.'),
          const SizedBox(height: 12),
          for (final key in criteria) _row(key),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              hintText: 'e.g. Lift to platform 2 is out of order',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text('Submit review'),
          ),
        ],
      ),
    );
  }

  Widget _row(String key) {
    final current = _ratings[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(criteriaLabels[key]!,
              style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i out of 5 for ${criteriaLabels[key]}',
                  icon: Icon(
                    (current ?? 0) >= i ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade800,
                    size: 30,
                  ),
                  onPressed: () => setState(() => _ratings[key] = i),
                ),
              ChoiceChip(
                label: const Text('N/A'),
                selected: current == null,
                onSelected: (_) => setState(() => _ratings.remove(key)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

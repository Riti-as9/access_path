import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'review_screen.dart';

const placeCategories = [
  'Library',
  'Transport',
  'Healthcare',
  'Shopping',
  'Education',
  'Outdoor',
  'Government',
  'Restaurant',
  'Other',
];

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  String _category = placeCategories.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }
    final place = Place(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: _category,
      address: _address.text.trim().isEmpty ? 'Address not added' : _address.text.trim(),
    );
    context.read<AppStore>().addPlace(place);
    // Go straight to the review screen so the new place gets its first rating
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(placeId: place.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a place')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Place name',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Address or area',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Category', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final c in placeCategories)
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.rate_review),
            label: const Text('Save and add first review'),
          ),
        ],
      ),
    );
  }
}

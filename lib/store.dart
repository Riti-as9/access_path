import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

// Filter chip key -> criterion it checks (average rating must be 4 or more)
const filterLabels = {
  'stepFree': 'Step-free 4+',
  'lift': 'Has lift 4+',
  'washroom': 'Washroom 4+',
  'seating': 'Seating 4+',
};

class AppStore extends ChangeNotifier {
  static const _placesKey = 'places_v1';
  static const _profileKey = 'profile_v1';

  List<Place> places = [];
  Profile profile = Profile.wheelchair;
  bool highContrast = false;
  double textScale = 1.0;
  String query = '';
  final Set<String> activeFilters = {};
  bool loaded = false;

  // ---------- load and save ----------
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_placesKey);
    if (raw == null) {
      places = _seedPlaces();
      await _save();
    } else {
      final list = jsonDecode(raw) as List;
      places = list
          .map((e) => Place.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final p = prefs.getInt(_profileKey);
    if (p != null && p < Profile.values.length) profile = Profile.values[p];
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _placesKey, jsonEncode(places.map((p) => p.toJson()).toList()));
    await prefs.setInt(_profileKey, profile.index);
  }

  // ---------- actions ----------
  void setProfile(Profile p) {
    profile = p;
    _save();
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void toggleFilter(String key) {
    activeFilters.contains(key)
        ? activeFilters.remove(key)
        : activeFilters.add(key);
    notifyListeners();
  }

  void setHighContrast(bool v) {
    highContrast = v;
    notifyListeners();
  }

  void setTextScale(double v) {
    textScale = v;
    notifyListeners();
  }

  void addReview(String placeId, Review review) {
    places.firstWhere((p) => p.id == placeId).reviews.add(review);
    _save();
    notifyListeners();
  }

  void addPlace(Place place) {
    places.add(place);
    _save();
    notifyListeners();
  }

  Place? byId(String id) {
    for (final p in places) {
      if (p.id == id) return p;
    }
    return null;
  }

  // Places after search and filters, best personal score first
  List<Place> get visiblePlaces {
    final q = query.trim().toLowerCase();
    final list = places.where((p) {
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.category.toLowerCase().contains(q)) {
        return false;
      }
      for (final key in activeFilters) {
        final avg = p.criterionAvg(key);
        if (avg == null || avg < 4) return false;
      }
      return true;
    }).toList();
    list.sort((a, b) =>
        (b.score(profile) ?? -1).compareTo(a.score(profile) ?? -1));
    return list;
  }

  // ---------- sample data (disclose this in the submission) ----------
  static Review _r(Map<String, int> ratings, String comment, int daysAgo) =>
      Review(
        ratings: ratings,
        comment: comment,
        date: DateTime.now().subtract(Duration(days: daysAgo)),
      );

  static List<Place> _seedPlaces() => [
    Place(
      id: 'p1',
      name: 'Central Library',
      category: 'Library',
      address: 'College Road',
      reviews: [
        _r({'stepFree': 5, 'lift': 4, 'washroom': 4, 'seating': 5, 'wayfinding': 4},
            'Ramp at the main gate and plenty of reading seats. Staff are helpful.', 40),
        _r({'stepFree': 5, 'lift': 5, 'washroom': 3, 'seating': 5, 'wayfinding': 3},
            'Lift is easy to find. Signs on the upper floors are small.', 12),
        _r({'stepFree': 4, 'lift': 4, 'seating': 5},
            'Quiet and calm. Good seating near the entrance.', 5),
      ],
    ),
    Place(
      id: 'p2',
      name: 'City Railway Station',
      category: 'Transport',
      address: 'Station Road',
      reviews: [
        _r({'stepFree': 2, 'lift': 3, 'washroom': 2, 'seating': 3, 'wayfinding': 2},
            'Platform signs are confusing. Washroom is far from the entrance.', 60),
        _r({'stepFree': 3, 'lift': 1, 'washroom': 2, 'seating': 4, 'wayfinding': 3},
            'Lift to platform 2 is out of order. Had to use the stairs.', 3),
        _r({'stepFree': 2, 'lift': 1, 'seating': 3},
            'Lift still broken. Staff offered a wheelchair assist.', 1),
      ],
    ),
    Place(
      id: 'p3',
      name: 'District Hospital',
      category: 'Healthcare',
      address: 'Hospital Chowk',
      reviews: [
        _r({'stepFree': 4, 'lift': 4, 'washroom': 4, 'seating': 3, 'wayfinding': 3},
            'Ramps everywhere and a working lift. Waiting area is crowded.', 20),
        _r({'stepFree': 5, 'lift': 3, 'washroom': 4, 'seating': 2, 'wayfinding': 4},
            'Good colour-coded floor signs. Not enough seats in OPD.', 9),
        _r({'stepFree': 4, 'washroom': 5, 'wayfinding': 4},
            'Accessible washroom is clean and wide.', 4),
        _r({'stepFree': 4, 'lift': 4, 'seating': 2},
            'Lift is slow but works. Needed more seating.', 2),
      ],
    ),
    Place(
      id: 'p4',
      name: 'Metro Mall',
      category: 'Shopping',
      address: 'Bank More',
      reviews: [
        _r({'stepFree': 5, 'lift': 5, 'washroom': 5, 'seating': 4, 'wayfinding': 5},
            'Very accessible. Wide lifts, clear directory boards, accessible toilets on every floor.', 15),
        _r({'stepFree': 5, 'lift': 4, 'washroom': 5, 'seating': 4, 'wayfinding': 4},
            'Smooth floors and benches near every escalator.', 7),
        _r({'stepFree': 5, 'lift': 5, 'seating': 5},
            'Great for a stroller. Lots of benches.', 2),
      ],
    ),
    Place(
      id: 'p5',
      name: 'Government College Campus',
      category: 'Education',
      address: 'Hirapur',
      reviews: [
        _r({'stepFree': 3, 'lift': 2, 'washroom': 3, 'seating': 4, 'wayfinding': 3},
            'Old buildings have steps. New block has a ramp.', 30),
        _r({'stepFree': 3, 'lift': 2, 'washroom': 2, 'seating': 4, 'wayfinding': 2},
            'Campus map missing at the gate. Hard to find the accessible entrance.', 14),
      ],
    ),
    Place(
      id: 'p6',
      name: 'Municipal Park',
      category: 'Outdoor',
      address: 'Lake Side',
      reviews: [
        _r({'stepFree': 4, 'washroom': 2, 'seating': 5, 'wayfinding': 3},
            'Paved paths and many benches. Public toilet is not accessible.', 25),
        _r({'stepFree': 4, 'washroom': 1, 'seating': 5, 'wayfinding': 4},
            'Lovely walk. Washroom has steps and no rail.', 6),
        _r({'stepFree': 5, 'seating': 5, 'wayfinding': 4},
            'Smooth path around the lake.', 2),
      ],
    ),
    Place(
      id: 'p7',
      name: 'Bus Terminal',
      category: 'Transport',
      address: 'GT Road',
      reviews: [
        _r({'stepFree': 2, 'washroom': 1, 'seating': 2, 'wayfinding': 2},
            'Crowded, uneven ground, and no accessible washroom.', 18),
        _r({'stepFree': 2, 'seating': 3, 'wayfinding': 1},
            'Hard to find the right bay. No tactile guides.', 8),
      ],
    ),
    Place(
      id: 'p8',
      name: 'Town Hall',
      category: 'Government',
      address: 'Civil Lines',
      reviews: [
        _r({'stepFree': 5, 'lift': 4, 'washroom': 4, 'seating': 4, 'wayfinding': 5},
            'Recently renovated. Large print signs and a helpful front desk.', 10),
        _r({'stepFree': 5, 'lift': 4, 'wayfinding': 5},
            'Easy to navigate with clear signage.', 3),
      ],
    ),
  ];
}

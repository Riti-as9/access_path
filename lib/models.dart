enum Profile { wheelchair, lowVision, elderly, sensory }

const criteria = ['stepFree', 'lift', 'washroom', 'seating', 'wayfinding'];

const criteriaLabels = {
  'stepFree': 'Step-free access',
  'lift': 'Lifts',
  'washroom': 'Accessible washroom',
  'seating': 'Seating',
  'wayfinding': 'Wayfinding',
};

extension ProfileInfo on Profile {
  String get label => switch (this) {
        Profile.wheelchair => 'Wheelchair',
        Profile.lowVision => 'Low vision',
        Profile.elderly => 'Elderly / stroller',
        Profile.sensory => 'Sensory',
      };

  Map<String, int> get weights => switch (this) {
        Profile.wheelchair => {'stepFree': 3, 'lift': 3, 'washroom': 3, 'seating': 1, 'wayfinding': 1},
        Profile.lowVision => {'stepFree': 1, 'lift': 1, 'washroom': 1, 'seating': 1, 'wayfinding': 3},
        Profile.elderly => {'stepFree': 2, 'lift': 2, 'washroom': 2, 'seating': 3, 'wayfinding': 1},
        Profile.sensory => {'stepFree': 1, 'lift': 1, 'washroom': 1, 'seating': 2, 'wayfinding': 3},
      };
}

class Review {
  final Map<String, int> ratings;
  final String comment;
  final DateTime date;

  Review({required this.ratings, required this.comment, required this.date});

  Map<String, dynamic> toJson() => {
        'ratings': ratings,
        'comment': comment,
        'date': date.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        ratings: Map<String, int>.from(j['ratings']),
        comment: j['comment'],
        date: DateTime.parse(j['date']),
      );
}

class Place {
  final String id;
  final String name;
  final String category;
  final String address;
  final List<Review> reviews;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    List<Review>? reviews,
  }) : reviews = reviews ?? [];

  double? criterionAvg(String key) {
    final values = reviews
        .where((r) => r.ratings.containsKey(key))
        .map((r) => r.ratings[key]!)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? score(Profile profile) {
    double total = 0;
    double weightSum = 0;
    for (final key in criteria) {
      final avg = criterionAvg(key);
      if (avg == null) continue;
      final w = profile.weights[key]!.toDouble();
      total += avg * w;
      weightSum += w;
    }
    if (weightSum == 0) return null;
    return (total / weightSum) * 20;
  }

  String get confidence {
    if (reviews.length < 3) return 'Low confidence';
    if (reviews.length < 10) return 'Medium confidence';
    return 'Trusted';
  }

  bool get hasRecentBarrier {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return reviews.any((r) =>
        r.date.isAfter(cutoff) &&
        ((r.ratings['lift'] ?? 5) == 1 || (r.ratings['stepFree'] ?? 5) == 1));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'address': address,
        'reviews': reviews.map((r) => r.toJson()).toList(),
      };

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'],
        name: j['name'],
        category: j['category'],
        address: j['address'],
        reviews: (j['reviews'] as List)
            .map((r) => Review.fromJson(Map<String, dynamic>.from(r)))
            .toList(),
      );
}

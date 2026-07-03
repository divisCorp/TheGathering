/// Interest taxonomy for The Gathering.
/// Hard-coded list derived from the 4 areas of the Children & Youth program
/// (Spiritual, Social, Physical, Intellectual) + common ward/stake activity tags.
/// Used for multi-select in profiles and event tagging (PR2+).
class InterestsService {
  static const List<String> spiritual = [
    'Scripture Study',
    'Fireside',
    'Temple Prep',
    'Family History',
    'Gospel Discussion',
    'Prayer & Meditation',
    'Missionary Work',
  ];

  static const List<String> social = [
    'Game Night',
    'Potluck / FHE-style',
    'Movie Night',
    'Service Project',
    'Ward Activity',
    'Book Club',
    'Singles Meetup',
    'Family-Friendly Gathering',
  ];

  static const List<String> physical = [
    'Hiking',
    'Sports / Basketball',
    'Outdoor Adventure',
    'Fitness / Walking',
    'Cycling',
    'Service Labor',
    'Camping',
  ];

  static const List<String> intellectual = [
    'Career / Skills Night',
    'Cooking / Baking',
    'Crafts & Hobbies',
    'Family History Research',
    'Book / Article Discussion',
    'Language / Music',
    'Education & Learning',
  ];

  static const List<String> other = [
    'Other',
  ];

  /// All interests flattened for UI.
  static List<String> get allInterests => [
        ...spiritual,
        ...social,
        ...physical,
        ...intellectual,
        ...other,
      ];

  /// Grouped by 4 areas for nice UI (chips, sections).
  static Map<String, List<String>> get grouped => {
        'Spiritual': spiritual,
        'Social': social,
        'Physical': physical,
        'Intellectual': intellectual,
        'Other': other,
      };

  /// Returns the primary area for a given interest tag.
  static String getAreaForInterest(String interest) {
    if (spiritual.contains(interest)) return 'Spiritual';
    if (social.contains(interest)) return 'Social';
    if (physical.contains(interest)) return 'Physical';
    if (intellectual.contains(interest)) return 'Intellectual';
    return 'Other';
  }
}

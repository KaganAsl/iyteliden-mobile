class Location {
  final int locationId;
  final String locationName;

  Location({
    required this.locationId,
    required this.locationName,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      locationId: json['locationId'],
      locationName: json['locationName'],
    );
  }

  bool isEqual(Location l) {
    return locationId == l.locationId;
  }
}
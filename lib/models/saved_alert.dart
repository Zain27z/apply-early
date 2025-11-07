class SavedAlert {
  final String query;
  final String location;
  final String timeFilter; // e.g., "past_24_hours"

  SavedAlert({
    required this.query,
    required this.location,
    required this.timeFilter,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'location': location,
        'timeFilter': timeFilter,
      };

  factory SavedAlert.fromJson(Map<String, dynamic> json) => SavedAlert(
        query: json['query'],
        location: json['location'],
        timeFilter: json['timeFilter'],
      );
}

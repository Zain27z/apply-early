class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String url;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.url,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json["id"].toString(),
      title: json["title"] ?? "Unknown",
      company: json["company_name"] ?? "Unknown Company",
      location: json["candidate_required_location"] ?? "Remote",
      url: json["url"] ?? "",
    );
  }
}

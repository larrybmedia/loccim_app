class Sermon {
  final int id;
  final String title;
  final String type;
  final String url;

  Sermon(
      {required this.id,
      required this.title,
      required this.type,
      required this.url});

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      type: json['type'] ?? 'unknown',
      url: json['url'] ?? '',
    );
  }
}

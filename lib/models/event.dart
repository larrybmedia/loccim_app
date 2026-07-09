class Event {
  final int id;
  final String title;
  final String date;
  final String location;
  final String? imageUrl; // Add this

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['image_url'], // Map it here
    );
  }
}

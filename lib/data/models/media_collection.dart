class MediaItem {
  final String title;
  final String type; // 'video', 'web', etc.
  final String? id; // e.g. youtube id
  final String? url;
  final List<int>? chapters; // e.g. [1, 21] or [1, 1]
  final String? duration;
  final String? description;
  final String? slug;

  MediaItem({
    required this.title,
    required this.type,
    this.id,
    this.url,
    this.chapters,
    this.duration,
    this.description,
    this.slug,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      title: json['title'] ?? 'Unknown Title',
      type: json['type'] ?? 'video',
      id: json['id'],
      url: json['url'],
      chapters: json['chapters'] != null ? List<int>.from(json['chapters']) : null,
      duration: json['duration'],
      description: json['description'],
      slug: json['slug'],
    );
  }
}

class MediaCollection {
  final String name;
  final String copyright;
  final String url;
  final String description;
  final Map<String, List<MediaItem>> mediaByBook; // Map of "Book Name" -> List of MediaItem

  MediaCollection({
    required this.name,
    required this.copyright,
    required this.url,
    required this.description,
    required this.mediaByBook,
  });

  factory MediaCollection.fromJson(Map<String, dynamic> json) {
    final mediaMap = <String, List<MediaItem>>{};
    
    if (json['media'] != null && json['media'] is Map) {
      final mediaRaw = json['media'] as Map<String, dynamic>;
      mediaRaw.forEach((bookName, itemsList) {
        if (itemsList is List) {
          mediaMap[bookName] = itemsList
              .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return MediaCollection(
      name: json['name'] ?? 'Unknown Collection',
      copyright: json['copyright'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      mediaByBook: mediaMap,
    );
  }
}

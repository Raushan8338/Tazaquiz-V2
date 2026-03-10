import 'dart:ui';

import 'package:intl/intl.dart';

class BlogPost {
  final int id;
  final String title;
  final String excerpt;
  final String url;
  final String author;
  final String category;
  final String? featuredImage;
  final String publishedAt;
  final String readTime;

  BlogPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.url,
    required this.author,
    required this.category,
    this.featuredImage,
    required this.publishedAt,
    required this.readTime,
  });

  factory BlogPost.fromJson(Map<String, dynamic> j) => BlogPost(
    id: j['id'] ?? 0,
    title: j['title']?.toString() ?? '',
    excerpt: j['excerpt']?.toString().trim() ?? '',
    url: j['url']?.toString() ?? '',
    author: j['author']?.toString() ?? 'TazaQuiz',
    category: j['category']?.toString() ?? 'General',
    featuredImage: j['featured_image']?.toString(),
    publishedAt: j['published_at']?.toString() ?? '',
    readTime: j['read_time']?.toString() ?? '1 min read',
  );

  String get formattedDate {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(publishedAt));
    } catch (_) {
      return publishedAt;
    }
  }

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'defence jobs':
        return const Color(0xFF1B4F72);
      case 'education':
        return const Color(0xFF1A6B3C);
      case 'results':
        return const Color(0xFF7D3C98);
      default:
        return const Color(0xFF1A5276);
    }
  }
}

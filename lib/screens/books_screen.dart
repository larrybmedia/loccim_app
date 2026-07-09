import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  late Future<List<dynamic>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = fetchBooks();
  }

  Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/books"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<dynamic>.from(data);
      }
      return [];
    } catch (e) {
      debugPrint("BOOK ERROR: $e");
      return [];
    }
  }

  Future<void> refreshBooks() async {
    setState(() {
      _booksFuture = fetchBooks();
    });
  }

  // FIXED: Robust URL concatenation
  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";

    // If it's already a full URL, return it as is
    if (path.startsWith("http://") || path.startsWith("https://")) {
      return path;
    }

    // Ensure we don't double-slash when joining
    String cleanBase = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    String cleanPath = path.startsWith('/') ? path : '/$path';

    return "$cleanBase$cleanPath";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final crossAxisCount = screenWidth > 1200
        ? 5
        : screenWidth > 800
            ? 4
            : screenWidth > 550
                ? 3
                : 2;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Books & Resources"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshBooks,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return const Center(child: Text("No books available yet."));
          }

          return RefreshIndicator(
            onRefresh: refreshBooks,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: books.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                final book = books[index];
                final imageUrl = getImageUrl(book['cover_image']?.toString());

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          // Added basic check to prevent rendering empty URLS
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.book, size: 50)
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image, size: 40),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book['title'] ?? 'Untitled',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book['author'] ?? 'Pastor Peter A. Olowoporoku',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              book['price'] ?? 'Free',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

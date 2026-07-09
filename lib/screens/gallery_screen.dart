import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final String apiUrl = "https://loccim-backend.onrender.com/api/gallery";

  Future<List<dynamic>> fetchGallery() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      debugPrint("Gallery Data:");
      debugPrint(response.body);

      return data;
    }

    throw Exception("Failed to load gallery images");
  }

  // 🔥 SAFE NORMALIZER (FIX FOR MULTIPLE IMAGES ISSUE)
  List<String> _normalizeImages(dynamic images) {
    if (images == null) return [];

    if (images is List) {
      return images.map((e) => e.toString()).toList();
    }

    if (images is String && images.isNotEmpty) {
      return images.split(','); // fallback support
    }

    return [];
  }

  void _openFullscreenMedia(
    BuildContext context,
    dynamic item,
    String title,
    bool isVideo,
  ) {
    final List<String> groupImages = _normalizeImages(item['images']);

    final String singleFileUrl = item['image_url'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isVideo)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 80,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (groupImages.isNotEmpty)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: PageView.builder(
                        itemCount: groupImages.length,
                        itemBuilder: (context, i) {
                          final imageUrl = groupImages[i];

                          return InteractiveViewer(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              else
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    singleFileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 60,
                        ),
                      );
                    },
                  ),
                ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("📸 Media Gallery Vault"),
          backgroundColor: const Color(0xFF4B0082),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.photo), text: "Pictures"),
              Tab(icon: Icon(Icons.videocam), text: "Videos"),
            ],
          ),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: fetchGallery(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("The gallery is empty."));
            }

            final allItems = snapshot.data!;

            final pictureItems = allItems
                .where((item) => item['media_type'] != 'video')
                .toList();

            final videoItems = allItems
                .where((item) => item['media_type'] == 'video')
                .toList();

            return TabBarView(
              children: [
                _buildMediaGrid(pictureItems, isVideoType: false),
                _buildMediaGrid(videoItems, isVideoType: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaGrid(
    List<dynamic> targetItems, {
    required bool isVideoType,
  }) {
    if (targetItems.isEmpty) {
      return Center(
        child: Text(
          isVideoType ? "No video clips found." : "No image pictures found.",
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: targetItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 24,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final item = targetItems[index];

        final String fileUrl = item['image_url'] ?? '';
        final String displayTitle = item['title'] ?? 'Untitled';

        final List<String> groupImages = _normalizeImages(item['images']);

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openFullscreenMedia(
              context,
              item,
              displayTitle,
              isVideoType,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: isVideoType
                      ? Container(
                          color: Colors.black,
                          child: const Icon(
                            Icons.play_circle_fill,
                            size: 40,
                            color: Colors.white70,
                          ),
                        )
                      : groupImages.isNotEmpty
                          ? Image.network(
                              groupImages[0],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            )
                          : Image.network(
                              fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    displayTitle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.imagePaths,
  });

  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          if (imagePaths.isNotEmpty)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final files = imagePaths.map(XFile.new).toList();
                Share.shareXFiles(files);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            final path = imagePaths[index];
            return _ResultTile(
              path: path,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FullScreenViewer(path: path),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.path,
    required this.onTap,
  });

  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.network(
                path,
                fit: BoxFit.cover,
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class FullScreenViewer extends StatelessWidget {
  const FullScreenViewer({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.scrim,
      appBar: AppBar(
        backgroundColor: colorScheme.scrim,
        foregroundColor: colorScheme.surface,
        title: const Text('Preview'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Share.shareXFiles([XFile(path)]);
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: kIsWeb ? Image.network(path) : Image.file(File(path)),
        ),
      ),
    );
  }
}

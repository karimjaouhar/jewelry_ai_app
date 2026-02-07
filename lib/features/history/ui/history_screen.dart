import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jewelry_ai_app/app/router.dart';
import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';
import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/jewelry_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/setting_type.dart';
import 'package:jewelry_ai_app/features/generate/ui/results_screen.dart';
import 'package:jewelry_ai_app/features/generate/state/generation_flow_controller.dart';
import 'package:jewelry_ai_app/features/history/data/history_store.dart';
import 'package:jewelry_ai_app/features/history/domain/history_entry.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryStore _store = HistoryStore();
  late Future<List<HistoryEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _store.loadEntries();
  }

  Future<void> _refresh() async {
    setState(() {
      _entriesFuture = _store.loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<HistoryEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data ?? <HistoryEntry>[];
            if (entries.isEmpty) {
              return const Center(
                child: Text('No generations yet.'),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _HistoryTile(
                    entry: entry,
                    onReuse: () {
                      context
                          .read<GenerationFlowController>()
                          .applyRequestSnapshot(entry.requestSnapshot);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRouter.root,
                        (route) => false,
                      );
                    },
                    onView: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ResultsScreen(
                            imagePaths: entry.outputPaths,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onReuse,
    required this.onView,
  });

  final HistoryEntry entry;
  final VoidCallback onReuse;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final request = entry.requestSnapshot;
    final subtitle = _buildSubtitle(request);
    final thumbnailPath = entry.thumbnailPath;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Thumbnail(path: thumbnailPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.jewelryType.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onView,
            child: const Text('View'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onReuse,
            child: const Text('Reuse'),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(GenerationRequest request) {
    final setting = request.settingType.label;
    final composition = request.compositionType.label;
    return '$setting • $composition';
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final size = 56.0;
    if (path == null || path!.isEmpty) {
      return _placeholder(size);
    }

    final image = kIsWeb
        ? Image.network(path!, fit: BoxFit.cover)
        : Image.file(File(path!), fit: BoxFit.cover);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: size,
        width: size,
        child: image,
      ),
    );
  }

  Widget _placeholder(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined),
    );
  }
}

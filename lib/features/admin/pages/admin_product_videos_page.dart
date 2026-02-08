import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product_video.dart';

class AdminProductVideosPage extends StatefulWidget {
  const AdminProductVideosPage({super.key});

  @override
  State<AdminProductVideosPage> createState() => _AdminProductVideosPageState();
}

class _AdminProductVideosPageState extends State<AdminProductVideosPage> {
  bool loading = true;
  String? error;
  List<ProductVideo> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      items = await catalogApi.listProductVideos();
    } catch (e) {
      error = "Failed to load videos: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openVideoForm({ProductVideo? video}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VideoFormSheet(video: video, onSave: load),
    );
  }

  Future<void> _deleteVideo(ProductVideo v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Video?'),
        content: Text(
          'Permanently delete "${v.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await catalogApi.adminDeleteProductVideo(v.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Video deleted')));
      load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: load, child: const Text('Retry')),
                ],
              ),
            )
          : items.isEmpty
          ? const Center(
              child: Text(
                'No videos yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade800, Colors.green.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Product Videos",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${items.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final v = items[i];
                        return ListTile(
                          leading: Image.network(
                            v.thumbnailUrl,
                            width: 80,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.video_library),
                          ),
                          title: Text(v.title),
                          subtitle: Text(
                            'Order: ${v.order} • ${v.isActive ? "Active" : "Inactive"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _openVideoForm(video: v),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteVideo(v),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openVideoForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class VideoFormSheet extends StatefulWidget {
  final ProductVideo? video;
  final VoidCallback onSave;

  const VideoFormSheet({super.key, this.video, required this.onSave});

  @override
  State<VideoFormSheet> createState() => _VideoFormSheetState();
}

class _VideoFormSheetState extends State<VideoFormSheet> {
  late TextEditingController titleCtrl;
  late TextEditingController youtubeUrlCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController orderCtrl;

  bool isActive = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.video?.title ?? '');
    youtubeUrlCtrl = TextEditingController(
      text: widget.video?.youtubeUrl ?? '',
    );
    descriptionCtrl = TextEditingController(
      text: widget.video?.description ?? '',
    );
    orderCtrl = TextEditingController(
      text: widget.video?.order.toString() ?? '0',
    );
    isActive = widget.video?.isActive ?? true;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    youtubeUrlCtrl.dispose();
    descriptionCtrl.dispose();
    orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (titleCtrl.text.isEmpty || youtubeUrlCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and YouTube URL required')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final payload = {
        'title': titleCtrl.text,
        'youtube_url': youtubeUrlCtrl.text,
        'description': descriptionCtrl.text.isEmpty
            ? null
            : descriptionCtrl.text,
        'order': int.tryParse(orderCtrl.text) ?? 0,
        'is_active': isActive,
      };

      if (widget.video == null) {
        await catalogApi.adminCreateProductVideo(payload);
      } else {
        await catalogApi.adminUpdateProductVideo(widget.video!.id, payload);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.video == null ? 'Add Video' : 'Edit Video',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Video Title *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: youtubeUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'YouTube URL *',
                hintText: 'https://youtube.com/watch?v=...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Display Order',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Active'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v ?? true),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                widget.video == null ? 'Create Video' : 'Update Video',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

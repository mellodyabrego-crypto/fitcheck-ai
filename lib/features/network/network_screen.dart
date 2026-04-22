import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../core/extensions.dart';
import '../../widgets/decorative_symbols.dart';
import '../../services/image_service.dart';
import '../../providers/user_providers.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class _Comment {
  final String username;
  final String text;
  final String timeAgo;
  _Comment({required this.username, required this.text, required this.timeAgo});
}

class _PollOption {
  final String label;
  int votes;
  _PollOption({required this.label, required this.votes});
}

class _Post {
  final String id;
  final String username;
  final String avatar;
  final String caption;
  final String? imageUrl;
  final Uint8List? imageBytes;
  int likes;
  final List<String> tags;
  final List<_Comment> comments;
  final List<_PollOption>? pollOptions;
  bool liked;
  int? userVote;

  _Post({
    required this.id,
    required this.username,
    required this.avatar,
    required this.caption,
    this.imageUrl,
    this.imageBytes,
    required this.likes,
    this.tags = const [],
    List<_Comment>? comments,
    this.pollOptions,
    this.liked = false,
    this.userVote,
  }) : comments = comments ?? [];
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _postsProvider = StateProvider<List<_Post>>((ref) => _buildSamplePosts());
final _activeHashtagProvider = StateProvider<String?>((ref) => null);
// usernameProvider is shared — imported from providers/user_providers.dart

List<_Post> _buildSamplePosts() => [
      _Post(
        id: '1',
        username: 'styledbyjaz',
        avatar: 'J',
        caption:
            'Obsessed with this coral set for summer! 🌸 Anyone else living in two-piece sets this season?',
        imageUrl:
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=500&q=80',
        likes: 247,
        tags: ['#SummerVibes', '#OOTD', '#TwoPieceSet'],
        comments: [
          _Comment(
              username: 'fashionbymia',
              text: 'Obsessed!! Where is this from?',
              timeAgo: '1h'),
          _Comment(
              username: 'kurvedbykira',
              text: 'You\'re so right, living in sets rn 🔥',
              timeAgo: '30m'),
        ],
      ),
      _Post(
        id: '2',
        username: 'fashionbymia',
        avatar: 'M',
        caption:
            'Would this bag work for both casual and office? 👜 Vote below!',
        imageUrl:
            'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=500&q=80',
        likes: 89,
        tags: ['#BagAddict', '#StyleAdvice'],
        comments: [],
        pollOptions: [
          _PollOption(label: 'Yes, perfect for both!', votes: 143),
          _PollOption(label: 'Too casual for office', votes: 38),
          _PollOption(label: 'Too formal for casual', votes: 12),
        ],
      ),
      _Post(
        id: '3',
        username: 'kurvedbykira',
        avatar: 'K',
        caption:
            'Found these heels for \$35 at Zara! They look SO much more expensive 😍',
        imageUrl:
            'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=500&q=80',
        likes: 412,
        tags: ['#ShoeLover', '#ZaraFinds', '#BudgetFashion'],
        comments: [
          _Comment(
              username: 'styledbyjaz',
              text: 'NEED THESE. Linking please!',
              timeAgo: '3h'),
        ],
      ),
      _Post(
        id: '4',
        username: 'thestylediva',
        avatar: 'T',
        caption:
            'The blazer era is NOT over. Styling tip: go one size up for that effortless oversized look ✨',
        imageUrl:
            'https://images.unsplash.com/photo-1598522325074-042db73aa4e6?w=500&q=80',
        likes: 331,
        tags: ['#BlazerSzn', '#StylingTips'],
        comments: [],
      ),
    ];

// ─── Screen ───────────────────────────────────────────────────────────────────

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _captionCtrl = TextEditingController();
  Uint8List? _newPostPhoto;
  bool _addingPoll = false;
  final List<TextEditingController> _pollOptionCtrl = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _captionCtrl.dispose();
    for (final c in _pollOptionCtrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(_postsProvider);
    final activeTag = ref.watch(_activeHashtagProvider);
    final filteredPosts = activeTag == null
        ? posts
        : posts.where((p) => p.tags.contains(activeTag)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Network'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [Tab(text: 'Feed'), Tab(text: 'Post')],
        ),
        actions: [
          if (activeTag != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(activeTag,
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.primary)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () =>
                    ref.read(_activeHashtagProvider.notifier).state = null,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
      body: WithDecorations(
        sparse: true,
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Feed ──
            filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tag,
                            size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text('No posts with $activeTag',
                            style: const TextStyle(fontSize: 16)),
                        TextButton(
                          onPressed: () => ref
                              .read(_activeHashtagProvider.notifier)
                              .state = null,
                          child: const Text('Clear filter'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 0, bottom: 80),
                    itemCount: filteredPosts.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        // Sample-community banner — tells the truth.
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Sample community — real posting + following coming soon.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final post = filteredPosts[i - 1];
                      final realIndex = posts.indexOf(post);
                      return _PostCard(
                        post: post,
                        onLike: () => _toggleLike(realIndex),
                        onComment: () => _showComments(post, realIndex),
                        onShare: () => _sharePost(post),
                        onHashtagTap: (tag) => ref
                            .read(_activeHashtagProvider.notifier)
                            .state = tag,
                        onVote: (optionIndex) =>
                            _castVote(realIndex, optionIndex),
                        onReport: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Post reported. Thank you!'),
                              behavior: SnackBarBehavior.floating),
                        ),
                      );
                    },
                  ),

            // ── New Post ──
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Share Your Look',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  // Photo
                  GestureDetector(
                    onTap: _pickPostPhoto,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _newPostPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(_newPostPhoto!,
                                  fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo,
                                    size: 44, color: AppTheme.textSecondary),
                                const SizedBox(height: 10),
                                Text('Add outfit photo / video',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 15)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: _captionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Caption',
                      hintText:
                          'Share your look, ask for advice, add #hashtags...',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Poll toggle
                  Row(
                    children: [
                      Switch(
                        value: _addingPoll,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _addingPoll = v),
                      ),
                      const Text('Add a Poll',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),

                  if (_addingPoll) ...[
                    const SizedBox(height: 8),
                    ..._pollOptionCtrl.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: e.value,
                            decoration: InputDecoration(
                              labelText: 'Option ${e.key + 1}',
                              isDense: true,
                            ),
                          ),
                        )),
                    TextButton.icon(
                      onPressed: () => setState(
                          () => _pollOptionCtrl.add(TextEditingController())),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add option'),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _submitPost,
                    icon: const Icon(Icons.send),
                    label: const Text('Share to Network'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike(int index) {
    final posts = [...ref.read(_postsProvider)];
    final p = posts[index];
    posts[index] = _Post(
      id: p.id,
      username: p.username,
      avatar: p.avatar,
      caption: p.caption,
      imageUrl: p.imageUrl,
      imageBytes: p.imageBytes,
      likes: p.liked ? p.likes - 1 : p.likes + 1,
      tags: p.tags,
      comments: p.comments,
      pollOptions: p.pollOptions,
      liked: !p.liked,
      userVote: p.userVote,
    );
    ref.read(_postsProvider.notifier).state = posts;
  }

  void _castVote(int postIndex, int optionIndex) {
    final posts = [...ref.read(_postsProvider)];
    final p = posts[postIndex];
    if (p.userVote != null) return; // already voted
    final options = p.pollOptions!
        .asMap()
        .entries
        .map((e) => _PollOption(
              label: e.value.label,
              votes: e.key == optionIndex ? e.value.votes + 1 : e.value.votes,
            ))
        .toList();
    posts[postIndex] = _Post(
      id: p.id,
      username: p.username,
      avatar: p.avatar,
      caption: p.caption,
      imageUrl: p.imageUrl,
      imageBytes: p.imageBytes,
      likes: p.likes,
      tags: p.tags,
      comments: p.comments,
      pollOptions: options,
      liked: p.liked,
      userVote: optionIndex,
    );
    ref.read(_postsProvider.notifier).state = posts;
  }

  void _showComments(_Post post, int index) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comments (${post.comments.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (post.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No comments yet — be the first!',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ...post.comments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.15),
                          child: Text(c.username[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${c.username}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              Text(c.text,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.4)),
                            ],
                          ),
                        ),
                        Text(c.timeAgo,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primary),
                    onPressed: () {
                      if (commentCtrl.text.isEmpty) return;
                      final username = ref.read(usernameProvider);
                      final uname = username.isNotEmpty ? username : 'you';
                      final posts = [...ref.read(_postsProvider)];
                      posts[index].comments.add(_Comment(
                            username: uname,
                            text: commentCtrl.text,
                            timeAgo: 'Just now',
                          ));
                      ref.read(_postsProvider.notifier).state =
                          List.from(posts);
                      setLocalState(() {});
                      commentCtrl.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sharePost(_Post post) async {
    final text = '@${post.username}: ${post.caption}\n\n${post.tags.join(' ')}';
    await Share.share(text, subject: 'Check out this outfit on Her Style Co.!');
  }

  Future<void> _pickPostPhoto() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, 'camera')),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery')),
        ]),
      ),
    );
    if (source == null) return;
    final imageService = ref.read(imageServiceProvider);
    final bytes = source == 'camera'
        ? await imageService.pickFromCamera()
        : await imageService.pickFromGallery();
    if (bytes != null) setState(() => _newPostPhoto = bytes);
  }

  void _submitPost() {
    if (_captionCtrl.text.isEmpty && _newPostPhoto == null) {
      context.showSnackBar('Add a photo or caption first!', isError: true);
      return;
    }
    final username = ref.read(usernameProvider);
    final uname = username.isNotEmpty ? username : 'you';

    List<_PollOption>? pollOptions;
    if (_addingPoll) {
      pollOptions = _pollOptionCtrl
          .where((c) => c.text.isNotEmpty)
          .map((c) => _PollOption(label: c.text, votes: 0))
          .toList();
    }

    // Extract hashtags from caption
    final tags = RegExp(r'#\w+')
        .allMatches(_captionCtrl.text)
        .map((m) => m.group(0)!)
        .toList();

    final posts = [...ref.read(_postsProvider)];
    posts.insert(
        0,
        _Post(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: uname,
          avatar: uname[0].toUpperCase(),
          caption: _captionCtrl.text,
          imageBytes: _newPostPhoto,
          likes: 0,
          tags: tags,
          pollOptions: pollOptions,
        ));
    ref.read(_postsProvider.notifier).state = posts;
    _captionCtrl.clear();
    for (final c in _pollOptionCtrl) c.clear();
    setState(() {
      _newPostPhoto = null;
      _addingPoll = false;
    });
    _tabCtrl.animateTo(0);
    context.showSnackBar('Post shared! 🎉');
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final _Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final void Function(String) onHashtagTap;
  final void Function(int) onVote;
  final VoidCallback? onReport;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onHashtagTap,
    required this.onVote,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(post.avatar,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('@${post.username}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      color: AppTheme.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (val) async {
                    if (val == 'report' && onReport != null) onReport!();
                    if (val == 'copy') {
                      final text = '${post.caption}\n${post.tags.join(' ')}';
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Caption copied to clipboard'),
                            behavior: SnackBarBehavior.floating),
                      );
                    }
                    if (val == 'share') {
                      final text =
                          '@${post.username}: ${post.caption}\n\n${post.tags.join(' ')}';
                      await Share.share(text,
                          subject: 'Outfit from Her Style Co.');
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'copy',
                        child: Row(children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Copy caption'),
                        ])),
                    PopupMenuItem(
                        value: 'share',
                        child: Row(children: [
                          Icon(Icons.share_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Share post'),
                        ])),
                    PopupMenuItem(
                        value: 'report',
                        child: Row(children: [
                          Icon(Icons.flag_outlined,
                              size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Report', style: TextStyle(color: Colors.red)),
                        ])),
                  ],
                ),
              ],
            ),
          ),

          // Image
          if (post.imageUrl != null)
            Image.network(post.imageUrl!,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    child:
                        const Center(child: Icon(Icons.image_not_supported))))
          else if (post.imageBytes != null)
            Image.memory(post.imageBytes!,
                height: 280, width: double.infinity, fit: BoxFit.cover),

          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(post.caption,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ),

          // Hashtags (tappable)
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Wrap(
                spacing: 6,
                children: post.tags
                    .map((t) => GestureDetector(
                          onTap: () => onHashtagTap(t),
                          child: Text(t,
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ),

          // Poll
          if (post.pollOptions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: _PollWidget(
                  options: post.pollOptions!,
                  userVote: post.userVote,
                  onVote: onVote),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.liked ? Icons.favorite : Icons.favorite_border,
                    color:
                        post.liked ? AppTheme.primary : AppTheme.textSecondary,
                    size: 22,
                  ),
                  onPressed: onLike,
                ),
                Text('${post.likes}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      size: 20, color: AppTheme.textSecondary),
                  onPressed: onComment,
                ),
                Text('${post.comments.length}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      size: 20, color: AppTheme.textSecondary),
                  onPressed: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Poll Widget ─────────────────────────────────────────────────────────────

class _PollWidget extends StatelessWidget {
  final List<_PollOption> options;
  final int? userVote;
  final void Function(int) onVote;

  const _PollWidget(
      {required this.options, required this.userVote, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final total = options.fold<int>(0, (s, o) => s + o.votes);
    final voted = userVote != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Poll',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        ...options.asMap().entries.map((e) {
          final pct = total > 0 ? e.value.votes / total : 0.0;
          final isChosen = userVote == e.key;
          return GestureDetector(
            onTap: voted ? null : () => onVote(e.key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: isChosen ? AppTheme.primary : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  if (voted)
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: isChosen
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(e.value.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isChosen
                                      ? FontWeight.w700
                                      : FontWeight.normal)),
                        ),
                        if (voted)
                          Text('${(pct * 100).round()}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isChosen
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (voted)
          Text('$total votes',
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

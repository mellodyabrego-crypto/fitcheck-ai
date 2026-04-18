import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';

class _ContentItem {
  final String title;
  final String channel;
  final String thumbnail;
  final String url;
  final String duration;
  final String category;
  final String views;

  const _ContentItem({
    required this.title,
    required this.channel,
    required this.thumbnail,
    required this.url,
    required this.duration,
    required this.category,
    this.views = '',
  });
}

const _content = [
  // Makeup
  _ContentItem(
    title: 'Soft Glam Makeup Tutorial',
    channel: 'NikkieTutorials',
    thumbnail: 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=soft+glam+makeup+tutorial',
    duration: '18:24', category: 'Makeup', views: '2.4M views',
  ),
  _ContentItem(
    title: 'Natural Everyday Makeup Look',
    channel: 'Jackie Aina',
    thumbnail: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=natural+everyday+makeup',
    duration: '12:05', category: 'Makeup', views: '1.8M views',
  ),
  _ContentItem(
    title: 'Viral Lip Combo Tutorial',
    channel: 'Beauty By Rach',
    thumbnail: 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=viral+lip+combo+makeup',
    duration: '8:30', category: 'Makeup', views: '980K views',
  ),
  // Styling
  _ContentItem(
    title: 'How to Style a Blazer 5 Ways',
    channel: 'Outfit Ideas',
    thumbnail: 'https://images.unsplash.com/photo-1598522325074-042db73aa4e6?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=how+to+style+blazer',
    duration: '10:12', category: 'Styling', views: '3.1M views',
  ),
  _ContentItem(
    title: 'Summer Outfits: 10 Looks',
    channel: 'Colorful Style',
    thumbnail: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=summer+outfit+ideas',
    duration: '15:48', category: 'Styling', views: '5.2M views',
  ),
  _ContentItem(
    title: 'Get Ready With Me: Date Night',
    channel: 'FashionByLari',
    thumbnail: 'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=date+night+grwm+outfit',
    duration: '20:15', category: 'Styling', views: '4.7M views',
  ),
  // Accessories
  _ContentItem(
    title: 'How to Accessorize Any Outfit',
    channel: 'Fashion By Lari',
    thumbnail: 'https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=how+to+accessorize',
    duration: '9:02', category: 'Accessories', views: '1.2M views',
  ),
  _ContentItem(
    title: 'Bag Collection 2024 + Styling Tips',
    channel: 'The Luxe List',
    thumbnail: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=bag+collection+styling',
    duration: '22:17', category: 'Accessories', views: '890K views',
  ),
  // Fashion Shows
  _ContentItem(
    title: 'Paris Fashion Week Highlights',
    channel: 'Vogue Runway',
    thumbnail: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=paris+fashion+week+highlights',
    duration: '30:44', category: 'Fashion Shows', views: '12M views',
  ),
  _ContentItem(
    title: 'Met Gala 2024 Best Looks',
    channel: 'E! News',
    thumbnail: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=met+gala+best+looks',
    duration: '25:11', category: 'Fashion Shows', views: '18M views',
  ),
  // Makeup (articles)
  _ContentItem(
    title: 'The No-Makeup Makeup Guide',
    channel: 'Vogue Beauty',
    thumbnail: 'https://images.unsplash.com/photo-1503236823255-94609f598e71?w=800&q=80',
    url: 'https://www.vogue.com/article/natural-makeup-looks',
    duration: 'Article', category: 'Makeup', views: 'Vogue.com',
  ),
  _ContentItem(
    title: 'Best Drugstore Foundations 2025',
    channel: 'Byrdie',
    thumbnail: 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=800&q=80',
    url: 'https://www.byrdie.com/best-drugstore-foundations',
    duration: 'Article', category: 'Makeup', views: 'Byrdie.com',
  ),
  // Hair
  _ContentItem(
    title: 'Quick Hairstyles for Any Outfit',
    channel: 'Naturally Sunny',
    thumbnail: 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=quick+hairstyles+tutorial',
    duration: '11:33', category: 'Hair', views: '2.9M views',
  ),
  _ContentItem(
    title: 'Curtain Bangs Tutorial',
    channel: 'Brad Mondo',
    thumbnail: 'https://images.unsplash.com/photo-1562887245-d13bde0a7e7b?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=curtain+bangs+tutorial',
    duration: '8:55', category: 'Hair', views: '6.4M views',
  ),
  _ContentItem(
    title: 'Sleek Bun Step-by-Step',
    channel: 'GlamByMonica',
    thumbnail: 'https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=sleek+bun+hairstyle+tutorial',
    duration: '6:44', category: 'Hair', views: '1.5M views',
  ),
  // Clothing Tips
  _ContentItem(
    title: '10 Styling Rules That Always Work',
    channel: 'Erin Elizabeth',
    thumbnail: 'https://images.unsplash.com/photo-1467043237213-65f2da53396f?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=outfit+styling+rules+tips',
    duration: '14:20', category: 'Clothing Tips', views: '4.3M views',
  ),
  _ContentItem(
    title: 'How to Build a Capsule Wardrobe',
    channel: 'The Style Insider',
    thumbnail: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=capsule+wardrobe+guide',
    duration: '20:08', category: 'Clothing Tips', views: '7.1M views',
  ),
  _ContentItem(
    title: 'Color Combinations That Pop',
    channel: 'StyleBySteph',
    thumbnail: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=color+combination+outfits',
    duration: '11:53', category: 'Clothing Tips', views: '2.6M views',
  ),
  // Trends
  _ContentItem(
    title: 'Spring 2025 Trend Forecast',
    channel: 'Vogue',
    thumbnail: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=spring+2025+fashion+trends',
    duration: '18:55', category: 'Trends', views: '9.8M views',
  ),
  _ContentItem(
    title: 'Quiet Luxury: The Aesthetic Explained',
    channel: 'Who What Wear',
    thumbnail: 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=quiet+luxury+fashion+aesthetic',
    duration: '12:30', category: 'Trends', views: '6.2M views',
  ),
  _ContentItem(
    title: 'Y2K is Back: How to Wear It Now',
    channel: 'TrendSetterTV',
    thumbnail: 'https://images.unsplash.com/photo-1571513722275-4b41940f54b8?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=y2k+fashion+trend+2025',
    duration: '10:44', category: 'Trends', views: '3.4M views',
  ),
  // Styling (articles)
  _ContentItem(
    title: 'How to Dress for Your Body Type',
    channel: 'Harper\'s Bazaar',
    thumbnail: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80',
    url: 'https://www.harpersbazaar.com/fashion/trends/a43000/how-to-dress-for-your-body-type/',
    duration: 'Article', category: 'Styling', views: 'HarpersBazaar.com',
  ),
  _ContentItem(
    title: 'The French Girl Style Secrets',
    channel: 'Elle',
    thumbnail: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800&q=80',
    url: 'https://www.elle.com/fashion/g28768751/french-girl-style/',
    duration: 'Article', category: 'Styling', views: 'Elle.com',
  ),
  // Skincare
  _ContentItem(
    title: 'Glass Skin Routine: Step-by-Step',
    channel: 'Hyram',
    thumbnail: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=glass+skin+routine',
    duration: '16:07', category: 'Skincare', views: '11M views',
  ),
  _ContentItem(
    title: 'Skincare Mistakes You\'re Making',
    channel: 'Dr. Dray',
    thumbnail: 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=skincare+mistakes+dermatologist',
    duration: '14:22', category: 'Skincare', views: '5.7M views',
  ),
  _ContentItem(
    title: 'SPF Guide: Which Sunscreen for You',
    channel: 'Lab Muffin Beauty',
    thumbnail: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=best+sunscreen+guide+skincare',
    duration: '9:15', category: 'Skincare', views: '3.1M views',
  ),
  // Skincare (articles)
  _ContentItem(
    title: 'The Dermatologist-Approved Routine',
    channel: 'Allure',
    thumbnail: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=800&q=80',
    url: 'https://www.allure.com/story/dermatologist-approved-skincare-routine',
    duration: 'Article', category: 'Skincare', views: 'Allure.com',
  ),
  // Trends (articles)
  _ContentItem(
    title: 'Spring 2025 Key Pieces to Own',
    channel: 'Refinery29',
    thumbnail: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800&q=80',
    url: 'https://www.refinery29.com/en-us/spring-fashion-trends',
    duration: 'Article', category: 'Trends', views: 'Refinery29.com',
  ),
  // Accessories (articles)
  _ContentItem(
    title: 'The Jewelry Trends Dominating 2025',
    channel: 'Vogue',
    thumbnail: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&q=80',
    url: 'https://www.vogue.com/article/jewelry-trends',
    duration: 'Article', category: 'Accessories', views: 'Vogue.com',
  ),
  // Fashion Shows (articles)
  _ContentItem(
    title: 'Milan Fashion Week Recap',
    channel: 'Vogue Runway',
    thumbnail: 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80',
    url: 'https://www.vogue.com/fashion-shows/milan',
    duration: 'Article', category: 'Fashion Shows', views: 'Vogue.com',
  ),
  // Athleisure
  _ContentItem(
    title: 'Chic Gym-to-Street Outfits',
    channel: 'Fit & Fabulous',
    thumbnail: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=gym+to+street+outfit+ideas',
    duration: '13:50', category: 'Athleisure', views: '2.2M views',
  ),
  _ContentItem(
    title: '5 Athleisure Looks You\'ll Love',
    channel: 'ActivateStyle',
    thumbnail: 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=athleisure+outfit+ideas',
    duration: '10:28', category: 'Athleisure', views: '1.8M views',
  ),
  // Shoes — brand-new category
  _ContentItem(
    title: 'Shoe Trends 2025: What\'s In & What\'s Out',
    channel: 'StyleByHand',
    thumbnail: 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=2025+shoe+trends+fashion',
    duration: '15:40', category: 'Shoes', views: '4.8M views',
  ),
  _ContentItem(
    title: 'Boot Guide: Every Boot You Need',
    channel: 'Who What Wear',
    thumbnail: 'https://images.unsplash.com/photo-1520639888713-7851133b1ed0?w=800&q=80',
    url: 'https://www.whowhatwear.com/boot-trends',
    duration: 'Article', category: 'Shoes', views: 'WhoWhatWear.com',
  ),
  _ContentItem(
    title: 'How to Style Statement Heels',
    channel: 'The Heel Hub',
    thumbnail: 'https://images.unsplash.com/photo-1535043934128-cf0b28d52f95?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=how+to+style+statement+heels',
    duration: '11:22', category: 'Shoes', views: '1.9M views',
  ),
  _ContentItem(
    title: 'Best Sneakers Under \$150',
    channel: 'Complex Style',
    thumbnail: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=best+sneakers+2025',
    duration: '9:58', category: 'Shoes', views: '5.6M views',
  ),
  // Jewelry — brand-new category
  _ContentItem(
    title: 'Layered Necklace Styling Guide',
    channel: 'Mejuri',
    thumbnail: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=layered+necklace+styling',
    duration: '7:32', category: 'Jewelry', views: '2.1M views',
  ),
  _ContentItem(
    title: 'Mixing Gold & Silver: The New Rules',
    channel: 'Vogue Accessories',
    thumbnail: 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800&q=80',
    url: 'https://www.vogue.com/article/mixed-metal-jewelry',
    duration: 'Article', category: 'Jewelry', views: 'Vogue.com',
  ),
  _ContentItem(
    title: 'Minimalist Jewelry Picks for Everyday',
    channel: 'Aritzia',
    thumbnail: 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=minimalist+jewelry+2025',
    duration: '6:18', category: 'Jewelry', views: '1.3M views',
  ),
  _ContentItem(
    title: 'Chunky Gold Statement Pieces',
    channel: 'The Luxe List',
    thumbnail: 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=chunky+gold+jewelry+2025',
    duration: '8:40', category: 'Jewelry', views: '2.7M views',
  ),
  // Trend forecast (more)
  _ContentItem(
    title: 'Fall 2025 Runway Trends',
    channel: 'Vogue Runway',
    thumbnail: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800&q=80',
    url: 'https://www.vogue.com/fashion-shows/fall-2025-ready-to-wear',
    duration: 'Article', category: 'Trends', views: 'Vogue.com',
  ),
  _ContentItem(
    title: 'Coquette Aesthetic: 2025 Edition',
    channel: 'Elle',
    thumbnail: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800&q=80',
    url: 'https://www.elle.com/fashion/trend-reports/a46000/coquette-fashion/',
    duration: 'Article', category: 'Trends', views: 'Elle.com',
  ),
  // Styling (more)
  _ContentItem(
    title: 'Building an Outfit in 60 Seconds',
    channel: 'Aritzia',
    thumbnail: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800&q=80',
    url: 'https://www.youtube.com/results?search_query=how+to+build+an+outfit+quick',
    duration: '7:18', category: 'Styling', views: '1.9M views',
  ),
  _ContentItem(
    title: 'The Power of Monochrome Dressing',
    channel: 'Harper\'s Bazaar',
    thumbnail: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&q=80',
    url: 'https://www.harpersbazaar.com/fashion/street-style/monochrome-outfits',
    duration: 'Article', category: 'Styling', views: 'HarpersBazaar.com',
  ),
  // Makeup (more)
  _ContentItem(
    title: 'The Clean Girl Beauty Routine',
    channel: 'Byrdie',
    thumbnail: 'https://images.unsplash.com/photo-1571908599407-cdb918ed83bf?w=800&q=80',
    url: 'https://www.byrdie.com/clean-girl-aesthetic',
    duration: 'Article', category: 'Makeup', views: 'Byrdie.com',
  ),
];

const _categories = [
  'All', 'Trends', 'Styling', 'Shoes', 'Jewelry', 'Accessories',
  'Makeup', 'Skincare', 'Hair', 'Clothing Tips', 'Fashion Shows', 'Athleisure',
];

class FashionScreen extends StatefulWidget {
  const FashionScreen({super.key});

  @override
  State<FashionScreen> createState() => _FashionScreenState();
}

class _FashionScreenState extends State<FashionScreen> {
  String _selectedCategory = 'All';
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _content
        : _content.where((c) => c.category == _selectedCategory).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        elevation: 0,
        title: const Text('Fashion & Beauty',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        children: [
          // ── Full-screen TikTok-style vertical PageView ──
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _VideoPage(item: filtered[i]),
          ),

          // ── Category bar pinned below AppBar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 4,
            left: 0, right: 0,
            child: SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _pageController.jumpToPage(0);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppTheme.primary : Colors.white30,
                        ),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single full-screen video preview page ────────────────────────────────────

class _VideoPage extends StatefulWidget {
  final _ContentItem item;
  const _VideoPage({required this.item});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  bool _liked = false;
  int  _likes = 0;

  @override
  void initState() {
    super.initState();
    _likes = 100 + (widget.item.views.hashCode % 900).abs();
  }

  Future<void> _openYouTube() async {
    final uri = Uri.parse(widget.item.url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openYouTube,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background thumbnail ──
          Image.network(
            widget.item.thumbnail,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade900,
              child: const Center(
                  child: Icon(Icons.smart_display, color: Colors.white54, size: 80)),
            ),
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                color: Colors.grey.shade900,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: AppTheme.primary,
                  ),
                ),
              );
            },
          ),

          // ── Dark gradient overlays ──
          // Top gradient (for AppBar readability)
          Positioned(
            top: 0, left: 0, right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom gradient (for info panel)
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Play icon center overlay ──
          Center(
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38, width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 40),
            ),
          ),

          // ── Right-side action buttons ──
          Positioned(
            right: 14, bottom: 120,
            child: Column(
              children: [
                _ActionBtn(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.red : Colors.white,
                  label: '${_liked ? _likes + 1 : _likes}K',
                  onTap: () => setState(() => _liked = !_liked),
                ),
                const SizedBox(height: 20),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  color: Colors.white,
                  label: 'Share',
                  onTap: () => Share.share(
                    '${widget.item.title} — ${widget.item.channel}\n${widget.item.url}',
                    subject: 'Check this out on Her Style Co.!',
                  ),
                ),
                const SizedBox(height: 20),
                _ActionBtn(
                  icon: Icons.open_in_new,
                  color: Colors.white,
                  label: 'Watch',
                  onTap: _openYouTube,
                ),
              ],
            ),
          ),

          // ── Bottom info panel ──
          Positioned(
            bottom: 28, left: 16, right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(widget.item.category,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(widget.item.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2),
                    maxLines: 2),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.smart_display, color: Colors.red, size: 16),
                    const SizedBox(width: 5),
                    Text(widget.item.channel,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    Text(widget.item.views,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white54, size: 13),
                    const SizedBox(width: 4),
                    Text(widget.item.duration,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.item.duration == 'Article'
                                ? Icons.article_outlined
                                : Icons.play_circle_outline,
                            color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.item.duration == 'Article'
                                ? 'Read Article'
                                : 'Watch on YouTube',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scroll hint ──
          Positioned(
            bottom: 6, left: 0, right: 0,
            child: Column(
              children: [
                const Icon(Icons.keyboard_arrow_up,
                    color: Colors.white38, size: 20),
                const Text('Swipe up for more',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30,
              shadows: [Shadow(color: Colors.black45, blurRadius: 6)]),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600,
                  shadows: [const Shadow(color: Colors.black45, blurRadius: 4)])),
        ],
      ),
    );
  }
}

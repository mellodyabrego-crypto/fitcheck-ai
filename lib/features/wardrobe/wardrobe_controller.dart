import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../../models/category.dart';
import '../../models/wardrobe_item.dart';
import '../../services/supabase_service.dart';

final wardrobeControllerProvider =
    AsyncNotifierProvider<WardrobeController, List<WardrobeItem>>(
  WardrobeController.new,
);

class WardrobeController extends AsyncNotifier<List<WardrobeItem>> {
  @override
  FutureOr<List<WardrobeItem>> build() async {
    if (kDemoMode) return _mockItems;

    final supabase = ref.read(supabaseServiceProvider);
    if (supabase == null) return []; // Supabase not configured — return empty
    try {
      return await supabase.getWardrobeItems();
    } catch (_) {
      return []; // auth/network/table errors — degrade gracefully
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    if (kDemoMode) {
      state = AsyncData(_mockItems);
      return;
    }
    final supabase = ref.read(supabaseServiceProvider);
    if (supabase == null) {
      state = const AsyncData([]);
      return;
    }
    state = await AsyncValue.guard(() => supabase.getWardrobeItems());
  }

  Future<void> deleteItem(WardrobeItem item) async {
    if (kDemoMode) {
      state = AsyncData(
        state.value?.where((i) => i.id != item.id).toList() ?? [],
      );
      return;
    }
    final supabase = ref.read(supabaseServiceProvider);
    if (supabase == null) return;
    await supabase.deleteImage(item.imagePath);
    if (item.thumbnailPath != null) {
      await supabase.deleteImage(item.thumbnailPath!);
    }
    await supabase.deleteWardrobeItem(item.id);
    state = AsyncData(
      state.value?.where((i) => i.id != item.id).toList() ?? [],
    );
  }
}

// ── Sample wardrobe — names and images verified to match ──────────────────────
final _mockItems = [
  // Tops
  WardrobeItem(
    id: 's1',
    userId: 'demo',
    category: ClothingCategory.tops,
    subcategory: 'Crop Top',
    color: 'Pink',
    name: 'Pink Crop Top',
    imagePath:
        'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's2',
    userId: 'demo',
    category: ClothingCategory.tops,
    subcategory: 'Blouse',
    color: 'White',
    name: 'White Silk Blouse',
    imagePath:
        'https://images.unsplash.com/photo-1594938298603-c8148c4b5ea4?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's3',
    userId: 'demo',
    category: ClothingCategory.tops,
    subcategory: 'Bustier',
    color: 'Black',
    name: 'Black Lace Bustier',
    imagePath:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  // Bottoms
  WardrobeItem(
    id: 's4',
    userId: 'demo',
    category: ClothingCategory.bottoms,
    subcategory: 'Mini Skirt',
    color: 'Pink',
    name: 'Pink Mini Skirt',
    imagePath:
        'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's5',
    userId: 'demo',
    category: ClothingCategory.bottoms,
    subcategory: 'Satin Skirt',
    color: 'Champagne',
    name: 'Champagne Satin Midi Skirt',
    imagePath:
        'https://images.unsplash.com/photo-1609505848912-b7c3b8b4beda?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's6',
    userId: 'demo',
    category: ClothingCategory.bottoms,
    subcategory: 'Jeans',
    color: 'Light Blue',
    name: 'Light Wash Flare Jeans',
    imagePath:
        'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  // Dresses
  WardrobeItem(
    id: 's7',
    userId: 'demo',
    category: ClothingCategory.dresses,
    subcategory: 'Wrap Dress',
    color: 'Floral',
    name: 'Floral Wrap Dress',
    imagePath:
        'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's8',
    userId: 'demo',
    category: ClothingCategory.dresses,
    subcategory: 'Mini Dress',
    color: 'White',
    name: 'White Mini Dress',
    imagePath:
        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's9',
    userId: 'demo',
    category: ClothingCategory.dresses,
    subcategory: 'Bodycon',
    color: 'Red',
    name: 'Red Bodycon Dress',
    imagePath:
        'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's9b',
    userId: 'demo',
    category: ClothingCategory.dresses,
    subcategory: 'Maxi',
    color: 'Emerald',
    name: 'Emerald Maxi Dress',
    imagePath:
        'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  // Shoes — image and name must match exactly
  WardrobeItem(
    id: 's10',
    userId: 'demo',
    category: ClothingCategory.shoes,
    subcategory: 'Strappy Heels',
    color: 'Nude',
    name: 'Nude Strappy Heels',
    imagePath:
        'https://images.unsplash.com/photo-1515347619252-60a4bf4fff4f?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's11',
    userId: 'demo',
    category: ClothingCategory.shoes,
    subcategory: 'Sneakers',
    color: 'White',
    name: 'White Leather Sneakers',
    imagePath:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's12',
    userId: 'demo',
    category: ClothingCategory.shoes,
    subcategory: 'Ankle Boots',
    color: 'Brown',
    name: 'Brown Ankle Boots',
    imagePath:
        'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's12b',
    userId: 'demo',
    category: ClothingCategory.shoes,
    subcategory: 'Block Heels',
    color: 'Black',
    name: 'Black Block Heels',
    imagePath:
        'https://images.unsplash.com/photo-1594938374182-a57dc2f43a4d?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  // Outerwear
  WardrobeItem(
    id: 's13',
    userId: 'demo',
    category: ClothingCategory.outerwear,
    subcategory: 'Blazer',
    color: 'Beige',
    name: 'Beige Oversized Blazer',
    imagePath:
        'https://images.unsplash.com/photo-1598522325074-042db73aa4e6?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's14',
    userId: 'demo',
    category: ClothingCategory.outerwear,
    subcategory: 'Trench Coat',
    color: 'Camel',
    name: 'Camel Trench Coat',
    imagePath:
        'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  // Accessories
  WardrobeItem(
    id: 's15',
    userId: 'demo',
    category: ClothingCategory.accessories,
    subcategory: 'Necklace',
    color: 'Gold',
    name: 'Gold Layered Chain Necklace',
    imagePath:
        'https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's16',
    userId: 'demo',
    category: ClothingCategory.accessories,
    subcategory: 'Sunglasses',
    color: 'Black',
    name: 'Black Cat-Eye Sunglasses',
    imagePath:
        'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's16b',
    userId: 'demo',
    category: ClothingCategory.accessories,
    subcategory: 'Earrings',
    color: 'Gold',
    name: 'Gold Hoop Earrings',
    imagePath:
        'https://images.unsplash.com/photo-1630019852942-f89202989a59?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  // Bags
  WardrobeItem(
    id: 's17',
    userId: 'demo',
    category: ClothingCategory.bags,
    subcategory: 'Tote',
    color: 'Tan',
    name: 'Tan Leather Tote Bag',
    imagePath:
        'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's18',
    userId: 'demo',
    category: ClothingCategory.bags,
    subcategory: 'Mini Bag',
    color: 'Black',
    name: 'Black Chain Mini Bag',
    imagePath:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 's18b',
    userId: 'demo',
    category: ClothingCategory.bags,
    subcategory: 'Clutch',
    color: 'Gold',
    name: 'Gold Evening Clutch',
    imagePath:
        'https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d?w=400&q=80',
    createdAt: DateTime.now(),
  ),
];

// Exposed so wardrobe_screen can show samples when wardrobe is empty
final sampleWardrobeItems = List<WardrobeItem>.unmodifiable(_mockItems);

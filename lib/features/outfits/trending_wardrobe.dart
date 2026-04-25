// Curated "trending" wardrobe items sourced from online retailers.
// Used as the item pool when the user picks "Create > Trending (Scratch)" —
// so the AI draws from current online fashion inspiration, not the user's
// personal wardrobe.

import '../../models/category.dart';
import '../../models/wardrobe_item.dart';

/// Items spanning the retailers the product requested: SHEIN, Mango, Uniqlo,
/// Zara, H&M, ASOS, Nordstrom, Macy's, Fashion Nova, Victoria's Secret, Next,
/// Aritzia, Free People, Revolve, Skims, Lululemon, Mejuri, Steve Madden,
/// Good American, PrettyLittleThing.
final trendingWardrobeItems = <WardrobeItem>[
  // ── Dresses ───────────────────────────────────────────────────────────────
  WardrobeItem(
    id: 't-dress-1',
    userId: 'trending',
    category: ClothingCategory.dresses,
    name: 'Floral Midi Dress',
    color: 'Coral',
    brand: 'Zara',
    imagePath:
        'https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-dress-2',
    userId: 'trending',
    category: ClothingCategory.dresses,
    name: 'Red Bodycon Midi',
    color: 'Red',
    brand: 'PrettyLittleThing',
    imagePath:
        'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-dress-3',
    userId: 'trending',
    category: ClothingCategory.dresses,
    name: 'Tiered Tennis Dress',
    color: 'White',
    brand: 'Aritzia',
    imagePath:
        'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-dress-4',
    userId: 'trending',
    category: ClothingCategory.dresses,
    name: 'Slip Midi Dress',
    color: 'Green Satin',
    brand: 'H&M',
    imagePath:
        'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=500&q=80',
    createdAt: DateTime.now(),
  ),

  // ── Tops ──────────────────────────────────────────────────────────────────
  WardrobeItem(
    id: 't-top-1',
    userId: 'trending',
    category: ClothingCategory.tops,
    name: 'Silk Blouse',
    color: 'Cream',
    brand: 'Zara',
    imagePath:
        'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-top-2',
    userId: 'trending',
    category: ClothingCategory.tops,
    name: 'Ribbed Crop Top',
    color: 'Black',
    brand: 'SHEIN',
    imagePath:
        'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-top-3',
    userId: 'trending',
    category: ClothingCategory.tops,
    name: 'Basic U-Neck Tee',
    color: 'White',
    brand: 'Uniqlo',
    imagePath:
        'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-top-4',
    userId: 'trending',
    category: ClothingCategory.tops,
    name: 'Contour Sculpt Tank',
    color: 'Beige',
    brand: 'Aritzia',
    imagePath:
        'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=500&q=80',
    createdAt: DateTime.now(),
  ),

  // ── Bottoms ───────────────────────────────────────────────────────────────
  WardrobeItem(
    id: 't-bot-1',
    userId: 'trending',
    category: ClothingCategory.bottoms,
    name: 'Wide-Leg Trousers',
    color: 'Chocolate',
    brand: 'Mango',
    imagePath:
        'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-bot-2',
    userId: 'trending',
    category: ClothingCategory.bottoms,
    name: 'Pleated Mini Skirt',
    color: 'Navy',
    brand: 'Uniqlo',
    imagePath:
        'https://images.unsplash.com/photo-1609505848912-b7c3b8b4beda?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-bot-3',
    userId: 'trending',
    category: ClothingCategory.bottoms,
    name: 'Straight-Leg Denim',
    color: 'Mid Blue',
    brand: 'Gap',
    imagePath:
        'https://images.unsplash.com/photo-1542272604-787c3835535d?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-bot-4',
    userId: 'trending',
    category: ClothingCategory.bottoms,
    name: 'Cargo Pants',
    color: 'Olive',
    brand: 'SHEIN',
    imagePath:
        'https://images.unsplash.com/photo-1594938298603-c8148c4b5ea4?w=500&q=80',
    createdAt: DateTime.now(),
  ),

  // ── Shoes ─────────────────────────────────────────────────────────────────
  WardrobeItem(
    id: 't-shoe-1',
    userId: 'trending',
    category: ClothingCategory.shoes,
    name: 'Strappy Heeled Sandals',
    color: 'Nude',
    brand: 'Steve Madden',
    imagePath:
        'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-shoe-2',
    userId: 'trending',
    category: ClothingCategory.shoes,
    name: 'Pointed-Toe Pumps',
    color: 'Black',
    brand: 'Nordstrom',
    imagePath:
        'https://images.unsplash.com/photo-1518894781321-630e638d0742?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-shoe-3',
    userId: 'trending',
    category: ClothingCategory.shoes,
    name: 'Ankle Boots',
    color: 'Tan',
    brand: 'Zara',
    imagePath:
        'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-shoe-4',
    userId: 'trending',
    category: ClothingCategory.shoes,
    name: 'Platform Sneakers',
    color: 'White',
    brand: 'Revolve',
    imagePath:
        'https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=500&q=80',
    createdAt: DateTime.now(),
  ),

  // ── Bags ──────────────────────────────────────────────────────────────────
  WardrobeItem(
    id: 't-bag-1',
    userId: 'trending',
    category: ClothingCategory.bags,
    name: 'Leather Tote',
    color: 'Camel',
    brand: 'Coach Outlet',
    imagePath:
        'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-bag-2',
    userId: 'trending',
    category: ClothingCategory.bags,
    name: 'Mini Crossbody',
    color: 'Black',
    brand: 'Mango',
    imagePath:
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-bag-3',
    userId: 'trending',
    category: ClothingCategory.bags,
    name: 'Structured Handbag',
    color: 'Beige',
    brand: 'Nordstrom',
    imagePath:
        'https://images.unsplash.com/photo-1473188588951-666fce8e7c68?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-bag-4',
    userId: 'trending',
    category: ClothingCategory.bags,
    name: 'Clutch',
    color: 'Gold',
    brand: 'ASOS',
    imagePath:
        'https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d?w=500&q=80',
    createdAt: DateTime.now(),
  ),

  // ── Accessories (jewelry etc) ─────────────────────────────────────────────
  WardrobeItem(
    id: 't-acc-1',
    userId: 'trending',
    category: ClothingCategory.accessories,
    name: 'Gold Layered Necklace',
    color: 'Gold',
    brand: 'Mejuri',
    imagePath:
        'https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-acc-2',
    userId: 'trending',
    category: ClothingCategory.accessories,
    name: 'Cat-Eye Sunglasses',
    color: 'Tortoise',
    brand: 'Fashion Nova',
    imagePath:
        'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-acc-3',
    userId: 'trending',
    category: ClothingCategory.accessories,
    name: 'Chunky Hoop Earrings',
    color: 'Gold',
    brand: 'Mejuri',
    imagePath:
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-acc-4',
    userId: 'trending',
    category: ClothingCategory.accessories,
    name: 'Silk Scarf',
    color: 'Pink',
    brand: 'Zara',
    imagePath:
        'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-acc-5',
    userId: 'trending',
    category: ClothingCategory.accessories,
    name: 'Chain Belt',
    color: 'Silver',
    brand: 'H&M',
    imagePath:
        'https://images.unsplash.com/photo-1624221249080-2fc03a82e74e?w=500&q=80',
    createdAt: DateTime.now(),
  ),

  // ── Outerwear ─────────────────────────────────────────────────────────────
  WardrobeItem(
    id: 't-out-1',
    userId: 'trending',
    category: ClothingCategory.outerwear,
    name: 'Classic Trench',
    color: 'Beige',
    brand: 'Zara',
    imagePath:
        'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-out-2',
    userId: 'trending',
    category: ClothingCategory.outerwear,
    name: 'Oversized Blazer',
    color: 'Black',
    brand: 'H&M',
    imagePath:
        'https://images.unsplash.com/photo-1598522325074-042db73aa4e6?w=500&q=80',
    createdAt: DateTime.now(),
  ),
  WardrobeItem(
    id: 't-out-3',
    userId: 'trending',
    category: ClothingCategory.outerwear,
    name: 'Denim Jacket',
    color: 'Mid Blue',
    brand: 'Levi\'s',
    imagePath:
        'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=500&q=80',
    createdAt: DateTime.now(),
  ),
];

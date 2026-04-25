import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../widgets/decorative_symbols.dart';
import '../../services/image_service.dart';
import '../../services/gemini_service.dart';
import '../../providers/user_providers.dart';

// ─── Product model ────────────────────────────────────────────────────────────

class _Product {
  final String name;
  final String brand;
  final String price;
  final String imageUrl;
  final String storeUrl;
  final String? palette;
  final String category;

  const _Product({
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.storeUrl,
    required this.category,
    this.palette,
  });
}

// ─── Product catalog (6–8 per category) ──────────────────────────────────────

const _catalog = <String, List<_Product>>{
  'Dresses': [
    _Product(
      name: 'Floral Midi Dress',
      brand: 'Zara',
      price: '\$49.90',
      imageUrl:
          'https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03?w=400&q=80',
      storeUrl: 'https://zara.com',
      category: 'Dresses',
      palette: 'Spring ✓',
    ),
    _Product(
      name: 'Navy Maxi Dress',
      brand: 'ASOS',
      price: '\$42.00',
      imageUrl:
          'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&q=80',
      storeUrl: 'https://asos.com',
      category: 'Dresses',
    ),
    _Product(
      name: 'White Mini Dress',
      brand: 'Revolve',
      price: '\$68.00',
      imageUrl:
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&q=80',
      storeUrl: 'https://revolve.com',
      category: 'Dresses',
      palette: 'Summer ✓',
    ),
    _Product(
      name: 'Red Bodycon Dress',
      brand: 'PrettyLittleThing',
      price: '\$22.00',
      imageUrl:
          'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400&q=80',
      storeUrl: 'https://prettylittlething.com',
      category: 'Dresses',
      palette: 'Winter ✓',
    ),
    _Product(
      name: 'Green Satin Slip',
      brand: 'H&M',
      price: '\$39.99',
      imageUrl:
          'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=400&q=80',
      storeUrl: 'https://hm.com',
      category: 'Dresses',
    ),
    _Product(
      name: 'Linen Shirt Dress',
      brand: 'SHEIN',
      price: '\$19.99',
      imageUrl:
          'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&q=80',
      storeUrl: 'https://shein.com',
      category: 'Dresses',
      palette: 'Summer ✓',
    ),
    _Product(
      name: 'Pleated Midi Dress',
      brand: 'Mango',
      price: '\$89.99',
      imageUrl:
          'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400&q=80',
      storeUrl: 'https://mango.com',
      category: 'Dresses',
      palette: 'Autumn ✓',
    ),
    _Product(
      name: 'Tiered Tennis Dress',
      brand: 'Aritzia',
      price: '\$128.00',
      imageUrl:
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&q=80',
      storeUrl: 'https://aritzia.com',
      category: 'Dresses',
    ),
    _Product(
      name: 'Sheer Lace Midi',
      brand: 'Next',
      price: '£58.00',
      imageUrl:
          'https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03?w=400&q=80',
      storeUrl: 'https://next.co.uk',
      category: 'Dresses',
      palette: 'Winter ✓',
    ),
  ],
  'Tops': [
    _Product(
      name: 'Ribbed Crop Top',
      brand: 'Fashion Nova',
      price: '\$24.99',
      imageUrl:
          'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=400&q=80',
      storeUrl: 'https://fashionnova.com',
      category: 'Tops',
    ),
    _Product(
      name: 'Silk Blouse',
      brand: 'Zara',
      price: '\$39.90',
      imageUrl:
          'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=400&q=80',
      storeUrl: 'https://zara.com',
      category: 'Tops',
      palette: 'Spring ✓',
    ),
    _Product(
      name: 'White Lace Top',
      brand: 'Free People',
      price: '\$58.00',
      imageUrl:
          'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400&q=80',
      storeUrl: 'https://freepeople.com',
      category: 'Tops',
      palette: 'Summer ✓',
    ),
    _Product(
      name: 'Floral Bustier',
      brand: 'ASOS',
      price: '\$28.00',
      imageUrl:
          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=400&q=80',
      storeUrl: 'https://asos.com',
      category: 'Tops',
    ),
    _Product(
      name: 'Classic Blazer Crop',
      brand: 'H&M',
      price: '\$44.99',
      imageUrl:
          'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=400&q=80',
      storeUrl: 'https://hm.com',
      category: 'Tops',
    ),
    _Product(
      name: 'Off-Shoulder Top',
      brand: 'Boohoo',
      price: '\$16.00',
      imageUrl:
          'https://images.unsplash.com/photo-1504703395950-b89145a5425b?w=400&q=80',
      storeUrl: 'https://boohoo.com',
      category: 'Tops',
      palette: 'Autumn ✓',
    ),
    _Product(
      name: 'Basic U-Neck Tee',
      brand: 'Uniqlo',
      price: '\$14.90',
      imageUrl:
          'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=400&q=80',
      storeUrl: 'https://uniqlo.com',
      category: 'Tops',
    ),
    _Product(
      name: 'Ruched Crop Top',
      brand: 'SHEIN',
      price: '\$12.00',
      imageUrl:
          'https://images.unsplash.com/photo-1594938298603-c8148c4b5ea4?w=400&q=80',
      storeUrl: 'https://shein.com',
      category: 'Tops',
      palette: 'Spring ✓',
    ),
    _Product(
      name: 'Contour Sculpt Tank',
      brand: 'Aritzia',
      price: '\$58.00',
      imageUrl:
          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=400&q=80',
      storeUrl: 'https://aritzia.com',
      category: 'Tops',
    ),
    _Product(
      name: 'Satin Camisole',
      brand: 'Victoria\'s Secret',
      price: '\$49.95',
      imageUrl:
          'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&q=80',
      storeUrl: 'https://victoriassecret.com',
      category: 'Tops',
      palette: 'Winter ✓',
    ),
    _Product(
      name: 'Cashmere Turtleneck',
      brand: 'Macy\'s',
      price: '\$79.99',
      imageUrl:
          'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=400&q=80',
      storeUrl: 'https://macys.com',
      category: 'Tops',
    ),
  ],
  'Bottoms': [
    _Product(
      name: 'Slim Jeans',
      brand: 'Levi\'s',
      price: '\$69.50',
      imageUrl:
          'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&q=80',
      storeUrl: 'https://levi.com',
      category: 'Bottoms',
    ),
    _Product(
      name: 'Black Mini Skirt',
      brand: 'Fashion Nova',
      price: '\$19.99',
      imageUrl:
          'https://images.unsplash.com/photo-1583496661160-fb5218ee78ab?w=400&q=80',
      storeUrl: 'https://fashionnova.com',
      category: 'Bottoms',
      palette: 'Winter ✓',
    ),
    _Product(
      name: 'Wide-Leg Trousers',
      brand: 'ASOS',
      price: '\$35.00',
      imageUrl:
          'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=400&q=80',
      storeUrl: 'https://asos.com',
      category: 'Bottoms',
    ),
    _Product(
      name: 'Floral Mini Skirt',
      brand: 'Zara',
      price: '\$29.90',
      imageUrl:
          'https://images.unsplash.com/photo-1577900232427-18219b9166a0?w=400&q=80',
      storeUrl: 'https://zara.com',
      category: 'Bottoms',
      palette: 'Spring ✓',
    ),
    _Product(
      name: 'Satin Midi Skirt',
      brand: 'Revolve',
      price: '\$88.00',
      imageUrl:
          'https://images.unsplash.com/photo-1609505848912-b7c3b8b4beda?w=400&q=80',
      storeUrl: 'https://revolve.com',
      category: 'Bottoms',
      palette: 'Summer ✓',
    ),
    _Product(
      name: 'High-Waist Leggings',
      brand: 'Skims',
      price: '\$62.00',
      imageUrl:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&q=80',
      storeUrl: 'https://skims.com',
      category: 'Bottoms',
    ),
    _Product(
      name: 'Seamless Pleated Skirt',
      brand: 'Uniqlo',
      price: '\$39.90',
      imageUrl:
          'https://images.unsplash.com/photo-1609505848912-b7c3b8b4beda?w=400&q=80',
      storeUrl: 'https://uniqlo.com',
      category: 'Bottoms',
      palette: 'Spring ✓',
    ),
    _Product(
      name: 'Denim Cargo Skirt',
      brand: 'Gap',
      price: '\$59.95',
      imageUrl:
          'https://images.unsplash.com/photo-1577900232427-18219b9166a0?w=400&q=80',
      storeUrl: 'https://gap.com',
      category: 'Bottoms',
    ),
    _Product(
      name: 'Y2K Low-Rise Jeans',
      brand: 'SHEIN',
      price: '\$21.00',
      imageUrl:
          'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&q=80',
      storeUrl: 'https://shein.com',
      category: 'Bottoms',
    ),
    _Product(
      name: 'Wool Tailored Trouser',
      brand: 'Mango',
      price: '\$79.99',
      imageUrl:
          'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=400&q=80',
      storeUrl: 'https://mango.com',
      category: 'Bottoms',
      palette: 'Winter ✓',
    ),
  ],
  'Shoes': [
    _Product(
      name: 'Strappy Heeled Sandals',
      brand: 'Steve Madden',
      price: '\$89.95',
      imageUrl:
          'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400&q=80',
      storeUrl: 'https://stevemadden.com',
      category: 'Shoes',
      palette: 'Autumn ✓',
    ),
    _Product(
      name: 'White Sneakers',
      brand: 'Nike',
      price: '\$95.00',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',
      storeUrl: 'https://nike.com',
      category: 'Shoes',
    ),
    _Product(
      name: 'Clear Block Heels',
      brand: 'DSW',
      price: '\$48.00',
      imageUrl:
          'https://images.unsplash.com/photo-1518894781321-630e638d0742?w=400&q=80',
      storeUrl: 'https://dsw.com',
      category: 'Shoes',
      palette: 'Summer ✓',
    ),
    _Product(
      name: 'Ankle Boots',
      brand: 'Zara',
      price: '\$79.90',
      imageUrl:
          'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=400&q=80',
      storeUrl: 'https://zara.com',
      category: 'Shoes',
      palette: 'Autumn ✓',
    ),
    _Product(
      name: 'Platform Mules',
      brand: 'Revolve',
      price: '\$110.00',
      imageUrl:
          'https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=400&q=80',
      storeUrl: 'https://revolve.com',
      category: 'Shoes',
    ),
    _Product(
      name: 'Ballet Flats',
      brand: 'H&M',
      price: '\$24.99',
      imageUrl:
          'https://images.unsplash.com/photo-1574634535671-d42e7d27ae8f?w=400&q=80',
      storeUrl: 'https://hm.com',
      category: 'Shoes',
      palette: 'Spring ✓',
    ),
  ],
  'Bags': [
    _Product(
      name: 'Leather Tote',
      brand: 'Coach Outlet',
      price: '\$149.00',
      imageUrl:
          'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&q=80',
      storeUrl: 'https://coachoutlet.com',
      category: 'Bags',
      palette: 'Autumn ✓',
    ),
    _Product(
      name: 'Mini Chain Bag',
      brand: 'Fashion Nova',
      price: '\$22.00',
      imageUrl:
          'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400&q=80',
      storeUrl: 'https://fashionnova.com',
      category: 'Bags',
    ),
    _Product(
      name: 'Woven Straw Bag',
      brand: 'Zara',
      price: '\$35.90',
      imageUrl:
          'https://images.unsplash.com/photo-1591561954557-26941169b49e?w=400&q=80',
      storeUrl: 'https://zara.com',
      category: 'Bags',
      palette: 'Spring ✓',
    ),
    _Product(
      name: 'Structured Handbag',
      brand: 'Nordstrom',
      price: '\$198.00',
      imageUrl:
          'https://images.unsplash.com/photo-1473188588951-666fce8e7c68?w=400&q=80',
      storeUrl: 'https://nordstrom.com',
      category: 'Bags',
    ),
    _Product(
      name: 'Clear Stadium Bag',
      brand: 'ASOS',
      price: '\$18.00',
      imageUrl:
          'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=400&q=80',
      storeUrl: 'https://asos.com',
      category: 'Bags',
      palette: 'Summer ✓',
    ),
    _Product(
      name: 'Quilted Crossbody',
      brand: 'Amazon Fashion',
      price: '\$26.99',
      imageUrl:
          'https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d?w=400&q=80',
      storeUrl: 'https://amazon.com/fashion',
      category: 'Bags',
    ),
  ],
  'Accessories': [
    _Product(
      name: 'Gold Layered Necklace',
      brand: 'Mejuri',
      price: '\$78.00',
      imageUrl:
          'https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=400&q=80',
      storeUrl: 'https://mejuri.com',
      category: 'Accessories',
      palette: 'Autumn ✓',
    ),
    _Product(
      name: 'Cat-Eye Sunglasses',
      brand: 'Fashion Nova',
      price: '\$14.99',
      imageUrl:
          'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=400&q=80',
      storeUrl: 'https://fashionnova.com',
      category: 'Accessories',
    ),
    _Product(
      name: 'Wide Brim Hat',
      brand: 'ASOS',
      price: '\$26.00',
      imageUrl:
          'https://images.unsplash.com/photo-1533827432537-1f1e88b807e7?w=400&q=80',
      storeUrl: 'https://asos.com',
      category: 'Accessories',
      palette: 'Spring ✓',
    ),
    _Product(
      name: 'Pearl Hair Clips',
      brand: 'Claire\'s',
      price: '\$8.99',
      imageUrl:
          'https://images.unsplash.com/photo-1603974372039-adc49044b6bd?w=400&q=80',
      storeUrl: 'https://claires.com',
      category: 'Accessories',
    ),
    _Product(
      name: 'Silk Scarf',
      brand: 'Zara',
      price: '\$22.90',
      imageUrl:
          'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=400&q=80',
      storeUrl: 'https://zara.com',
      category: 'Accessories',
      palette: 'Summer ✓',
    ),
    _Product(
      name: 'Chain Belt',
      brand: 'H&M',
      price: '\$14.99',
      imageUrl:
          'https://images.unsplash.com/photo-1624221249080-2fc03a82e74e?w=400&q=80',
      storeUrl: 'https://hm.com',
      category: 'Accessories',
    ),
  ],
  'Outerwear': [
    _Product(
      name: 'Classic Trench Coat',
      brand: 'Zara',
      price: '\$99.90',
      imageUrl:
          'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400&q=80',
      storeUrl: 'https://zara.com',
      category: 'Outerwear',
      palette: 'Autumn ✓',
    ),
    _Product(
      name: 'Oversized Blazer',
      brand: 'H&M',
      price: '\$59.99',
      imageUrl:
          'https://images.unsplash.com/photo-1598522325074-042db73aa4e6?w=400&q=80',
      storeUrl: 'https://hm.com',
      category: 'Outerwear',
      palette: 'Winter ✓',
    ),
    _Product(
      name: 'Puffer Jacket',
      brand: 'ASOS',
      price: '\$75.00',
      imageUrl:
          'https://images.unsplash.com/photo-1548624313-0396c75e4b1a?w=400&q=80',
      storeUrl: 'https://asos.com',
      category: 'Outerwear',
    ),
    _Product(
      name: 'Shearling Coat',
      brand: 'Nordstrom',
      price: '\$189.00',
      imageUrl:
          'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=400&q=80',
      storeUrl: 'https://nordstrom.com',
      category: 'Outerwear',
    ),
    _Product(
      name: 'Denim Jacket',
      brand: 'Levi\'s',
      price: '\$89.50',
      imageUrl:
          'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=400&q=80',
      storeUrl: 'https://levi.com',
      category: 'Outerwear',
    ),
    _Product(
      name: 'Boho Fringe Jacket',
      brand: 'Free People',
      price: '\$128.00',
      imageUrl:
          'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&q=80',
      storeUrl: 'https://freepeople.com',
      category: 'Outerwear',
      palette: 'Autumn ✓',
    ),
  ],
  'Activewear': [
    _Product(
      name: 'High-Waist Leggings',
      brand: 'Lululemon',
      price: '\$98.00',
      imageUrl:
          'https://images.unsplash.com/photo-1518310383802-640c2de311b2?w=400&q=80',
      storeUrl: 'https://lululemon.com',
      category: 'Activewear',
    ),
    _Product(
      name: 'Sports Bra Set',
      brand: 'Gymshark',
      price: '\$44.00',
      imageUrl:
          'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=400&q=80',
      storeUrl: 'https://gymshark.com',
      category: 'Activewear',
    ),
    _Product(
      name: 'Yoga Shorts',
      brand: 'Nike',
      price: '\$40.00',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',
      storeUrl: 'https://nike.com',
      category: 'Activewear',
    ),
    _Product(
      name: 'Lounge Set',
      brand: 'Skims',
      price: '\$88.00',
      imageUrl:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&q=80',
      storeUrl: 'https://skims.com',
      category: 'Activewear',
    ),
    _Product(
      name: 'Track Jacket',
      brand: 'Adidas',
      price: '\$65.00',
      imageUrl:
          'https://images.unsplash.com/photo-1556906781-9a412961a28c?w=400&q=80',
      storeUrl: 'https://adidas.com',
      category: 'Activewear',
    ),
    _Product(
      name: 'Sculpt Jumpsuit',
      brand: 'Good American',
      price: '\$129.00',
      imageUrl:
          'https://images.unsplash.com/photo-1483721310020-03333e577078?w=400&q=80',
      storeUrl: 'https://goodamerican.com',
      category: 'Activewear',
    ),
    _Product(
      name: 'Oversized Sweatsuit Set',
      brand: 'Fashion Nova',
      price: '\$34.99',
      imageUrl:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&q=80',
      storeUrl: 'https://fashionnova.com',
      category: 'Activewear',
      palette: 'Autumn ✓',
    ),
  ],
};

const _categoryIcons = {
  'Dresses': Icons.dry_cleaning,
  'Tops': Icons.checkroom,
  'Bottoms': Icons.accessibility_new,
  'Shoes': Icons.ice_skating,
  'Bags': Icons.shopping_bag,
  'Accessories': Icons.watch,
  'Outerwear': Icons.umbrella,
  'Activewear': Icons.fitness_center,
};

const _categoryColors = {
  'Dresses': AppTheme.primary,
  'Tops': AppTheme.primaryDeep,
  'Bottoms': AppTheme.accent,
  'Shoes': AppTheme.primary,
  'Bags': AppTheme.accent,
  'Accessories': AppTheme.primaryDeep,
  'Outerwear': AppTheme.accent,
  'Activewear': AppTheme.primary,
};

// ─── Store directory (searched when user types a store name) ──────────────────

const _storeDirectory = <String, String>{
  // Core fast fashion
  'Zara': 'https://zara.com',
  'H&M': 'https://hm.com',
  'SHEIN': 'https://shein.com',
  'Fashion Nova': 'https://fashionnova.com',
  'ASOS': 'https://asos.com',
  'Uniqlo': 'https://uniqlo.com',
  'Mango': 'https://mango.com',
  'Gap': 'https://gap.com',
  'Old Navy': 'https://oldnavy.gap.com',
  'Banana Republic': 'https://bananarepublic.gap.com',
  'PrettyLittleThing': 'https://prettylittlething.com',
  'Boohoo': 'https://boohoo.com',
  'Forever 21': 'https://forever21.com',
  // Luxury / mid-tier department stores
  'Nordstrom': 'https://nordstrom.com',
  'Macy\'s': 'https://macys.com',
  'Bloomingdale\'s': 'https://bloomingdales.com',
  'Saks Fifth Avenue': 'https://saksfifthavenue.com',
  'Net-a-Porter': 'https://net-a-porter.com',
  'Revolve': 'https://revolve.com',
  'Free People': 'https://freepeople.com',
  'Anthropologie': 'https://anthropologie.com',
  'Urban Outfitters': 'https://urbanoutfitters.com',
  'Aritzia': 'https://aritzia.com',
  'Express': 'https://express.com',
  // Lifestyle / intimates / swim
  'Victoria\'s Secret': 'https://victoriassecret.com',
  'Skims': 'https://skims.com',
  'Good American': 'https://goodamerican.com',
  // Activewear
  'Nike': 'https://nike.com',
  'Adidas': 'https://adidas.com',
  'Lululemon': 'https://lululemon.com',
  'Gymshark': 'https://gymshark.com',
  // Shoes + accessories
  'Steve Madden': 'https://stevemadden.com',
  'DSW': 'https://dsw.com',
  'Mejuri': 'https://mejuri.com',
  'Windsor': 'https://windsorstore.com',
  // Resale + marketplaces
  'Poshmark': 'https://poshmark.com',
  'Mercari': 'https://mercari.com',
  'Depop': 'https://depop.com',
  'ThredUp': 'https://thredup.com',
  'Grailed': 'https://grailed.com',
  'Shop': 'https://shop.app',
  'Threads': 'https://threads.com',
  'Karma': 'https://karmanow.com',
  // International
  'Next (UK)': 'https://next.co.uk',
  'Myntra': 'https://myntra.com',
  'Meesho': 'https://meesho.com',
  'ZOZOTOWN': 'https://zozo.jp',
  // Marketplaces
  'Target': 'https://target.com',
  'Amazon Fashion': 'https://amazon.com/fashion',
  'Walmart': 'https://walmart.com/cp/womens-clothing/1045804',
  'Coach Outlet': 'https://coachoutlet.com',
  'Levi\'s': 'https://levi.com',
};

// ─── Providers ────────────────────────────────────────────────────────────────

final _selectedShopCategoryProvider = StateProvider<String?>((ref) => null);
final _shopSearchQueryProvider = StateProvider<String>((ref) => '');
final _shopLookupPhotoProvider = StateProvider<Uint8List?>((ref) => null);

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchCtrl = TextEditingController();
  bool _analyzingPhoto = false;
  String? _photoAnalysis;

  /// In-memory cache of palette-check results keyed by a stable hash of the
  /// uploaded image. Avoids repeat Gemini calls (and 429s) for the same photo.
  static final Map<String, String> _paletteCache = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Simple content-hash for cache key (SHA-1 is overkill; we just need same-photo detection).
  String _hashBytes(Uint8List bytes) {
    int h = 17;
    for (var i = 0; i < bytes.length; i += 257) {
      h = 0x7FFFFFFF & (h * 31 + bytes[i]);
    }
    return '${bytes.length}-$h';
  }

  @override
  Widget build(BuildContext context) {
    final selectedCat = ref.watch(_selectedShopCategoryProvider);
    final photo = ref.watch(_shopLookupPhotoProvider);
    final query = ref.watch(_shopSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedCat ?? 'Shop'),
        leading: selectedCat != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref
                    .read(_selectedShopCategoryProvider.notifier)
                    .state = null,
              )
            : null,
      ),
      body: WithDecorations(
        sparse: true,
        child: Column(
          children: [
            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search items, brands, or online stores...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref
                                      .read(
                                        _shopSearchQueryProvider.notifier,
                                      )
                                      .state = '';
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) {
                        ref.read(_shopSearchQueryProvider.notifier).state = v;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickLookupPhoto,
                      tooltip: 'Palette-check by photo',
                    ),
                  ),
                ],
              ),
            ),

            // ── Photo palette banner ──
            if (photo != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        photo,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _analyzingPhoto
                          ? const Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Checking palette match...'),
                              ],
                            )
                          : Text(
                              _photoAnalysis ?? 'Analyzing...',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        ref.read(_shopLookupPhotoProvider.notifier).state =
                            null;
                        setState(() => _photoAnalysis = null);
                      },
                    ),
                  ],
                ),
              ),

            // ── Main content ──
            Expanded(
              child: selectedCat != null
                  ? _ProductGrid(category: selectedCat, searchQuery: query)
                  : query.isNotEmpty
                      ? _ProductGrid(category: null, searchQuery: query)
                      : _ShopHomePage(
                          onCategoryTap: (cat) => ref
                              .read(_selectedShopCategoryProvider.notifier)
                              .state = cat,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLookupPhoto() async {
    final imageService = ref.read(imageServiceProvider);
    final bytes = await imageService.pickWithSheet(context);
    if (bytes == null) return;

    ref.read(_shopLookupPhotoProvider.notifier).state = bytes;

    // Cache hit — reuse prior result for the same photo, skip the Gemini call.
    final cacheKey = _hashBytes(bytes);
    if (_paletteCache.containsKey(cacheKey)) {
      setState(() {
        _analyzingPhoto = false;
        _photoAnalysis = _paletteCache[cacheKey];
      });
      return;
    }

    setState(() {
      _analyzingPhoto = true;
      _photoAnalysis = null;
    });

    try {
      final gemini = ref.read(geminiServiceProvider);
      String analysis;

      if (!gemini.isGeminiConfigured || kDemoMode) {
        analysis =
            '⚠️ AI palette check unavailable (no API key configured). You can still browse picks curated for your season in your profile.';
      } else {
        final b64 = base64Encode(bytes);
        // Proxy call via Supabase Edge Function — Gemini key never touches the browser.
        final proxyUrl =
            '${AppConstants.supabaseUrl.replaceAll(RegExp(r'/+$'), '')}/functions/v1/gemini-proxy';
        final body = jsonEncode({
          'model': 'gemini-2.5-flash',
          'contents': [
            {
              'parts': [
                {
                  'text': 'Analyze this clothing item photo. Tell me: '
                      '1) What type of clothing it is (top, bottom, dress, etc.), '
                      '2) The dominant colors and whether they are warm (autumn/spring) or cool (summer/winter) toned, '
                      '3) Which of the 4 seasonal color palettes (Spring, Summer, Autumn, Winter) it best fits, '
                      '4) A short style note. '
                      'Reply in 2–3 short sentences, starting with ✅ or ⚠️ depending on whether it fits a warm or cool palette. '
                      'Be friendly and direct.',
                },
                {
                  'inlineData': {'mimeType': 'image/jpeg', 'data': b64},
                },
              ],
            },
          ],
        });
        // Retry with exponential backoff on 429 / 5xx (up to 3 attempts, 1s + 2s + 4s).
        http.Response? resp;
        int attempt = 0;
        const maxAttempts = 3;
        while (attempt < maxAttempts) {
          resp = await http.post(
            Uri.parse(proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
              'apikey': AppConstants.supabaseAnonKey,
            },
            body: body,
          );
          final status = resp.statusCode;
          final transient = status == 429 || (status >= 500 && status < 600);
          if (!transient) break;
          attempt++;
          if (attempt >= maxAttempts) break;
          await Future.delayed(Duration(seconds: 1 << attempt)); // 2s, 4s
        }

        if (resp != null && resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          analysis = (json['candidates']?[0]?['content']?['parts']?[0]?['text']
                      as String?)
                  ?.trim() ??
              '⚠️ The AI responded but I couldn\'t read the result. Try another photo.';
        } else if (resp?.statusCode == 429) {
          analysis =
              '⚠️ The AI is rate-limited right now. Your Gemini API key may be over quota — rotate it at aistudio.google.com.';
        } else {
          analysis =
              '⚠️ AI palette check failed (HTTP ${resp?.statusCode ?? "unknown"}). Try again in a moment.';
        }
      }

      // Cache the result (success or honest-error string). Avoids hammering the
      // API if the same photo is re-uploaded.
      _paletteCache[cacheKey] = analysis;

      if (mounted) {
        setState(() {
          _analyzingPhoto = false;
          _photoAnalysis = analysis;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzingPhoto = false;
          _photoAnalysis =
              '⚠️ Couldn\'t analyze photo: ${e.toString().split('\n').first}. Check your connection and try again.';
        });
      }
    }
  }
}

// ─── Shop Home (category icons + featured products) ──────────────────────────

class _ShopHomePage extends ConsumerWidget {
  final void Function(String) onCategoryTap;
  const _ShopHomePage({required this.onCategoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(colorSeasonProvider); // e.g. 'Autumn'
    final favColors = ref.watch(
      favoriteColorsProvider,
    ); // e.g. ['Coral', 'Hot Pink']

    // Palette Picks:
    //  1. Items tagged with the user's season come first.
    //  2. Items whose name/color mentions one of the user's favorite colors next.
    //  3. Everything else with any palette tag fills in.
    //  4. Show many more items (was 6 → 20+).
    final all = _catalog.values.expand((p) => p).toList();
    final seasonMatches = season == null
        ? <_Product>[]
        : all
            .where(
              (p) =>
                  p.palette?.toLowerCase().contains(season.toLowerCase()) ??
                  false,
            )
            .toList();
    bool mentionsFavColor(_Product p) {
      if (favColors.isEmpty) return false;
      final haystack = '${p.name} ${p.palette ?? ""}'.toLowerCase();
      return favColors.any((c) => haystack.contains(c.toLowerCase()));
    }

    final favColorMatches = all
        .where((p) => !seasonMatches.contains(p) && mentionsFavColor(p))
        .toList();
    final otherPaletteItems = all
        .where(
          (p) =>
              p.palette != null &&
              !seasonMatches.contains(p) &&
              !favColorMatches.contains(p),
        )
        .toList();
    final featured = [
      ...seasonMatches,
      ...favColorMatches,
      ...otherPaletteItems,
    ].take(24).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: const Text(
              'Shop by Category',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((_, i) {
              final cat = _catalog.keys.elementAt(i);
              final icon = _categoryIcons[cat] ?? Icons.checkroom;
              final color = _categoryColors[cat] ?? AppTheme.primary;
              return GestureDetector(
                onTap: () => onCategoryTap(cat),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cat,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }, childCount: _catalog.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: const Text(
              'Palette Picks For You',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ProductCard(product: featured[i]),
              childCount: featured.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Product Grid (category or search) ───────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final String? category;
  final String searchQuery;

  const _ProductGrid({required this.category, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    List<_Product> products;
    List<MapEntry<String, String>> matchedStores = [];

    final q = searchQuery.toLowerCase();
    if (category != null) {
      final catProducts = _catalog[category] ?? [];
      // Filter within category if search query is active
      products = q.isEmpty
          ? catProducts
          : catProducts
              .where(
                (p) =>
                    p.name.toLowerCase().contains(q) ||
                    p.brand.toLowerCase().contains(q),
              )
              .toList();
    } else if (q.isNotEmpty) {
      products = _catalog.values
          .expand((p) => p)
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.brand.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q),
          )
          .toList();

      // Also search store directory
      matchedStores = _storeDirectory.entries
          .where((e) => e.key.toLowerCase().contains(q))
          .toList();
    } else {
      products = [];
    }

    if (products.isEmpty &&
        matchedStores.isEmpty &&
        (q.isNotEmpty || category != null)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No results found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (q.isNotEmpty) ...[
              const SizedBox(height: 16),
              _WebSearchTile(query: q),
            ],
          ],
        ),
      );
    }

    // When no query and no category, show nothing (home page handles this)
    if (products.isEmpty && matchedStores.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // ── Store results ──
        if (matchedStores.isNotEmpty) ...[
          const Text(
            'Online Stores',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...matchedStores.map(
            (e) => _StoreListTile(name: e.key, url: e.value),
          ),
          const SizedBox(height: 16),
          if (products.isNotEmpty)
            const Text(
              'Products',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 8),
        ],
        // ── Product results ──
        if (products.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => _ProductCard(product: products[i]),
          ),
        // ── Web search button (always shown when there's a query) ──
        if (q.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Search Online',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _WebSearchTile(query: q),
          _WebSearchTile(
            query: '$q site:amazon.com',
            label: 'Search Amazon',
            icon: Icons.shopping_cart_outlined,
          ),
          _WebSearchTile(
            query: '$q fashion',
            label: 'Google Shopping',
            icon: Icons.storefront_outlined,
          ),
        ],
      ],
    );
  }
}

// ─── Web Search Tile ──────────────────────────────────────────────────────────

class _WebSearchTile extends StatelessWidget {
  final String query;
  final String? label;
  final IconData? icon;
  const _WebSearchTile({required this.query, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? 'Search "${query}" on the web';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon ?? Icons.language, color: AppTheme.accent, size: 20),
        ),
        title: Text(
          displayLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.open_in_new,
          color: AppTheme.accent,
          size: 16,
        ),
        onTap: () async {
          final encoded = Uri.encodeComponent(query);
          final uri = Uri.parse('https://www.google.com/search?q=$encoded');
          if (await canLaunchUrl(uri))
            launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}

// ─── Store List Tile ──────────────────────────────────────────────────────────

class _StoreListTile extends StatelessWidget {
  final String name;
  final String url;
  const _StoreListTile({required this.name, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.store, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          url,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.open_in_new,
          color: AppTheme.primary,
          size: 16,
        ),
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri))
            launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final _Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(product.storeUrl);
        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ──
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        child: const Icon(
                          Icons.checkroom,
                          color: AppTheme.primary,
                          size: 40,
                        ),
                      ),
                      loadingBuilder: (ctx, child, prog) {
                        if (prog == null) return child;
                        return Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                    // Product name banner at top of image
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Palette badge
                    if (product.palette != null)
                      Positioned(
                        bottom: 28,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.palette!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Shop now overlay on bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new,
                                color: Colors.white70,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Shop Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Product info ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.brand,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';
import '../../models/outfit.dart';
import '../../models/wardrobe_item.dart';
import '../../providers/photo_providers.dart';
import '../../services/gemini_service.dart';
import '../../services/supabase_service.dart';
import '../../services/weather_service.dart';
import '../wardrobe/wardrobe_controller.dart';
import 'trending_wardrobe.dart';

// ─── In-memory outfit store (session-persistent) ──────────────────────────────

class LocalOutfitStore {
  final Outfit outfit;
  final List<WardrobeItem> items; // actual items selected for this outfit

  const LocalOutfitStore({required this.outfit, required this.items});
}

final localOutfitStoreProvider =
    StateProvider<List<LocalOutfitStore>>((ref) => []);

// Helper to get an outfit + its items by id from the local store
LocalOutfitStore? findLocalOutfit(List<LocalOutfitStore> store, String id) {
  try {
    return store.firstWhere((s) => s.outfit.id == id);
  } catch (_) {
    return null;
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

final outfitControllerProvider =
    AsyncNotifierProvider<OutfitController, void>(OutfitController.new);

class OutfitController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Outfit> generateOutfit(
    String occasion, {
    String? colorSeason,
    bool fromScratch = false,
  }) async {
    final gemini = ref.read(geminiServiceProvider);

    // Pick the source item pool based on mode:
    //   - fromScratch (Trending) → use the curated online-retailer pool
    //     (`trendingWardrobeItems`) so outfits pull from online fashion refs,
    //     not the user's uploaded wardrobe.
    //   - !fromScratch (My Wardrobe) → use the user's real wardrobe; fall back
    //     to samples only if the wardrobe is completely empty.
    final realItems = ref.read(wardrobeControllerProvider).value ?? [];
    final sourceItems = fromScratch
        ? trendingWardrobeItems
        : (realItems.isNotEmpty ? realItems : sampleWardrobeItems);

    // Get today's weather for context
    final weatherMap = ref.read(weatherProvider).value;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todayWeather = weatherMap?[todayKey];
    final weatherStr = todayWeather != null
        ? '${todayWeather.description}, ${todayWeather.tempMin.round()}–${todayWeather.tempMax.round()}°F'
        : null;

    // Build item payload for Gemini. Always send the source pool — whether
    // that's the user's wardrobe or the curated trending pool — so Gemini can
    // select real item ids that we can render afterwards.
    final itemPayload = sourceItems
        .map((i) => {
              'id': i.id,
              'name': i.name ?? i.category.label,
              'color': i.color ?? 'unknown',
              'category': i.category.name,
              if (i.brand != null) 'brand': i.brand!,
            })
        .toList();

    // Call Gemini
    final result = await gemini.generateOutfit(
      occasion: occasion,
      colorSeason: colorSeason,
      weather: weatherStr,
      items: itemPayload,
      fromScratch: fromScratch,
    );

    // Build full reasoning string
    final fullReasoning = [
      result.reasoning,
      if (result.trendNote.isNotEmpty) '✨ Trend: ${result.trendNote}',
      if (result.suggestions.isNotEmpty) '💡 Tip: ${result.suggestions}',
      if (weatherStr != null) '🌤️ Weather: $weatherStr',
    ].join('\n\n');

    // Match selected item IDs to wardrobe items.
    // Guarantee a COMPLETE outfit (≥4 items, all slots covered). If Gemini
    // returned too few IDs (or none that matched), fall back to the default picker.
    List<WardrobeItem> selectedItems = result.selectedItemIds.isNotEmpty
        ? sourceItems
            .where((i) => result.selectedItemIds.contains(i.id))
            .toList()
        : [];

    if (selectedItems.length < 4) {
      selectedItems = _pickDefaultItems(sourceItems, occasion, colorSeason);
    }

    // Top up missing categories so preview has top + bottom/dress + shoes + bag + accessory
    selectedItems = _topUpMissingSlots(selectedItems, sourceItems, occasion);

    final outfitId = 'local-${const Uuid().v4()}';

    // Use the real authenticated user id when available. Empty string if not
    // logged in — the outfit still lives in the local store, it just won't
    // sync to Supabase.
    final supabase = ref.read(supabaseServiceProvider);
    final realUserId = kDemoMode ? 'demo' : (supabase?.currentUser?.id ?? '');

    final outfit = Outfit(
      id: outfitId,
      userId: realUserId,
      occasion: occasion,
      reasoning: fullReasoning,
      createdAt: DateTime.now(),
    );

    // Persist in local store
    ref.read(localOutfitStoreProvider.notifier).update(
          (list) =>
              [...list, LocalOutfitStore(outfit: outfit, items: selectedItems)],
        );

    // Auto-save to My Photos (AI-generated card with first item's image)
    final firstWithUrl = selectedItems.cast<WardrobeItem?>().firstWhere(
        (i) => i?.imagePath.startsWith('http') ?? false,
        orElse: () => null);
    final photo = RatedPhoto(
      networkUrl: firstWithUrl?.imagePath,
      isAiGenerated: true,
      score: 0, // No fabricated score — UI hides the badge for unscored photos
      feedback: 'AI-styled ${occasion.toUpperCase()} look, ready to wear.',
      improvements: '',
      outfitLabel: occasion.toUpperCase(),
    );
    ref.read(ratedPhotosProvider.notifier).update((list) => [...list, photo]);

    // Also try to save to Supabase if available (fire and forget)
    if (!kDemoMode) {
      _trySaveToSupabase(outfit, selectedItems);
    }

    return outfit;
  }

  /// Ensure an outfit has the essentials: (top+bottom OR dress) + shoes + bag + accessory.
  /// If a slot is missing, pull the first matching item from sourceItems.
  List<WardrobeItem> _topUpMissingSlots(List<WardrobeItem> current,
      List<WardrobeItem> sourceItems, String occasion) {
    final result = List<WardrobeItem>.from(current);
    final has = <String, bool>{
      for (final c in [
        'tops',
        'bottoms',
        'dresses',
        'shoes',
        'bags',
        'accessories',
        'outerwear'
      ])
        c: result.any((i) => i.category.name == c),
    };

    WardrobeItem? firstFrom(String cat) =>
        sourceItems.cast<WardrobeItem?>().firstWhere(
              (i) => i?.category.name == cat,
              orElse: () => null,
            );

    // Top/dress is required
    if (!has['tops']! && !has['dresses']!) {
      final d = firstFrom('dresses') ?? firstFrom('tops');
      if (d != null) result.add(d);
    }
    // Bottom if top exists and no dress
    if (has['tops']! && !has['bottoms']! && !has['dresses']!) {
      final b = firstFrom('bottoms');
      if (b != null) result.add(b);
    }
    // Shoes always
    if (!has['shoes']!) {
      final s = firstFrom('shoes');
      if (s != null) result.add(s);
    }
    // Bag always
    if (!has['bags']!) {
      final b = firstFrom('bags');
      if (b != null) result.add(b);
    }
    // At least one accessory
    if (!has['accessories']!) {
      final a = firstFrom('accessories');
      if (a != null) result.add(a);
    }

    return result;
  }

  /// Pick a sensible default outfit when Gemini returns no item IDs.
  /// Always returns 5–6 items: top/dress + bottom + shoes + bag + 1-2 accessories.
  List<WardrobeItem> _pickDefaultItems(
      List<WardrobeItem> items, String occasion, String? colorSeason) {
    final tops = items.where((i) => i.category.name == 'tops').toList();
    final bottoms = items.where((i) => i.category.name == 'bottoms').toList();
    final shoes = items.where((i) => i.category.name == 'shoes').toList();
    final dresses = items.where((i) => i.category.name == 'dresses').toList();
    final bags = items.where((i) => i.category.name == 'bags').toList();
    final accessories =
        items.where((i) => i.category.name == 'accessories').toList();
    final outerwear =
        items.where((i) => i.category.name == 'outerwear').toList();

    final result = <WardrobeItem>[];

    // Base: dress for dressy occasions, otherwise top + bottom
    final isDressy =
        occasion == 'date_night' || occasion == 'formal' || occasion == 'party';
    if (isDressy && dresses.isNotEmpty) {
      result.add(dresses.first);
    } else {
      if (tops.isNotEmpty) result.add(tops.first);
      if (bottoms.isNotEmpty) result.add(bottoms.first);
    }

    // Shoes (always)
    if (shoes.isNotEmpty) result.add(shoes.first);

    // Bag (always)
    if (bags.isNotEmpty) result.add(bags.first);

    // Accessories — add up to 2
    for (var i = 0; i < accessories.length && result.length < 6; i++) {
      result.add(accessories[i]);
    }

    // Outerwear for cold-weather occasions
    if (outerwear.isNotEmpty &&
        result.length < 6 &&
        (occasion == 'work' || occasion == 'casual')) {
      result.add(outerwear.first);
    }

    // If still only 1 item (empty wardrobe edge case), try to add from any category
    if (result.length <= 1) {
      for (final item in items) {
        if (!result.contains(item)) result.add(item);
        if (result.length >= 4) break;
      }
    }

    return result;
  }

  Future<void> _trySaveToSupabase(
      Outfit outfit, List<WardrobeItem> items) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      if (supabase == null) return; // no backend — local store suffices
      final outfitData = outfit.toJson();
      final outfitItems = items
          .map((i) => {
                'id': const Uuid().v4(),
                'wardrobe_item_id': i.id,
                'slot': i.category.name,
              })
          .toList();
      await supabase.createOutfit(outfitData, outfitItems);
    } catch (_) {
      // Silent fail — local store already has the outfit
    }
  }
}

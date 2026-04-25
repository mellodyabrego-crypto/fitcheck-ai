import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class OutfitCollection {
  final String id;
  final String name;
  final List<String> outfitIds;
  final DateTime createdAt;

  const OutfitCollection({
    required this.id,
    required this.name,
    required this.outfitIds,
    required this.createdAt,
  });

  OutfitCollection copyWith({String? name, List<String>? outfitIds}) =>
      OutfitCollection(
        id: id,
        name: name ?? this.name,
        outfitIds: outfitIds ?? this.outfitIds,
        createdAt: createdAt,
      );
}

class CollectionsNotifier extends StateNotifier<List<OutfitCollection>> {
  CollectionsNotifier() : super(const []);

  OutfitCollection create(String name) {
    final collection = OutfitCollection(
      id: const Uuid().v4(),
      name: name,
      outfitIds: const [],
      createdAt: DateTime.now(),
    );
    state = [...state, collection];
    return collection;
  }

  void rename(String id, String newName) {
    state = [for (final c in state) c.id == id ? c.copyWith(name: newName) : c];
  }

  void delete(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void addOutfit(String collectionId, String outfitId) {
    state = [
      for (final c in state)
        if (c.id == collectionId && !c.outfitIds.contains(outfitId))
          c.copyWith(outfitIds: [...c.outfitIds, outfitId])
        else
          c,
    ];
  }

  void removeOutfit(String collectionId, String outfitId) {
    state = [
      for (final c in state)
        if (c.id == collectionId)
          c.copyWith(
            outfitIds: c.outfitIds.where((id) => id != outfitId).toList(),
          )
        else
          c,
    ];
  }
}

final collectionsProvider =
    StateNotifierProvider<CollectionsNotifier, List<OutfitCollection>>(
  (ref) => CollectionsNotifier(),
);

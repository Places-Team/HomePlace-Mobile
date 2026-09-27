import 'dart:math';

import 'package:flutter/foundation.dart';

import 'idea_store.dart';

final class IdeaController extends ChangeNotifier {
  IdeaController(this.store);

  final IdeaStore store;
  IdeaCollection collection = const IdeaCollection();
  bool loading = true;
  bool busy = false;
  Object? error;

  List<HomeIdea> get ideas => collection.ideas;
  List<String> get categories => [
    ...builtInIdeaCategories,
    ...collection.customCategories.map((category) => 'custom:$category'),
  ];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      collection = await store.read();
    } catch (failure) {
      error = failure;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> add(String text, String category) async {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > 500 || !categories.contains(category)) {
      return false;
    }
    final idea = HomeIdea(
      id: _newId(),
      text: clean,
      category: category,
      createdAt: DateTime.now(),
    );
    return _save(
      IdeaCollection(
        ideas: [idea, ...ideas],
        customCategories: collection.customCategories,
      ),
    );
  }

  Future<bool> update(HomeIdea idea, String text, String category) async {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > 500 || !categories.contains(category)) {
      return false;
    }
    return _save(
      IdeaCollection(
        ideas: [
          for (final item in ideas)
            if (item.id == idea.id)
              item.copyWith(text: clean, category: category)
            else
              item,
        ],
        customCategories: collection.customCategories,
      ),
    );
  }

  Future<bool> duplicate(HomeIdea idea) => _save(
    IdeaCollection(
      ideas: [
        idea.copyWith(id: _newId(), createdAt: DateTime.now()),
        ...ideas,
      ],
      customCategories: collection.customCategories,
    ),
  );

  Future<bool> remove(HomeIdea idea) => _save(
    IdeaCollection(
      ideas: ideas.where((item) => item.id != idea.id).toList(),
      customCategories: collection.customCategories,
    ),
  );

  Future<bool> addCategory(String name) async {
    final clean = name.trim();
    if (clean.isEmpty ||
        clean.length > 40 ||
        categories.any(
          (category) => category.toLowerCase() == 'custom:$clean'.toLowerCase(),
        ) ||
        builtInIdeaCategories.contains(clean.toLowerCase())) {
      return false;
    }
    return _save(
      IdeaCollection(
        ideas: ideas,
        customCategories: [...collection.customCategories, clean],
      ),
    );
  }

  Future<bool> _save(IdeaCollection next) async {
    if (loading || busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await store.write(next);
      collection = next;
      return true;
    } catch (failure) {
      error = failure;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
      '${Random.secure().nextInt(1 << 32).toRadixString(36)}';
}

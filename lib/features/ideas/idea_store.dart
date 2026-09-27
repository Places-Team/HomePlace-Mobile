import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/storage/connection_profile.dart';

const builtInIdeaCategories = ['inbox', 'home', 'work', 'media', 'later'];

final class HomeIdea {
  const HomeIdea({
    required this.id,
    required this.text,
    required this.category,
    required this.createdAt,
    this.note = '',
    this.pinned = false,
    this.completed = false,
    this.archived = false,
  });

  final String id;
  final String text;
  final String category;
  final DateTime createdAt;
  final String note;
  final bool pinned;
  final bool completed;
  final bool archived;

  HomeIdea copyWith({
    String? id,
    String? text,
    String? category,
    DateTime? createdAt,
    String? note,
    bool? pinned,
    bool? completed,
    bool? archived,
  }) => HomeIdea(
    id: id ?? this.id,
    text: text ?? this.text,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    note: note ?? this.note,
    pinned: pinned ?? this.pinned,
    completed: completed ?? this.completed,
    archived: archived ?? this.archived,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
    'pinned': pinned,
    'completed': completed,
    'archived': archived,
  };

  static HomeIdea? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final text = value['text'];
    final category = value['category'];
    final note = value['note'] ?? '';
    final pinned = value['pinned'] ?? false;
    final completed = value['completed'] ?? false;
    final archived = value['archived'] ?? false;
    final createdAt = DateTime.tryParse(value['createdAt']?.toString() ?? '');
    if (id is! String ||
        id.isEmpty ||
        text is! String ||
        text.trim().isEmpty ||
        text.length > 500 ||
        category is! String ||
        category.isEmpty ||
        category.length > 47 ||
        note is! String ||
        note.length > 2000 ||
        pinned is! bool ||
        completed is! bool ||
        archived is! bool ||
        createdAt == null) {
      return null;
    }
    return HomeIdea(
      id: id,
      text: text,
      category: category,
      createdAt: createdAt,
      note: note,
      pinned: pinned,
      completed: completed,
      archived: archived,
    );
  }
}

final class IdeaCollection {
  const IdeaCollection({
    this.ideas = const [],
    this.customCategories = const [],
  });

  final List<HomeIdea> ideas;
  final List<String> customCategories;

  Map<String, Object?> toJson() => {
    'version': 1,
    'ideas': ideas.map((idea) => idea.toJson()).toList(),
    'customCategories': customCategories,
  };

  static IdeaCollection fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) {
      return const IdeaCollection();
    }
    final rawIdeas = value['ideas'];
    final rawCategories = value['customCategories'];
    final customCategories = <String>[];
    if (rawCategories is List) {
      for (final category in rawCategories.whereType<String>()) {
        if (category.isEmpty ||
            category.length > 40 ||
            builtInIdeaCategories.contains(category.toLowerCase()) ||
            customCategories.any(
              (existing) => existing.toLowerCase() == category.toLowerCase(),
            )) {
          continue;
        }
        customCategories.add(category);
      }
    }
    final allowedCategories = {
      ...builtInIdeaCategories,
      ...customCategories.map((category) => 'custom:$category'),
    };
    final ideas = <HomeIdea>[];
    final seenIds = <String>{};
    if (rawIdeas is List) {
      for (final raw in rawIdeas) {
        final idea = HomeIdea.fromJson(raw);
        if (idea == null || !seenIds.add(idea.id)) continue;
        ideas.add(
          allowedCategories.contains(idea.category)
              ? idea
              : idea.copyWith(category: 'inbox'),
        );
      }
    }
    return IdeaCollection(ideas: ideas, customCategories: customCategories);
  }
}

abstract interface class IdeaStore {
  Future<IdeaCollection> read();
  Future<void> write(IdeaCollection collection);
}

final class SecureIdeaStore implements IdeaStore {
  SecureIdeaStore(ConnectionProfile profile, {FlutterSecureStorage? storage})
    : _key = keyFor(profile),
      _storage = storage ?? const FlutterSecureStorage();

  final String _key;
  final FlutterSecureStorage _storage;

  static String keyFor(ConnectionProfile profile) {
    final scope = sha256
        .convert(utf8.encode('${profile.serverId}:${profile.deviceId}'))
        .toString();
    return 'homeplace.ideas.v1.$scope';
  }

  @override
  Future<IdeaCollection> read() async {
    final raw = await _storage.read(
      key: _key,
      aOptions: const AndroidOptions(),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    if (raw == null) return const IdeaCollection();
    try {
      return IdeaCollection.fromJson(jsonDecode(raw));
    } on FormatException {
      return const IdeaCollection();
    }
  }

  @override
  Future<void> write(IdeaCollection collection) => _storage.write(
    key: _key,
    value: jsonEncode(collection.toJson()),
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}

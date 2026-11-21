import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

/// Stores the whole library as one JSON document. Works on Android, web,
/// and desktop. For very large libraries, move to one file per book later.
class BookRepository {
  static const _key = 'urdu_book_studio.books.v1';

  Future<List<Book>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAll(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(books.map((b) => b.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}

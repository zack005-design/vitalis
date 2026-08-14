import 'dart:convert';
import 'package:flutter/services.dart';

class IndbFoodItem {
  final String name;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String servingDescription;
  final String category;

  const IndbFoodItem({
    required this.name,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.servingDescription,
    required this.category,
  });

  factory IndbFoodItem.fromJson(Map<String, dynamic> json) {
    return IndbFoodItem(
      name: json['name'] as String,
      calories: (json['calories'] as num).toInt(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      servingDescription: json['serving_description'] as String? ?? '1 serving',
      category: json['category'] as String? ?? 'General',
    );
  }
}

class IndbFoodLoader {
  List<IndbFoodItem>? _cachedItems;

  Future<List<IndbFoodItem>> loadLocalDataset() async {
    if (_cachedItems != null) return _cachedItems!;

    try {
      final jsonString = await rootBundle.loadString('assets/data/indb_kerala_foods.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _cachedItems = jsonList.map((e) => IndbFoodItem.fromJson(e)).toList();
      return _cachedItems!;
    } catch (_) {
      return [];
    }
  }

  Future<List<IndbFoodItem>> searchLocalDataset(String query) async {
    final items = await loadLocalDataset();
    if (query.trim().isEmpty) return items;

    final queryWords = query.toLowerCase().trim().split(RegExp(r'\s+'));
    return items.where((item) {
      final targetStr = '${item.name} ${item.category}'.toLowerCase();
      return queryWords.every((word) => targetStr.contains(word));
    }).toList();
  }
}

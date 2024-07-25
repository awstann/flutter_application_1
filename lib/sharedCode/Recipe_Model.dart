
import 'package:cloud_firestore/cloud_firestore.dart';


class Recipe {
  String id;
  String name;
  String imageUrl;
  String description; // Add the description field
  String cookingTime;
  List<String> ingredients;
  List<String> cookingSteps;
  String source;
  double rating;
  String type;
  String category; // Add the category field
  List<String>? missingIngredients;
  String? backgroundStory;
  List<String>? famousCities;
  String? occasion;
  String? by; // Add the by field

  Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description, // Add the description field
    required this.cookingTime,
    required this.ingredients,
    required this.cookingSteps,
    required this.source,
    required this.rating,
    required this.type,
    required this.category, // Add the category field
    this.missingIngredients,
    this.backgroundStory,
    this.famousCities,
    this.occasion,
    this.by, // Add the by field
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description, // Add the description field
      'cookingTime': cookingTime,
      'ingredients': ingredients,
      'cookingSteps': cookingSteps,
      'source': source,
      'rating': rating,
      'type': type,
      'category': category, // Add the category field
      'missingIngredients': missingIngredients ?? [],
      'backgroundStory': backgroundStory,
      'famousCities': famousCities,
      'occasion': occasion,
      'by': by, // Add the by field
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description, // Add the description field
      'cookingTime': cookingTime,
      'ingredients': ingredients,
      'cookingSteps': cookingSteps,
      'source': source,
      'rating': rating,
      'type': type,
      'category': category, // Add the category field
      'missingIngredients': missingIngredients ?? [],
      'backgroundStory': backgroundStory,
      'famousCities': famousCities,
      'occasion': occasion,
      'by': by, // Add the by field
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> data) {
    return Recipe(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '', // Add the description field
      cookingTime: data['cookingTime'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      cookingSteps: List<String>.from(data['cookingSteps'] ?? []),
      source: data['source'] ?? '',
      rating: (data['rating'] as num).toDouble(),
      type: data['type'] ?? '',
      category: data['category'] ?? '', // Add the category field
      missingIngredients: List<String>.from(data['missingIngredients'] ?? []),
      backgroundStory: data['backgroundStory'],
      famousCities: List<String>.from(data['famousCities'] ?? []),
      occasion: data['occasion'],
      by: data['by'], // Add the by field
    );
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<String> ingredients = List<String>.from(data['ingredients'] ?? []);

    List<String> cookingSteps;
    if (data['cookingSteps'] != null) {
      if (data['cookingSteps'] is List<String>) {
        cookingSteps = List<String>.from(data['cookingSteps']);
      } else {
        cookingSteps = (data['cookingSteps'] as List)
            .map((item) => item.toString())
            .toList();
      }
    } else {
      cookingSteps = [];
    }

    double rating =
        data['rating'] != null ? (data['rating'] as num).toDouble() : 0.0;

    List<String>? missingIngredients;
    if (data['missingIngredients'] != null) {
      missingIngredients = List<String>.from(data['missingIngredients']);
    }

    String? backgroundStory = data['backgroundStory'];

    List<String>? famousCities;
    if (data['famousCities'] != null) {
      if (data['famousCities'] is String) {
        famousCities = List<String>.from(
            data['famousCities'].split(',').map((item) => item.trim()));
      } else {
        famousCities = List<String>.from(data['famousCities']);
      }
    }

    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '', // Add the description field
      cookingTime: data['cookingTime'] ?? '',
      ingredients: ingredients,
      cookingSteps: cookingSteps,
      source: data['source']?.isNotEmpty == true ? data['source'] : 'CookUp',
      rating: rating,
      type: data['type'] ?? '',
      category: data['category'] ?? '', // Add the category field
      missingIngredients: missingIngredients,
      backgroundStory: backgroundStory,
      famousCities: famousCities,
      occasion: data['occasion'],
      by: data['by'], // Add the by field
    );
  }
}

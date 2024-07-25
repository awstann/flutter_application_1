import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeGenerator extends StatefulWidget {
  @override
  _RecipeGeneratorState createState() => _RecipeGeneratorState();
}

class _RecipeGeneratorState extends State<RecipeGenerator> {
  final TextEditingController _ingredientsController = TextEditingController();
  String _recipe = '';

  Future<void> _generateRecipe() async {
    final ingredients = _ingredientsController.text;
    if (ingredients.isEmpty) {
      setState(() {
        _recipe = 'Please enter some ingredients.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('open api link'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer apikey',
        },
        body: jsonEncode({
          'prompt': 'Create a recipe using the following ingredients: $ingredients',
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _recipe = data['choices'][0]['text'].trim();
        });
      } else {
        setState(() {
          _recipe = 'Failed to generate recipe. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _recipe = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ingredientsController,
              decoration: InputDecoration(
                labelText: 'Enter ingredients',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _generateRecipe,
              child: Text('Generate Recipe'),
            ),
            SizedBox(height: 16.0),
            Text(_recipe),
          ],
        ),
      ),
    );
  }
}
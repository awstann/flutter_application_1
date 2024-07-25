import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Main_Screens/CookUpCommunity.dart';
import 'package:flutter_application_1/Main_Screens/HomePage.dart';
import 'package:flutter_application_1/Main_Screens/KitchenManagement.dart';
import 'package:flutter_application_1/Main_Screens/UserProfilePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/sharedCode/Recipe_Model.dart';
import 'RecipeDetailsPage.dart';
//this is a page for showing your saved recipes//
class SavedRecipes extends StatefulWidget {
  @override
  _SavedRecipesState createState() => _SavedRecipesState();
}

class _SavedRecipesState extends State<SavedRecipes> {
  List<Recipe> recipes = [];
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    fetchSavedRecipes();
  }

  Future<void> fetchSavedRecipes() async {
    final savedRecipesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedRecipes')
        .get();

    if (mounted) {
      setState(() {
        recipes = savedRecipesSnapshot.docs
            .map((doc) => Recipe.fromFirestore(doc))
            .toList();
      });
    }
  }

  void removeRecipe(int index) {
    final recipeId = recipes[index].id;
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedRecipes')
        .doc(recipeId)
        .delete();

    setState(() {
      recipes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 3;

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CookUpCommunity()));
          break;
        case 1:
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => KitchenManagementPage()));
          break;
        case 2:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => HomePage()));
          break;
        case 3:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SavedRecipes()));
          break;
        case 4:
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => Userprofilepage()));
          break;
      }
    }

    return Scaffold(
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Colors.orange,
        items: [
          TabItem(icon: Icons.person, title: 'Chefs'),
          TabItem(icon: Icons.kitchen, title: 'Kitchen'),
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.bookmark, title: 'Saved'),
          TabItem(icon: Icons.account_circle, title: 'Profile'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange.shade300,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Saved Recipes',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.75,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return RecipeCard(
            recipe: recipe,
            onRemove: () => removeRecipe(index),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailsPage(
                    recipe: recipe,
                    userId: userId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  RecipeCard(
      {required this.recipe, required this.onRemove, required this.onTap});

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool isBookmarked = true;

  void _showRemoveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove Recipe'),
          content: Text(
              'Are you sure you want to remove this recipe from your saved recipes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.onRemove();
                Navigator.of(context).pop();
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    ).then((_) {
      if (!isBookmarked) {
        setState(() {
          isBookmarked = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
              child: Image.network(
                widget.recipe.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 6, 2, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.recipe.name,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.orange : Colors.grey,
                    ),
                    onPressed: () {
                      if (isBookmarked) {
                        _showRemoveDialog();
                      } else {
                        setState(() {
                          isBookmarked = !isBookmarked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(widget.recipe.source,
                  style: TextStyle(color: Colors.grey)),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16.0,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 1.5),
                      Text(
                        '${widget.recipe.cookingTime}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow, size: 16.0),
                      SizedBox(width: 1.5),
                      Text(
                        '${widget.recipe.rating}',
                        style: TextStyle(color: Colors.grey),
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

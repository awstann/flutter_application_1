import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Main_Screens/EditRecipePage.dart';
import 'package:flutter_application_1/sharedCode/Recipe_Model.dart';
import 'RecipeDetailsPage.dart';

class UserRecipesPage extends StatefulWidget {
  @override
  _UserRecipesPageState createState() => _UserRecipesPageState();
}

class _UserRecipesPageState extends State<UserRecipesPage> {
  List<Recipe> recipes = [];
  bool fromScheduler = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['fromScheduler'] != null) {
      fromScheduler = args['fromScheduler'];
    }
  }

  Future<void> _fetchRecipes() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('recipes')
          .get();

      setState(() {
        recipes = snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
      });
    }
  }

  void _deleteRecipe(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Recipe'),
        content: Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                String userId = user.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('recipes')
                    .doc(recipes[index].id)
                    .delete();

                setState(() {
                  recipes.removeAt(index);
                });
              }
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _editRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipePage(recipe: recipe),
      ),
    ).then((_) => _fetchRecipes());
  }

  void _selectRecipe(Recipe recipe) {
    if (fromScheduler) {
      Navigator.pop(context, recipe);
    } else {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(
              recipe: recipe,
              userId: user.uid,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange.shade300,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'My Recipes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.4 / 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return GestureDetector(
              onTap: () => _selectRecipe(recipe),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 120,
                                color: Colors.grey,
                                child: Icon(Icons.broken_image, color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            recipe.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey),
                              SizedBox(width: 1.4),
                              Text(
                                recipe.cookingTime,
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              Spacer(),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 22, color: Colors.orange),
                                    onPressed: () => _editRecipe(recipe), // Navigate to EditRecipePage
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 22, color: Colors.red),
                                    onPressed: () => _deleteRecipe(index),
                                  ),
                                ],
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
          },
        ),
      ),
    );
  }
}















/* class RecipeDetailsPage extends StatefulWidget {
  final Recipe recipe;

  RecipeDetailsPage({required this.recipe});

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  bool isBookmarked = false;
  int selectedIndex = 0;
  List<String> ingredients = ['2 cups flour', '1 cup sugar', '2 eggs', '2 potatos', '2 eggs'];
  List<String> cookingSteps = [
    'Mix ingredients together in a bowl.',
    'Preheat oven to 350°F.',
    'Pour batter into greased pan.',
    'Bake for 30 minutes or until golden brown.'
  ];
  List<Map<String, dynamic>> reviews = [{'user': 'User1', 'rating': 5, 'review': 'Great recipe!'}];
  int userRating = 0;
  String userReview = '';
  List<bool> ingredientAdded = List<bool>.filled(4, false);
  List<String> notes = [];
  TextEditingController noteController = TextEditingController();
  int? editingIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  widget.recipe.imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: Icon(Icons.arrow_back, color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.recipe.name,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.orange),
                        onPressed: () {
                          setState(() {
                            isBookmarked = !isBookmarked;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Recipe Source',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(widget.recipe.cookingTime),
                      SizedBox(width: 16),
                      Icon(Icons.star, color: Colors.yellow[500]),
                      SizedBox(width: 4),
                      Text('4.5'),
                    ],
                  ),
                  SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSectionTab('Ingredients', 0),
                        _buildSectionTab('Cooking Steps', 1),
                        _buildSectionTab('My Notes', 2),
                        _buildSectionTab('Rate & Review', 3),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSectionContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTab(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selectedIndex == index ? Colors.orange : Colors.grey,
              ),
            ),
            SizedBox(height: 4),
            if (selectedIndex == index)
              Container(
                height: 2,
                width: 40,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (selectedIndex) {
      case 0:
        return _buildIngredientsSection();
      case 1:
        return _buildCookingStepsSection();
      case 2:
        return _buildNotesSection();
      case 3:
        return _buildReviewSection();
      default:
        return Container();
    }
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(ingredients.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ingredients[index], style: TextStyle(fontSize: 16)),
              IconButton(
                icon: Icon(
                  ingredientAdded[index] ? Icons.check_box : Icons.check_box_outline_blank,
                  color: Colors.orange,
                ),
                onPressed: () {
                  setState(() {
                    ingredientAdded[index] = !ingredientAdded[index];
                  });
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCookingStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(cookingSteps.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.orange,
                child: Text(
                  (index + 1).toString(),
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(cookingSteps[index], style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(notes[index]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      setState(() {
                        noteController.text = notes[index];
                        editingIndex = index;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        notes.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        TextField(
          controller: noteController,
          decoration: InputDecoration(
            hintText: 'Add a note',
            suffixIcon: IconButton(
              icon: Icon(Icons.send, color: Colors.orange),
              onPressed: () {
                setState(() {
                  if (editingIndex != null) {
                    notes[editingIndex!] = noteController.text;
                    editingIndex = null;
                  } else {
                    notes.add(noteController.text);
                  }
                  noteController.clear();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return ListTile(
              title: Text(review['user']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < review['rating'] ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                      );
                    }),
                  ),
                  Text(review['review']),
                ],
              ),
            );
          },
        ),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < userRating ? Icons.star : Icons.star_border,
                color: Colors.orange,
              ),
              onPressed: () {
                setState(() {
                  userRating = index + 1;
                });
              },
            );
          }),
        ),
        TextField(
          onChanged: (value) {
            setState(() {
              userReview = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Write a review',
            suffixIcon: IconButton(
              icon: Icon(Icons.send, color: Colors.orange),
              onPressed: () {
                setState(() {
                  reviews.add({'user': 'User', 'rating': userRating, 'review': userReview});
                  userRating = 0;
                  userReview = '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }
} */
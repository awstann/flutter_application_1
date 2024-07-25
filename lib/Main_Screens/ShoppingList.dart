import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IngredientShoppingList extends StatefulWidget {
  final String userId; // Add this to get the logged-in user ID

  IngredientShoppingList({required this.userId});

  @override
  _IngredientShoppingListState createState() => _IngredientShoppingListState();
}

class _IngredientShoppingListState extends State<IngredientShoppingList> {
  List<Recipe> recipes = [];
  List<Ingredient> manualIngredients = [];

  final TextEditingController ingredientNameController =
      TextEditingController();
  final TextEditingController ingredientQuantityController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchShoppingList();
    _fetchManualIngredients();
  }

  Future<void> _fetchShoppingList() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('shoppingList')
        .get();

    List<Recipe> fetchedRecipes = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      List<String> ingredients = List<String>.from(data['ingredients']);
      return Recipe(
        id: doc.id,
        name: data['recipeName'] ?? 'No name',
        imageUrl: data['recipeImageUrl'] ?? '',
        cookingTime: data['recipeCookingTime'] ?? 'No time',
        rating: data['recipeRating'] ?? 0.0,
        missingIngredients: ingredients
            .map((ingredient) => Ingredient(name: ingredient, quantity: 1))
            .toList(),
      );
    }).toList();

    setState(() {
      recipes = fetchedRecipes;
    });
  }

  Future<void> _fetchManualIngredients() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('manualIngredients')
        .get();

    List<Ingredient> fetchedIngredients = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Ingredient(
        name: data['name'],
        quantity: data['quantity'],
      );
    }).toList();

    setState(() {
      manualIngredients = fetchedIngredients;
    });
  }

  void _addManualIngredient() async {
    final newIngredient = Ingredient(
      name: ingredientNameController.text,
      quantity: int.tryParse(ingredientQuantityController.text) ?? 1,
    );

    setState(() {
      manualIngredients.add(newIngredient);
      ingredientNameController.clear();
      ingredientQuantityController.clear();
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('manualIngredients')
        .add({
      'name': newIngredient.name,
      'quantity': newIngredient.quantity,
    });
  }

  void _deleteRecipe(Recipe recipe) async {
    setState(() {
      recipes.remove(recipe);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('shoppingList')
        .doc(recipe.id)
        .delete();
  }

  void _increaseManualQuantity(Ingredient ingredient) async {
    setState(() {
      ingredient.quantity++;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('manualIngredients')
        .where('name', isEqualTo: ingredient.name)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('manualIngredients')
          .doc(snapshot.docs.first.id)
          .update({'quantity': ingredient.quantity});
    }
  }

  void _decreaseManualQuantity(Ingredient ingredient) async {
    if (ingredient.quantity > 1) {
      setState(() {
        ingredient.quantity--;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('manualIngredients')
          .where('name', isEqualTo: ingredient.name)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('manualIngredients')
            .doc(snapshot.docs.first.id)
            .update({'quantity': ingredient.quantity});
      }
    }
  }

  void _deleteManualIngredient(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('Remove Ingredient'),
          content: Text('Do you provide this nutritional ingredient?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () async {
                setState(() {
                  manualIngredients.remove(ingredient);
                });

                final snapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('manualIngredients')
                    .where('name', isEqualTo: ingredient.name)
                    .get();

                if (snapshot.docs.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .collection('manualIngredients')
                      .doc(snapshot.docs.first.id)
                      .delete();
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteIngredientFromRecipe(Recipe recipe, Ingredient ingredient) async {
  setState(() {
    recipe.missingIngredients.remove(ingredient);
  });

  try {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('shoppingList')
        .doc(recipe.id)
        .get();

    if (docSnapshot.exists) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('shoppingList')
          .doc(recipe.id)
          .update({
        'ingredients': FieldValue.arrayRemove([ingredient.name])
      });

      // Check if the recipe has no more missing ingredients
      if (recipe.missingIngredients.isEmpty) {
        _deleteRecipe(recipe);
      }
    } else {
      // Handle the case where the document doesn't exist
      print('Recipe document not found');
      setState(() {
        recipes.remove(recipe);
      });
    }
  } catch (e) {
    // Handle other potential exceptions
    print('Error updating recipe: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange.shade300,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Shopping List',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: 160), // Ensure space for draggable sheet
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    return RecipeCard(
                      recipe: recipes[index],
                      onToggleExpand: () {
                        setState(() {
                          for (int i = 0; i < recipes.length; i++) {
                            if (i != index) {
                              recipes[i].expanded = false;
                            }
                          }
                          recipes[index].expanded = !recipes[index].expanded;
                        });
                      },
                      onDelete: () {
                        _deleteRecipe(recipes[index]);
                      },
                      onDeleteIngredient: (ingredient) {
                        _deleteIngredientFromRecipe(recipes[index], ingredient);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        'Add Your Ingredients',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: ingredientNameController,
                              decoration: InputDecoration(
                                labelText: 'Ingredient Name',
                                labelStyle: TextStyle(fontSize: 13.5),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 8.0),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: ingredientQuantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                labelStyle: TextStyle(fontSize: 13.5),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 8.0),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            color: Colors.orange,
                            onPressed: _addManualIngredient,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: manualIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = manualIngredients[index];
                          return ListTile(
                            title: TextField(
                              controller: TextEditingController(text: ingredient.name),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                              ),
                              onChanged: (newValue) {
                                setState(() {
                                  ingredient.name = newValue;
                                });
                              },
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.orange),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.remove, size: 16),
                                    color: Colors.orange,
                                    onPressed: () {
                                      _decreaseManualQuantity(ingredient);
                                    },
                                  ),
                                ),
                                SizedBox(width: 1.5),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.orange),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(ingredient.quantity.toString()),
                                ),
                                SizedBox(width: 1.5),
                                Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.orange),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.add, size: 16),
                                    color: Colors.orange,
                                    onPressed: () {
                                      _increaseManualQuantity(ingredient);
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.check, size: 22),
                                  color: Colors.green,
                                  onPressed: () =>
                                      _deleteManualIngredient(ingredient),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Recipe {
  String id;
  String name;
  final String imageUrl;
  final String cookingTime;
  final double rating;
  final List<Ingredient> missingIngredients;
  bool expanded;

  Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cookingTime,
    required this.rating,
    required this.missingIngredients,
    this.expanded = false,
  });
}

class Ingredient {
  String name;
  int quantity;

  Ingredient({
    required this.name,
    required this.quantity,
  });
}

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onToggleExpand;
  final VoidCallback onDelete;
  final ValueChanged<Ingredient> onDeleteIngredient;

  RecipeCard({
    required this.recipe,
    required this.onToggleExpand,
    required this.onDelete,
    required this.onDeleteIngredient,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  void _increaseQuantity(Ingredient ingredient) {
    setState(() {
      ingredient.quantity++;
    });
  }

  void _decreaseQuantity(Ingredient ingredient) {
    setState(() {
      if (ingredient.quantity > 1) {
        ingredient.quantity--;
      }
    });
  }

  void _deleteIngredient(BuildContext context, Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Ingredient'),
          content: Text('Do you provide this nutritional ingredient?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                setState(() {
                  widget.recipe.missingIngredients.remove(ingredient);
                  widget.onDeleteIngredient(ingredient);
                  Navigator.of(context).pop();
                });

                if (widget.recipe.missingIngredients.isEmpty) {
                  widget.onDelete();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteRecipe(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('Delete Recipe'),
          content: Text('Are you sure you want to delete this recipe?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                widget.onDelete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Image.network(
                  widget.recipe.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipe.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              widget.recipe.cookingTime,
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.star, color: Colors.yellow, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${widget.recipe.rating}',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Missing ingredients: ${widget.recipe.missingIngredients.length}',
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteRecipe(context),
                      tooltip: 'Delete Recipe',
                    ),
                    IconButton(
                      icon: Icon(widget.recipe.expanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                      onPressed: widget.onToggleExpand,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.recipe.expanded)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: widget.recipe.missingIngredients.map((ingredient) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      ingredient.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.remove, size: 16),
                            color: Colors.orange,
                            onPressed: () {
                              _decreaseQuantity(ingredient);
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        ),
                        SizedBox(width: 1.5),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(ingredient.quantity.toString()),
                        ),
                        SizedBox(width: 1.5),
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, size: 16),
                            color: Colors.orange,
                            onPressed: () {
                              _increaseQuantity(ingredient);
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, size: 22),
                          color: Colors.green,
                          onPressed: () =>
                              _deleteIngredient(context, ingredient),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}







/* void _increaseQuantity(Ingredient ingredient) {
    ingredient.quantity++;
  }

  void _decreaseQuantity(Ingredient ingredient) {
    if (ingredient.quantity > 1) {
      ingredient.quantity--;
    }
  } 
  
  void _deleteIngredient(BuildContext context, Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Ingredient'),
          content: Text('Do you provide this nutritional ingredient?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                recipe.missingIngredients.remove(ingredient);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }*/


/* import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientShoppingList extends StatefulWidget {
  final String userId;

  IngredientShoppingList({required this.userId});

  @override
  _IngredientShoppingListState createState() => _IngredientShoppingListState();
}

class _IngredientShoppingListState extends State<IngredientShoppingList> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Recipe> recipes = [];
  List<Ingredient> manualIngredients = [];

  final TextEditingController ingredientNameController = TextEditingController();
  final TextEditingController ingredientQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchShoppingList();
  }

  void fetchShoppingList() async {
    QuerySnapshot querySnapshot = await firestore
        .collection('users')
        .doc(widget.userId)
        .collection('shoppingList')
        .get();

    for (var doc in querySnapshot.docs) {
      String recipeId = doc['recipeId'];
      String recipeName = doc['recipeName'];
      List ingredients = doc['ingredients'];

      // Fetch recipe details
      DocumentSnapshot recipeSnapshot = await firestore.collection('recipes').doc(recipeId).get();
      if (!recipeSnapshot.exists) {
        recipeSnapshot = await firestore
            .collection('users')
            .doc(widget.userId)
            .collection('recipes')
            .doc(recipeId)
            .get();
      }

      if (recipeSnapshot.exists) {
        Recipe recipe = Recipe.fromFirestore(recipeSnapshot);
        setState(() {
          recipes.add(recipe);
          manualIngredients.addAll(ingredients.map((e) => Ingredient.fromMap(e)).toList());
        });
      }
    }
  }

  void _addManualIngredient() {
    setState(() {
      manualIngredients.add(Ingredient(
        name: ingredientNameController.text,
        quantity: int.tryParse(ingredientQuantityController.text) ?? 1,
      ));
      ingredientNameController.clear();
      ingredientQuantityController.clear();
    });
  }

  void _deleteRecipe(Recipe recipe) {
    setState(() {
      recipes.remove(recipe);
    });
  }

  void _increaseManualQuantity(Ingredient ingredient) {
    setState(() {
      ingredient.quantity++;
    });
  }

  void _decreaseManualQuantity(Ingredient ingredient) {
    setState(() {
      if (ingredient.quantity > 1) {
        ingredient.quantity--;
      }
    });
  }

  void _deleteManualIngredient(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('Remove Ingredient'),
          content: Text('Do you want to remove this ingredient?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                setState(() {
                  manualIngredients.remove(ingredient);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void saveManualIngredients(List<Ingredient> ingredients) async {
  CollectionReference shoppingListRef = firestore
      .collection('users')
      .doc(widget.userId)
      .collection('shoppingList');

  await shoppingListRef.add({
    'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
    'recipeId': '', // Provide the appropriate recipe ID or name
    'recipeName': '', // Provide the appropriate recipe name
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange.shade300,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Shopping List',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: 160),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    return RecipeCard(
                      recipe: recipes[index],
                      onToggleExpand: () {
                        setState(() {
                          for (int i = 0; i < recipes.length; i++) {
                            if (i != index) {
                              recipes[i].expanded = false;
                            }
                          }
                          recipes[index].expanded = !recipes[index].expanded;
                        });
                      },
                      onDelete: () {
                        _deleteRecipe(recipes[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        'Add Your Ingredients',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: ingredientNameController,
                              decoration: InputDecoration(
                                labelText: 'Ingredient Name',
                                labelStyle: TextStyle(fontSize: 13.5),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 8.0),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: ingredientQuantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                labelStyle: TextStyle(fontSize: 13.5),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 8.0),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            color: Colors.orange,
                            onPressed: _addManualIngredient,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: manualIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = manualIngredients[index];
                          return ListTile(
                            title: TextField(
                              controller: TextEditingController(text: ingredient.name),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                              ),
                              onChanged: (newValue) {
                                setState(() {
                                  ingredient.name = newValue;
                                });
                              },
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.orange),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.remove, size: 16),
                                    color: Colors.orange,
                                    onPressed: () {
                                      _decreaseManualQuantity(ingredient);
                                    },
                                  ),
                                ),
                                SizedBox(width: 1.5),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.orange),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(ingredient.quantity.toString()),
                                ),
                                SizedBox(width: 1.5),
                                Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.orange),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.add, size: 16),
                                    color: Colors.orange,
                                    onPressed: () {
                                      _increaseManualQuantity(ingredient);
                                    },
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.orange),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.delete_outline, size: 16),
                                    color: Colors.orange,
                                    onPressed: () {
                                      _deleteManualIngredient(ingredient);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          saveManualIngredients(manualIngredients);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Save Ingredients'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Recipe {
  String id;
  String name;
  List<Ingredient> ingredients;
  String? imageUrl;
  double rating;
  String cookingTime;
  bool expanded;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    this.imageUrl,
    this.rating = 0.0,
    this.cookingTime = '',
    this.expanded = false,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

  // Handle null data scenario
  if (data == null) {
    throw Exception("Document data was null.");
  }

  // Parse ingredients
  List<Ingredient> parsedIngredients = [];
  final dynamic ingredientsData = data['ingredients'];

  if (ingredientsData != null && ingredientsData is List) {
    // If ingredientsData is a List, map each item to Ingredient.fromMap
    parsedIngredients = List<Ingredient>.from(
      ingredientsData.map((item) {
        if (item is Map<String, dynamic>) {
          return Ingredient.fromMap(item);
        } else {
          throw Exception("Ingredient data is not in expected format.");
        }
      }),
    );
  } else {
    // Handle unexpected format of ingredients data
    throw Exception("Ingredients data is not in expected format.");
  }

  // Parse optional fields
  String? imageUrl = data['imageUrl'];
  double rating = (data['rating'] ?? 0.0).toDouble();
  String cookingTime = data['cookingTime'] ?? '';

  return Recipe(
    id: doc.id,
    name: data['name'] ?? '',
    ingredients: parsedIngredients,
    imageUrl: imageUrl,
    rating: rating,
    cookingTime: cookingTime,
  );
}

}






class Ingredient {
  String name;
  int quantity;

  Ingredient({required this.name, required this.quantity});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1, // Example default value
    );
  }
}



class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onToggleExpand;
  final VoidCallback onDelete;

  RecipeCard({
    required this.recipe,
    required this.onToggleExpand,
    required this.onDelete,
  });

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  void _deleteIngredient(Ingredient ingredient) {
    setState(() {
      widget.recipe.ingredients.remove(ingredient);
    });
  }

  void _showDeleteIngredientDialog(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Ingredient'),
          content: Text('Do you provide this nutritional ingredient?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                _deleteIngredient(ingredient);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 3,
      child: Column(
        children: [
          // ... [Other existing widget code]
          if (widget.recipe.expanded)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.shade300,
              ),
              child: Column(
                children: widget.recipe.ingredients.map((ingredient) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(ingredient.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.remove, size: 16),
                            color: Colors.orange,
                            onPressed: () {
                              // Handle decrease quantity
                            },
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(ingredient.quantity.toString()),
                        ),
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, size: 16),
                            color: Colors.orange,
                            onPressed: () {
                              // Handle increase quantity
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, size: 16),
                          color: Colors.red,
                          onPressed: () => _showDeleteIngredientDialog(ingredient),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
} */


 


/*Recipe(
      name: "Chicken Curry",
      imageUrl: "assets/food1.jpg",
      cookingTime: "40 mins",
      rating: 4.7,
      missingIngredients: [
        Ingredient(name: "Chicken Breast", quantity: 2),
        Ingredient(name: "Coconut Milk", quantity: 1),
        Ingredient(name: "Curry Powder", quantity: 1),
      ],
    ),
    Recipe(
      name: "Chicken Curry",
      imageUrl: "assets/food1.jpg",
      cookingTime: "40 mins",
      rating: 4.7,
      missingIngredients: [
        Ingredient(name: "Chicken Breast", quantity: 2),
        Ingredient(name: "Coconut Milk", quantity: 1),
        Ingredient(name: "Curry Powder", quantity: 1),
      ],
    ),
    Recipe(
      name: "Chicken Curry",
      imageUrl: "assets/food1.jpg",
      cookingTime: "40 mins",
      rating: 4.7,
      missingIngredients: [
        Ingredient(name: "Chicken Breast", quantity: 2),
        Ingredient(name: "Coconut Milk", quantity: 1),
        Ingredient(name: "Curry Powder", quantity: 1),
      ],
    ),
    Recipe(
      name: "Beef Stew",
      imageUrl: "assets/food1.jpg",
      cookingTime: "1 hr",
      rating: 4.8,
      missingIngredients: [
        Ingredient(name: "Beef", quantity: 2),
        Ingredient(name: "Carrots", quantity: 3),
        Ingredient(name: "Potatoes", quantity: 4),
      ],
    ),
    Recipe(
      name: "Caesar Salad",
      imageUrl: "assets/food1.jpg",
      cookingTime: "15 mins",
      rating: 4.2,
      missingIngredients: [
        Ingredient(name: "Lettuce", quantity: 1),
        Ingredient(name: "Parmesan", quantity: 1),
        Ingredient(name: "Croutons", quantity: 1),
      ],
    ),
    Recipe(
      name: "Grilled Salmon",
      imageUrl: "assets/food1.jpg",
      cookingTime: "20 mins",
      rating: 4.9,
      missingIngredients: [
        Ingredient(name: "Salmon Fillet", quantity: 2),
        Ingredient(name: "Lemon", quantity: 1),
        Ingredient(name: "Dill", quantity: 1),
      ],
    ),*/


/* void _increaseQuantity(Ingredient ingredient) {
    ingredient.quantity++;
  }

  void _decreaseQuantity(Ingredient ingredient) {
    if (ingredient.quantity > 1) {
      ingredient.quantity--;
    }
  } 
  
  void _deleteIngredient(BuildContext context, Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Ingredient'),
          content: Text('Do you provide this nutritional ingredient?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                recipe.missingIngredients.remove(ingredient);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }*/
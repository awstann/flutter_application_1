import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/Main_Screens/HomePage.dart';
import 'package:flutter_application_1/Main_Screens/KitchenManagement.dart';
import 'package:flutter_application_1/Main_Screens/NotificationPage.dart';
import 'package:flutter_application_1/Main_Screens/SavedRecipes.dart';
import 'package:flutter_application_1/Main_Screens/UserProfilePage.dart';
import 'package:flutter_application_1/sharedCode/Recipe_Model.dart';
import 'RecipeDetailsPage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeSearchPage extends StatefulWidget {
  @override
  _RecipeSearchPageState createState() => _RecipeSearchPageState();
}

class _RecipeSearchPageState extends State<RecipeSearchPage> {
  String selectedFilter = 'All';
  List<String> filters = [
    'All',
    'Fast Food',
    'Traditional Food',
    'Desserts',
    'Drinks',
    'Pastries',
    'Salads',
    'Pasta',
    'Rice',
    'Healthy',
    'Snacks',
    'Chicken & Meat'
  ];

  List<Recipe> recipes = [];
  List<Recipe> filteredRecipes = [];
  String searchQuery = '';
  List<String> _savedRecipeIds = [];

  @override
  void initState() {
    super.initState();
    fetchRecipes();
    _fetchSavedRecipes();
  }

  Future<void> fetchRecipes() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('recipes').get();
    setState(() {
      recipes = snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
      applyFilter();
    });
  }

  Future<void> _fetchSavedRecipes() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedRecipes')
          .get();

      List<String> savedRecipeIds = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        _savedRecipeIds = savedRecipeIds;
      });
    }
  }

  void applyFilter() {
    setState(() {
      filteredRecipes = recipes.where((recipe) {
        bool matchesFilter =
            selectedFilter == 'All' || recipe.type == selectedFilter;
        bool matchesSearch = searchQuery.isEmpty ||
            recipe.name.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleBookmark(Recipe recipe) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      CollectionReference savedRecipesCollection = userDoc.collection('savedRecipes');

      if (_savedRecipeIds.contains(recipe.id)) {
        // Remove from saved recipes
        await savedRecipesCollection.doc(recipe.id).delete();
        setState(() {
          _savedRecipeIds.remove(recipe.id);
        });
      } else {
        // Add to saved recipes
        await savedRecipesCollection.doc(recipe.id).set(recipe.toFirestore());
        setState(() {
          _savedRecipeIds.add(recipe.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 2; // Home is the default selected index

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => NotificationPage()));
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
      backgroundColor: Colors.white,
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
      appBar: AppBar(
        backgroundColor: Colors.orange.shade300,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Search Recipe',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 5),
            _buildFilters(),
            _buildRecipeGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1.5,
            blurRadius: 3.5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for recipes...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.orange),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onChanged: (query) {
          searchQuery = query;
          applyFilter();
        },
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = filter;
                applyFilter();
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selectedFilter == filter ? Colors.orange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color:
                      selectedFilter == filter ? Colors.white : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecipeGrid() {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.only(top: 10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: filteredRecipes.length,
        itemBuilder: (context, index) {
          return _buildRecipeCard(filteredRecipes[index], index);
        },
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, int index) {
    bool isBookmarked = _savedRecipeIds.contains(recipe.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(recipe: recipe, userId: FirebaseAuth.instance.currentUser!.uid),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 120,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () {
                      _toggleBookmark(recipe);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 2),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overflow: TextOverflow.ellipsis,
                    recipe.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(recipe.source,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[600])),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text(
                            recipe.cookingTime,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(width: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text(
                            recipe.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
  }
}





//type: data['type'] ?? '',




/* class Recipe {
  final String id;
  final String name;
  final String image;
  final double rating;
  final String source;
  final String time;
  final String type;
  bool isSaved;

  Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.source,
    required this.time,
    required this.type,
    this.isSaved = false,
  });

  factory Recipe.fromDocument(DocumentSnapshot doc) {
    return Recipe(
      id: doc.id,
      name: doc['name'],
      image: doc['image'],
      rating: doc['rating'],
      source: doc['source'],
      time: doc['time'],
      type: doc['type'],
      isSaved: doc['isSaved'] ?? false,
    );
  }
} */
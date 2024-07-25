import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_application_1/Main_Screens/CookUpCommunity.dart';
import 'package:flutter_application_1/Main_Screens/CookingLesson.dart';
import 'package:flutter_application_1/Main_Screens/KitchenManagement.dart';
import 'package:flutter_application_1/Main_Screens/LibyanTraditionalFood.dart';
import 'package:flutter_application_1/Main_Screens/NotificationPage.dart';
import 'package:flutter_application_1/Main_Screens/SavedRecipes.dart';
import 'package:flutter_application_1/Main_Screens/SearchPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Main_Screens/UserProfilePage.dart';
import 'package:flutter_application_1/Services/Authentication.dart';
import 'package:flutter_application_1/Services/Auth_State_Handler.dart';
import 'package:flutter_application_1/sharedCode/Recipe_Model.dart' as shared_recipe;
import 'RecipeDetailsPage.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _username;
  List<shared_recipe.Recipe> _recommendedRecipes = [];
  List<shared_recipe.Recipe> _chefsRecipes = [];
  String selectedFilter = 'All';
  List<String> filters = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Eid\'s', 'Occasions'];
  late String userId;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchRecommendedRecipes();
    _fetchChefsRecipes();
  }

  Future<void> _fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            _username = userDoc['username'];
          });
        }
      } else {
        print('User document does not exist');
      }
    }
  }

  Future<void> _fetchRecommendedRecipes() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('recipes').limit(10).get();
    List<shared_recipe.Recipe> recipes = snapshot.docs.map((doc) => shared_recipe.Recipe.fromFirestore(doc)).toList();
    recipes.shuffle();
    if (mounted) {
      setState(() {
        _recommendedRecipes = recipes;
      });
    }
  }

  Future<void> _fetchChefsRecipes() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('chefsRecipes').get();
    List<shared_recipe.Recipe> recipes = snapshot.docs.map((doc) => shared_recipe.Recipe.fromFirestore(doc)).toList();
    recipes.shuffle();
    if (mounted) {
      setState(() {
        _chefsRecipes = recipes;
      });
    }
  }

  Future<void> _fetchFilteredRecipes(String filter) async {
    QuerySnapshot snapshot;
    if (filter == 'All') {
      snapshot = await FirebaseFirestore.instance.collection('recipes').get();
    } else {
      snapshot = await FirebaseFirestore.instance.collection('recipes').where('category', isEqualTo: filter).get();
    }
    List<shared_recipe.Recipe> recipes = snapshot.docs.map((doc) => shared_recipe.Recipe.fromFirestore(doc)).toList();
    recipes.shuffle();
    if (mounted) {
      setState(() {
        _recommendedRecipes = recipes;
      });
    }
  }

  Future<void> _saveRecipe(shared_recipe.Recipe recipe) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedRecipes')
          .doc(recipe.id)
          .set(recipe.toFirestore());
      print('Recipe saved to Firestore');
    }
  }

  void _viewRecipeDetails(shared_recipe.Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsPage(
          recipe: recipe,
          userId: userId,
        ),
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
              });
              _fetchFilteredRecipes(filter);
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
                  color: selectedFilter == filter ? Colors.white : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => CookUpCommunity()));
          break;
        case 1:
          Navigator.push(context, MaterialPageRoute(builder: (context) => KitchenManagementPage()));
          break;
        case 2:
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
          break;
        case 3:
          Navigator.push(context, MaterialPageRoute(builder: (context) => SavedRecipes()));
          break;
        case 4:
          Navigator.push(context, MaterialPageRoute(builder: (context) => Userprofilepage()));
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange.shade300,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('CookUp', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecommendedRecipes,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 2, 0),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _username == null
                      ? CircularProgressIndicator()
                      : Flexible(
                          child: Text('Welcome to CookUp, $_username!',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
              SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 12, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1.5,
                        blurRadius: 3.5,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: TextField(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeSearchPage()));
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for recipes...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.orange),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                height: 180.0,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryCard(
                      backgroundColor: Colors.orange,
                      image: 'assets/LibyanKitchen.jpg',
                      description: ' Libyan Traditional Food',
                      textColor: Colors.brown.shade600,
                      navigateToPage: LibyanTraditionalFoodPage(),
                    ),
                    CategoryCard(
                      backgroundColor: Colors.blue,
                      image: 'assets/Create_Recipe_AI.jpg',
                      description: 'Create Recipes With AI',
                      textColor: Colors.white,
                      navigateToPage: CreateRecipePage(),
                    ),
                    CategoryCard(
                      backgroundColor: Colors.green,
                      image: 'assets/Learn_Cooking.jpg',
                      description: 'Learn the Basics Of Cooking',
                      textColor: Colors.white,
                      navigateToPage: CookingLessonsPage(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.0),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recipe Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Text(
                      'View all',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Container(height: 60.0, child: _buildFilters()),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended Recipes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'View all',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.0),
              Container(
                height: 170.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendedRecipes.length,
                  itemBuilder: (context, index) {
                    shared_recipe.Recipe recipe = _recommendedRecipes[index];
                    return GestureDetector(
                      onTap: () => _viewRecipeDetails(recipe),
                      child: RecipeCard(
                        image: recipe.imageUrl,
                        name: recipe.name,
                        time: recipe.cookingTime,
                        rating: recipe.rating,
                        onBookmark: () => _saveRecipe(recipe),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Chef\'s Recipes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'View all',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  children: _chefsRecipes.map((recipe) {
                    return ChefRecipeCard(
                      image: recipe.imageUrl,
                      name: recipe.name,
                      chefName: recipe.by ?? 'Unknown Chef',
                      time: recipe.cookingTime,
                      rating: recipe.rating,
                      onBookmark: () => _saveRecipe(recipe),
                      onTap: () => _viewRecipeDetails(recipe),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Color backgroundColor;
  final String image;
  final String description;
  final Color textColor;
  final Widget navigateToPage;

  CategoryCard({
    required this.backgroundColor,
    required this.image,
    required this.description,
    required this.textColor,
    required this.navigateToPage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => navigateToPage),
        );
      },
      child: Container(
        width: 300.0,
        margin: EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.orange.shade200, width: 2),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              backgroundColor.withOpacity(0.0),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => navigateToPage),
                  );
                },
                child: Text('Explore', style: TextStyle(color: Colors.orange)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 30,
              left: 5,
              width: 150,
              child: Text(
                description,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final String image;
  final String name;
  final String time;
  final double rating;
  final VoidCallback onBookmark;

  RecipeCard({
    required this.image,
    required this.name,
    required this.time,
    required this.rating,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150.0,
      margin: EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
            child: Image.network(
              image,
              height: 100.0,
              width: 150.0,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16.0, color: Colors.grey),
                        SizedBox(width: 4.0),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 16.0),
                        SizedBox(width: 4.0),
                        Text(rating.toString()),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChefRecipeCard extends StatelessWidget {
  final String image;
  final String name;
  final String chefName;
  final String time;
  final double rating;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  ChefRecipeCard({
    required this.image,
    required this.name,
    required this.chefName,
    required this.time,
    required this.rating,
    required this.onBookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                image,
                height: 100.0,
                width: 100.0,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'by $chefName',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16.0, color: Colors.grey),
                          SizedBox(width: 4.0),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 16.0),
                          SizedBox(width: 4.0),
                          Text(rating.toString()),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.bookmark_border),
                        color: Colors.orange,
                        onPressed: onBookmark,
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


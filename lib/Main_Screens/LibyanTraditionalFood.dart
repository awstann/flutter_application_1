import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/sharedCode/Recipe_Model.dart';
import 'RecipeDetailsPage.dart';

class LibyanTraditionalFoodPage extends StatefulWidget {
  @override
  _LibyanTraditionalFoodPageState createState() => _LibyanTraditionalFoodPageState();
}

class _LibyanTraditionalFoodPageState extends State<LibyanTraditionalFoodPage> {
  TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  List<Recipe> _dessertRecipes = [];
  List<Recipe> _ramadanRecipes = [];
  List<Recipe> _occasionsRecipes = [];
  List<Recipe> _allRecipes = [];
  List<Recipe> _searchResults = [];
  bool _showAllDesserts = false;
  bool _showAllRamadan = false;
  bool _showAllOccasions = false;
  bool _isSearching = false;
  String searchQuery = '';
  List<String> _savedRecipeIds = [];

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _fetchSearchHistory();
    _fetchSavedRecipes();
  }

  Future<void> _fetchRecipes() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .where('type', isEqualTo: 'Traditional Food')
        .get();

    List<Recipe> fetchedRecipes = snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    setState(() {
      _dessertRecipes = fetchedRecipes.where((recipe) => recipe.occasion == 'Dessert').toList();
      _ramadanRecipes = fetchedRecipes.where((recipe) => recipe.occasion == 'Ramadan').toList();
      _occasionsRecipes = fetchedRecipes.where((recipe) => recipe.occasion != 'Dessert' && recipe.occasion != 'Ramadan').toList();
      _allRecipes = fetchedRecipes;
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

  void _searchRecipes(String query) async {
    setState(() {
      searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.add(query);
      });
      await _saveSearchHistory(query);
    }

    applyFilter();
  }

  void applyFilter() {
    setState(() {
      _searchResults = _allRecipes.where((recipe) {
        bool matchesSearch = searchQuery.isEmpty || recipe.name.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.collection('searchHistory').add({'query': query, 'timestamp': Timestamp.now()});
    }
  }

  Future<void> _fetchSearchHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('searchHistory')
            .orderBy('timestamp', descending: true)
            .get();

        List<String> history = snapshot.docs.map((doc) => doc['query'] as String).toList();
        setState(() {
          _searchHistory = history;
        });
      } catch (e) {
        print("Error fetching search history: $e");
      }
    }
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
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
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for recipes...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.orange),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onChanged: (query) {
                  _searchRecipes(query);
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.history, color: Colors.orange),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Search History'),
                    content: Container(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: _searchHistory
                            .map(
                              (query) => ListTile(
                                title: Text(query),
                                onTap: () {
                                  _searchController.text = query;
                                  _searchRecipes(query);
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeContainer(Recipe recipe) {
    bool isBookmarked = _savedRecipeIds.contains(recipe.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(
              recipe: recipe,
              userId: FirebaseAuth.instance.currentUser!.uid,
            ),
          ),
        );
      },
      child: Container(
        width: 150.0,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150.0,
              height: 100.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                image: DecorationImage(
                  image: NetworkImage(recipe.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.orange : null,
                        ),
                        onPressed: () {
                          _toggleBookmark(recipe);
                        },
                      ),
                    ],
                  ),
                  Text(
                    recipe.source,
                    style: TextStyle(color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 16,
                      ),
                      SizedBox(
                        width: 2,
                      ),
                      Text(
                        recipe.cookingTime,
                        style: TextStyle(color: Colors.grey),
                      ),
                      Spacer(),
                      Icon(
                        Icons.star,
                        color: Colors.yellow,
                        size: 18,
                      ),
                      Text(
                        recipe.rating.toString(),
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

  Widget _buildVerticalRecipeContainer(Recipe recipe) {
    bool isBookmarked = _savedRecipeIds.contains(recipe.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(
              recipe: recipe,
              userId: FirebaseAuth.instance.currentUser!.uid,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Container(
              width: 100.0,
              height: 110.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(8.0)),
                image: DecorationImage(
                  image: NetworkImage(recipe.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          recipe.source,
                          style: TextStyle(color: Colors.grey),
                        ),
                        IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: isBookmarked ? Colors.orange : null,
                          ),
                          onPressed: () {
                            _toggleBookmark(recipe);
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 2),
                            Text(
                              recipe.cookingTime,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 18,
                            ),
                            Text(
                              recipe.rating.toString(),
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Recipe> recipes, bool isHorizontal, bool showAll, VoidCallback onSeeAll) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  showAll ? 'Show less' : 'See all',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        isHorizontal
            ? SizedBox(
                height: 220.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: showAll ? recipes.length : (recipes.length > 5 ? 5 : recipes.length),
                  itemBuilder: (context, index) {
                    return _buildRecipeContainer(recipes[index]);
                  },
                ),
              )
            : Column(
                children: (showAll ? recipes : recipes.take(5)).map((recipe) => _buildVerticalRecipeContainer(recipe)).toList(),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Libyan Traditional Food',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.orange.shade300,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _isSearching
                ? Column(
                    children: _searchResults.map((recipe) => _buildVerticalRecipeContainer(recipe)).toList(),
                  )
                : Column(
                    children: [
                      _buildSection('Dessert Recipes', _dessertRecipes, true, _showAllDesserts, () {
                        setState(() {
                          _showAllDesserts = !_showAllDesserts;
                        });
                      }),
                      _buildSection('Ramadan Recipes', _ramadanRecipes, false, _showAllRamadan, () {
                        setState(() {
                          _showAllRamadan = !_showAllRamadan;
                        });
                      }),
                      _buildSection('Occasions Recipes', _occasionsRecipes, true, _showAllOccasions, () {
                        setState(() {
                          _showAllOccasions = !_showAllOccasions;
                        });
                      }),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

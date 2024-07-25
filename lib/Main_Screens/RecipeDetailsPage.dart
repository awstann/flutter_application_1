import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/sharedCode/Recipe_Model.dart';

class RecipeDetailsPage extends StatefulWidget {
  final String userId; // Logged-in user ID
  final Recipe recipe; // Assuming you have a Recipe model

  RecipeDetailsPage({required this.userId, required this.recipe});

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  bool isBookmarked = false;
  int selectedIndex = 0;
  List<String> ingredients = [];
  List<String> cookingSteps = [];
  List<Map<String, dynamic>> reviews = [];
  int userRating = 0;
  String userReview = '';
  List<String> notes = [];
  TextEditingController noteController = TextEditingController();
  int? editingIndex;
  String _username = '';
  String _profileImageUrl = '';
  Set<String> addedIngredients = {};
  List<Recipe> recommendedRecipes = [];

  @override
  void initState() {
    super.initState();
    ingredients = widget.recipe.ingredients;
    cookingSteps = widget.recipe.cookingSteps;
    _fetchReviews();
    _fetchNotes();
    _fetchUserData();
    _checkBookmarkStatus();
    _fetchRecommendedRecipes();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _username = data['username'] ?? '';
          _profileImageUrl = data['profileImageUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _checkBookmarkStatus() async {
    DocumentSnapshot bookmarkedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('savedRecipes')
        .doc(widget.recipe.id)
        .get();

    setState(() {
      isBookmarked = bookmarkedDoc.exists;
    });
  }

  Future<void> _saveNotes() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('recipes')
        .doc(widget.recipe.id)
        .set({'notes': notes}, SetOptions(merge: true));
  }

  Future<void> _addReview() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipe.id)
            .collection('reviews')
            .doc(widget.userId)
            .set({
          'user': widget.userId,
          'rating': userRating,
          'review': userReview,
          'username': _username,
          'profileImage': _profileImageUrl,
        });
      } catch (e) {
        print('Error adding review: $e');
      }
    } else {
      print('User not authenticated');
    }
  }

  Future<void> _updateReview() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipe.id)
            .collection('reviews')
            .doc(widget.userId)
            .update({
          'rating': userRating,
          'review': userReview,
        });
      } catch (e) {
        print('Error updating review: $e');
      }
    } else {
      print('User not authenticated');
    }
  }

  void _addNote() {
    if (noteController.text.isNotEmpty) {
      setState(() {
        if (editingIndex != null) {
          notes[editingIndex!] = noteController.text;
          editingIndex = null;
        } else {
          notes.add(noteController.text);
        }
      });
      _saveNotes();
      noteController.clear();
    }
  }

  Future<void> _fetchIngredients() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipe.id)
        .collection('ingredients')
        .get();

    setState(() {
      ingredients = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> _fetchCookingSteps() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipe.id)
        .collection('steps')
        .get();

    setState(() {
      cookingSteps = snapshot.docs.map((doc) => doc['step'] as String).toList();
    });
  }

  Future<void> _fetchNotes() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('recipes')
          .doc(widget.recipe.id)
          .get();

      if (snapshot.exists) {
        setState(() {
          notes = List<String>.from(snapshot['notes']);
        });
      }
    } catch (e) {
      print("Error fetching notes: $e");
    }
  }

  Future<void> _fetchReviews() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .collection('reviews')
          .get();

      setState(() {
        reviews = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });

      // Find the user's review
      DocumentSnapshot? userReviewDoc;
      for (var doc in snapshot.docs) {
        if (doc.id == widget.userId) {
          userReviewDoc = doc;
          break;
        }
      }

      if (userReviewDoc != null) {
        final userReviewData = userReviewDoc.data() as Map<String, dynamic>;
        setState(() {
          userRating = userReviewData['rating'];
          userReview = userReviewData['review'];
        });
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  Future<void> _fetchRecommendedRecipes() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .get();

    List<DocumentSnapshot> docs = snapshot.docs;
    docs.removeWhere((doc) => doc.id == widget.recipe.id); // Remove current recipe

    final random = Random();
    recommendedRecipes = List.generate(5, (index) {
      int randomIndex = random.nextInt(docs.length);
      DocumentSnapshot doc = docs[randomIndex];
      final data = doc.data() as Map<String, dynamic>;
      docs.removeAt(randomIndex); // Ensure unique recipes

      return Recipe(
        id: doc.id,
        name: data['name'] ?? 'Unnamed Recipe',
        imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150', // Placeholder image
        cookingTime: data['cookingTime'] ?? 'Unknown',
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        source: data['source'] ?? 'Unknown Source',
        ingredients: (data['ingredients'] as List<dynamic>?)
                ?.map((item) => item.toString())
                .toList() ??
            [],
        cookingSteps: (data['cookingSteps'] as List<dynamic>?)
                ?.map((item) => item.toString())
                .toList() ??
            [],
        type: data['type'] ?? 'Unknown Type', description: '', category: '',
      );
    });

    setState(() {});
  }

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
                Image.network(widget.recipe.imageUrl),
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
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () async {
                          if (isBookmarked) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId)
                                .collection('savedRecipes')
                                .doc(widget.recipe.id)
                                .delete();
                          } else {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId)
                                .collection('savedRecipes')
                                .doc(widget.recipe.id)
                                .set(widget.recipe.toFirestore());
                          }

                          setState(() {
                            isBookmarked = !isBookmarked;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.recipe.source,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.orange),
                      SizedBox(width: 4),
                      Text('${widget.recipe.cookingTime}'),
                      SizedBox(width: 16),
                      Icon(Icons.star, color: Colors.yellow[500]),
                      SizedBox(width: 4),
                      Text('${widget.recipe.rating}'),
                    ],
                  ),
                  SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (widget.recipe.type == 'Traditional Food')
                          _buildSectionTab('Details', 0),
                        _buildSectionTab('Ingredients', 1),
                        _buildSectionTab('Cooking Steps', 2),
                        _buildSectionTab('My Notes', 3),
                        _buildSectionTab('Rate & Review', 4),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSectionContent(),
                  SizedBox(height: 16),
                  Text(
                    'Recommended Recipes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: recommendedRecipes.map((recipe) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailsPage(
                                  userId: widget.userId,
                                  recipe: recipe,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 16),
                            width: 160,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    recipe.imageUrl,
                                    height: 80,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    recipe.name,
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: Colors.orange, size: 16),
                                      SizedBox(width: 4),
                                      Text(recipe.cookingTime, style: TextStyle(fontSize: 12)),
                                      Spacer(),
                                      Icon(Icons.star, color: Colors.yellow[500], size: 16),
                                      SizedBox(width: 4),
                                      Text(recipe.rating.toString(), style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTab(String title, int index) {
    return Container(
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(20),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: selectedIndex == index ? Colors.orange : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedIndex == 0) _buildDetailsSection(),
          if (selectedIndex == 1) _buildIngredientsSection(),
          if (selectedIndex == 2) _buildCookingStepsSection(),
          if (selectedIndex == 3) _buildNotesSection(),
          if (selectedIndex == 4) _buildRateAndReviewSection(),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.recipe.backgroundStory != null)
          Text(
            'Background Story:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        if (widget.recipe.backgroundStory != null)
          Text(
            widget.recipe.backgroundStory!,
            style: TextStyle(fontSize: 16),
          ),
        SizedBox(height: 16),
        if (widget.recipe.famousCities != null && widget.recipe.famousCities!.isNotEmpty)
          Text(
            'Famous Cities:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        if (widget.recipe.famousCities != null && widget.recipe.famousCities!.isNotEmpty)
          Text(
            widget.recipe.famousCities!.join(', '),
            style: TextStyle(fontSize: 16),
          ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Prevents inner scrolling
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        bool isAdded = addedIngredients.contains(ingredients[index]);
        return Row(
          children: [
            IconButton(
              icon: Icon(
                isAdded ? Icons.check_circle : Icons.add_circle,
                color: Colors.orange,
              ),
              onPressed: () async {
                if (isAdded) {
                  await _removeFromShoppingList(ingredients[index]);
                } else {
                  await _addToShoppingList(ingredients[index]);
                }
              },
            ),
            Text(ingredients[index], style: TextStyle(fontSize: 16)),
          ],
        );
      },
    );
  }

  Future<void> _addToShoppingList(String ingredient) async {
    DocumentReference shoppingListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('shoppingList')
        .doc(widget.recipe.id);

    await shoppingListRef.set({
      'recipeId': widget.recipe.id,
      'recipeName': widget.recipe.name,
      'recipeImageUrl': widget.recipe.imageUrl,
      'recipeCookingTime': widget.recipe.cookingTime,
      'recipeRating': widget.recipe.rating,
      'ingredients': FieldValue.arrayUnion([ingredient])
    }, SetOptions(merge: true));

    setState(() {
      addedIngredients.add(ingredient);
    });
  }

  Future<void> _removeFromShoppingList(String ingredient) async {
    DocumentReference shoppingListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('shoppingList')
        .doc(widget.recipe.id);

    await shoppingListRef.set({
      'recipeId': widget.recipe.id,
      'recipeName': widget.recipe.name,
      'ingredients': FieldValue.arrayRemove([ingredient])
    }, SetOptions(merge: true));

    setState(() {
      addedIngredients.remove(ingredient);
    });
  }

  Widget _buildCookingStepsSection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Prevents inner scrolling
      itemCount: cookingSteps.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${cookingSteps[index]}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: noteController,
          decoration: InputDecoration(
            hintText: 'Add your notes here...',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, color: Colors.orange),
              onPressed: () {
                setState(() {
                  _addNote();
                });
              },
            ),
          ),
        ),
        SizedBox(height: 16),
        ...notes.asMap().entries.map((entry) {
          int index = entry.key;
          String note = entry.value;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(note),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      setState(() {
                        noteController.text = note;
                        editingIndex = index;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text('Delete Note'),
                          content: Text(
                              'Are you sure you want to delete this note?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _deleteNoteFromFirestore(note);
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _saveNoteToFirestore(String note) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String path = 'users/${user.uid}/recipes/${widget.recipe.id}/notes';
        if (editingIndex != null) {
          // Update existing note
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection(path)
              .where('note', isEqualTo: notes[editingIndex!])
              .get();
          if (querySnapshot.docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection(path)
                .doc(querySnapshot.docs.first.id)
                .update({
              'note': note,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // Add new note
          await FirebaseFirestore.instance.collection(path).add({
            'note': note,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error saving note: $e');
    }
  }

  Future<List<String>> _fetchNotesFromFirestore() async {
    List<String> fetchedNotes = [];
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String path = 'users/${user.uid}/recipes/${widget.recipe.id}/notes';
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance.collection(path).get();
        querySnapshot.docs.forEach((doc) {
          fetchedNotes.add(doc['note']);
        });
      }
    } catch (e) {
      print('Error fetching notes: $e');
    }
    return fetchedNotes;
  }

  void _deleteNoteFromFirestore(String note) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String path = 'users/${user.uid}/recipes/${widget.recipe.id}/notes';
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection(path)
            .where('note', isEqualTo: note)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection(path)
              .doc(querySnapshot.docs.first.id)
              .delete();
          setState(() {
            notes.remove(note);
          });
        }
      }
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  void _editNote() {
    if (editingIndex != null) {
      setState(() {
        notes[editingIndex!] = noteController.text;
        editingIndex = null;
      });
      _saveNotes();
      noteController.clear();
    }
  }

  Widget _buildRateAndReviewSection() {
    bool hasUserReviewed = reviews.any((review) => review['user'] == widget.userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...reviews.map((review) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(review['profileImage'] ?? ''),
                      backgroundColor: Colors.orange,
                      child: review['profileImage'] == null ? Text(
                        review['username'][0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ) : null,
                    ),
                    SizedBox(width: 8),
                    Text(review['username']),
                    Spacer(),
                    _buildStaticStarRating(review['rating']),
                  ],
                ),
                SizedBox(height: 8),
                Text(review['review']),
              ],
            ),
          );
        }).toList(),
        SizedBox(height: 16),
        if (!hasUserReviewed) ...[
          Text('Your Review:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          _buildEditableStarRating(),
          TextField(
            onChanged: (value) {
              userReview = value;
            },
            decoration: InputDecoration(
              hintText: 'Write your review...',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                reviews.add({
                  'user': widget.userId,
                  'rating': userRating,
                  'review': userReview,
                  'username': _username,
                  'profileImage': _profileImageUrl,
                });
                userRating = 0;
                userReview = '';
              });
              _addReview();
            },
            child: Text('Submit Review'),
          ),
        ] else ...[
          Text('Your Review:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...reviews.where((review) => review['user'] == widget.userId).map((review) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditableStarRating(),
                TextField(
                  controller: TextEditingController(text: review['review']),
                  onChanged: (value) {
                    userReview = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Edit your review...',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          review['rating'] = userRating;
                          review['review'] = userReview;
                        });
                        _updateReview();
                      },
                      child: Text('Update Review'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Review'),
                            content: Text(
                                'Are you sure you want to delete your review?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    reviews
                                        .removeWhere((r) => r['user'] == widget.userId);
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'Delete Review',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildStaticStarRating(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.yellow[700],
        );
      }),
    );
  }

  Widget _buildEditableStarRating() {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < userRating ? Icons.star : Icons.star_border,
            color: Colors.yellow[700],
          ),
          onPressed: () {
            setState(() {
              userRating = index + 1;
            });
          },
        );
      }),
    );
  }

  Widget _buildRecommendedRecipe(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(
              userId: widget.userId,
              recipe: recipe,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        width: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                recipe.imageUrl,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                recipe.name,
                style: TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(recipe.cookingTime, style: TextStyle(fontSize: 12)),
                  Spacer(),
                  Icon(Icons.star, color: Colors.yellow[500], size: 16),
                  SizedBox(width: 4),
                  Text(recipe.rating.toString(), style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
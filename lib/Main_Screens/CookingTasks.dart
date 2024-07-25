import 'package:flutter/material.dart';
import 'package:flutter_application_1/Main_Screens/SavedRecipes.dart';
import 'package:flutter_application_1/Main_Screens/UserRecipes.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/sharedCode/Recipe_Model.dart';

class CookingSchedulerPage extends StatefulWidget {
  @override
  _CookingSchedulerPageState createState() => _CookingSchedulerPageState();
}

class _CookingSchedulerPageState extends State<CookingSchedulerPage> {
  List<Recipe> todayRecipes = [];
  Map<String, List<Recipe>> weeklyRecipesData = {};
  List<Recipe> unscheduledRecipes = [];
  DateTime currentWeekStartDate = DateTime.now();
  int expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    currentWeekStartDate = getStartOfWeek(DateTime.now());
    fetchRecipes();
  }

  void changeWeek(int offset) {
    setState(() {
      currentWeekStartDate = currentWeekStartDate.add(Duration(days: offset * 7));
      fetchWeeklyRecipes();
    });
  }

  DateTime getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }

  String formatDateRange(DateTime start, DateTime end) {
    DateFormat formatter = DateFormat('MMM d');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  Future<void> fetchRecipes() async {
    await fetchTodayRecipes();
    await fetchWeeklyRecipes();
    await fetchUnscheduledRecipes();
  }

  Future<void> fetchTodayRecipes() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DateTime today = DateTime.now();
    String todayString = DateFormat('yyyy-MM-dd').format(today);

    final todayRecipesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookingTasks')
        .doc(todayString)
        .collection('recipes')
        .get();

    setState(() {
      todayRecipes = todayRecipesSnapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  Future<void> fetchWeeklyRecipes() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DateTime startOfWeek = getStartOfWeek(currentWeekStartDate);

    setState(() {
      weeklyRecipesData = {};
    });

    for (int i = 0; i < 7; i++) {
      DateTime dayDate = startOfWeek.add(Duration(days: i));
      String dayString = DateFormat('yyyy-MM-dd').format(dayDate);

      final dailyRecipesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cookingTasks')
          .doc(dayString)
          .collection('recipes')
          .get();

      setState(() {
        weeklyRecipesData[DateFormat('EEEE').format(dayDate)] =
            dailyRecipesSnapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
      });
    }
  }

  Future<void> fetchUnscheduledRecipes() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    final unscheduledRecipesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookingTasks')
        .doc('unscheduled')
        .collection('recipes')
        .get();

    setState(() {
      unscheduledRecipes = unscheduledRecipesSnapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  Future<void> addRecipeToDay(String day, Recipe recipe) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DateTime startOfWeek = getStartOfWeek(currentWeekStartDate);
    DateTime dayDate = startOfWeek.add(Duration(days: getDayIndex(day)));
    String dayString = DateFormat('yyyy-MM-dd').format(dayDate);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookingTasks')
        .doc(dayString)
        .collection('recipes')
        .doc(recipe.id)
        .set(recipe.toMap());

    fetchWeeklyRecipes();
  }

  int getDayIndex(String day) {
    switch (day) {
      case 'Monday':
        return 0;
      case 'Tuesday':
        return 1;
      case 'Wednesday':
        return 2;
      case 'Thursday':
        return 3;
      case 'Friday':
        return 4;
      case 'Saturday':
        return 5;
      case 'Sunday':
        return 6;
      default:
        return 0;
    }
  }

  Future<void> addRecipeToToday(Recipe recipe) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DateTime today = DateTime.now();
    String todayString = DateFormat('yyyy-MM-dd').format(today);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookingTasks')
        .doc(todayString)
        .collection('recipes')
        .doc(recipe.id)
        .set(recipe.toMap());

    fetchTodayRecipes();
    addRecipeToDay(DateFormat('EEEE').format(today), recipe);
  }

  Future<void> addRecipeToUnscheduled(Recipe recipe) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookingTasks')
        .doc('unscheduled')
        .collection('recipes')
        .doc(recipe.id)
        .set(recipe.toMap());

    fetchUnscheduledRecipes();
  }

  Future<void> removeRecipeFromDay(String day, Recipe recipe) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DateTime startOfWeek = getStartOfWeek(currentWeekStartDate);
    DateTime dayDate = startOfWeek.add(Duration(days: getDayIndex(day)));
    String dayString = DateFormat('yyyy-MM-dd').format(dayDate);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookingTasks')
        .doc(dayString)
        .collection('recipes')
        .doc(recipe.id)
        .delete();

    fetchWeeklyRecipes();
  }

  Future<void> removeRecipeFromToday(Recipe recipe) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DateTime today = DateTime.now();
    String todayString = DateFormat('yyyy-MM-dd').format(today);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookingTasks')
        .doc(todayString)
        .collection('recipes')
        .doc(recipe.id)
        .delete();

    fetchTodayRecipes();
    removeRecipeFromDay(DateFormat('EEEE').format(today), recipe);
  }

  Future<void> removeRecipeFromUnscheduled(Recipe recipe) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cookingTasks')
        .doc('unscheduled')
        .collection('recipes')
        .doc(recipe.id)
        .delete();

    fetchUnscheduledRecipes();
  }

  @override
  Widget build(BuildContext context) {
    String weekDateRange = formatDateRange(
        currentWeekStartDate, currentWeekStartDate.add(Duration(days: 6)));
    String today = DateFormat('EEEE, MMM d').format(DateTime.now());
    int todayRecipeCount = todayRecipes.length;
    int thisWeekRecipeCount = weeklyRecipesData.values.fold<int>(
        0, (sum, dayRecipes) => sum + dayRecipes.length);
    int unscheduledRecipeCount = unscheduledRecipes.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text('Cooking Scheduler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(text: 'Today ($todayRecipeCount)'),
              Tab(text: 'This Week ($thisWeekRecipeCount)'),
              Tab(text: 'Unscheduled ($unscheduledRecipeCount)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildTodayTab(today),
            buildThisWeekTab(weekDateRange),
            buildUnscheduledTab(),
          ],
        ),
      ),
    );
  }

  Widget buildTodayTab(String today) {
    return RefreshIndicator(
      onRefresh: fetchRecipes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              today,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                showRecipeSourceMenu(context, (selectedRecipe) {
                  addRecipeToToday(selectedRecipe);
                });
              },
              icon: Icon(Icons.add, size: 20, color: Colors.orange),
              label: Text('Add', style: TextStyle(color: Colors.orange)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.orange, width: 2),
                elevation: 0,
              ),
            ),
          ),
          Expanded(
            child: todayRecipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                          child: Text(
                            'There are no cooking tasks for today, please add recipes',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: todayRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = todayRecipes[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to recipe details page
                        },
                        child: Card(
                          color: Colors.grey[50],
                          margin: EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Image.network(
                                      recipe.imageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey,
                                          child: Icon(Icons.broken_image),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe.name,
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 16, color: Colors.grey),
                                              SizedBox(width: 4),
                                              Text(recipe.cookingTime, style: TextStyle(color: Colors.grey)),
                                              SizedBox(width: 16),
                                              Icon(Icons.star, size: 16, color: Colors.yellow),
                                              SizedBox(width: 4),
                                              Text('${recipe.rating}', style: TextStyle(color: Colors.grey)),
                                            ],
                                          ),
                                          Text(
                                            recipe.source == 'CookUp' ? 'CookUp' : 'Chef ${recipe.source}',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: Text('Delete Recipe'),
                                              content: Text('Are you sure you want to remove this recipe?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    removeRecipeFromToday(recipe);
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildThisWeekTab(String weekDateRange) {
    return RefreshIndicator(
      onRefresh: fetchRecipes,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => changeWeek(-1),
              ),
              Text(weekDateRange, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () => changeWeek(1),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, dayIndex) {
                DateTime dayDate = currentWeekStartDate.add(Duration(days: dayIndex));
                String dayString = DateFormat('EEEE').format(dayDate);
                List<Recipe> dayRecipes = weeklyRecipesData[dayString] ?? [];
                bool isExpanded = dayIndex == expandedIndex;

                return Column(
                  children: [
                    ListTile(
                      title: Text('$dayString (${dayRecipes.length})'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                            onPressed: () {
                              setState(() {
                                expandedIndex = isExpanded ? -1 : dayIndex;
                              });
                            },
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              showRecipeSourceMenu(context, (selectedRecipe) {
                                addRecipeToDay(dayString, selectedRecipe);
                              });
                            },
                            child: Text('+ Add', style: TextStyle(color: Colors.orange)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Column(
                        children: dayRecipes.map((recipe) {
                          return GestureDetector(
                            onTap: () {
                              // Navigate to recipe details page
                            },
                            child: Card(
                              color: Colors.grey[50],
                              margin: EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Image.network(
                                          recipe.imageUrl,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey,
                                              child: Icon(Icons.broken_image),
                                            );
                                          },
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipe.name,
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                  SizedBox(width: 4),
                                                  Text(recipe.cookingTime, style: TextStyle(color: Colors.grey)),
                                                  SizedBox(width: 16),
                                                  Icon(Icons.star, size: 16, color: Colors.yellow),
                                                  SizedBox(width: 4),
                                                  Text('${recipe.rating}', style: TextStyle(color: Colors.grey)),
                                                ],
                                              ),
                                              Text(
                                                recipe.source == 'CookUp' ? 'CookUp' : 'Chef ${recipe.source}',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  title: Text('Delete Recipe'),
                                                  content: Text('Are you sure you want to remove this recipe?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        removeRecipeFromDay(dayString, recipe);
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUnscheduledTab() {
    return RefreshIndicator(
      onRefresh: fetchRecipes,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 20),
            margin: EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              icon: Icon(Icons.add, color: Colors.orange),
              label: Text('Add', style: TextStyle(color: Colors.orange)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.orange, width: 2),
              ),
              onPressed: () async {
                showRecipeSourceMenu(context, (selectedRecipe) {
                  addRecipeToUnscheduled(selectedRecipe);
                });
              },
            ),
          ),
          Expanded(
            child: unscheduledRecipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                          child: Text(
                            'There are no cooking tasks to be scheduled, please add recipes',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: unscheduledRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = unscheduledRecipes[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to recipe details page
                        },
                        child: Card(
                          color: Colors.grey[50],
                          margin: EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Image.network(
                                      recipe.imageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey,
                                          child: Icon(Icons.broken_image),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe.name,
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 16, color: Colors.grey),
                                              SizedBox(width: 4),
                                              Text(recipe.cookingTime, style: TextStyle(color: Colors.grey)),
                                              SizedBox(width: 16),
                                              Icon(Icons.star, size: 16, color: Colors.yellow),
                                              SizedBox(width: 4),
                                              Text('${recipe.rating}', style: TextStyle(color: Colors.grey)),
                                            ],
                                          ),
                                          Text(
                                            recipe.source == 'CookUp' ? 'CookUp' : 'Chef ${recipe.source}',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Delete Recipe'),
                                              content: Text('Are you sure you want to remove this recipe?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    removeRecipeFromUnscheduled(recipe);
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      color: Colors.grey[50],
                                      onSelected: (String result) {
                                        if (result == 'today') {
                                          addRecipeToToday(recipe);
                                          removeRecipeFromUnscheduled(recipe);
                                        } else if (result == 'week') {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: Colors.grey[50],
                                                title: Text('Select Day'),
                                                content: Container(
                                                  width: double.minPositive,
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: 7,
                                                    itemBuilder: (context, dayIndex) {
                                                      DateTime dayDate = currentWeekStartDate.add(Duration(days: dayIndex));
                                                      String dayString = DateFormat('EEEE').format(dayDate);
                                                      return ListTile(
                                                        title: Text(dayString),
                                                        onTap: () {
                                                          addRecipeToDay(dayString, recipe);
                                                          removeRecipeFromUnscheduled(recipe);
                                                          Navigator.of(context).pop();
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'today',
                                          child: Text('Add to Today\'s Tasks'),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'week',
                                          child: Text('Add to Week\'s Tasks'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void showRecipeSourceMenu(BuildContext context, Function(Recipe) onRecipeSelected) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select Recipe Source'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              final selectedRecipe = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserRecipesPage(),
                  settings: RouteSettings(arguments: {'fromScheduler': true}),
                ),
              );
              if (selectedRecipe != null) {
                onRecipeSelected(selectedRecipe);
              }
            },
            child: Text('My Recipes'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              final selectedRecipe = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedRecipes(),
                  settings: RouteSettings(arguments: {'fromScheduler': true}),
                ),
              );
              if (selectedRecipe != null) {
                onRecipeSelected(selectedRecipe);
              }
            },
            child: Text('Saved Recipes'),
          ),
        ],
      ),
    );
  }
}

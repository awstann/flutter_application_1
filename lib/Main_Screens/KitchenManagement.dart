import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_application_1/Main_Screens/CookUpCommunity.dart';
import 'package:flutter_application_1/Main_Screens/CookingTasks.dart';
import 'package:flutter_application_1/Main_Screens/HomePage.dart';
import 'package:flutter_application_1/Main_Screens/NewRecipePage.dart';
import 'package:flutter_application_1/Main_Screens/SavedRecipes.dart';
import 'package:flutter_application_1/Main_Screens/ShoppingList.dart';
import 'package:flutter_application_1/Main_Screens/UserProfilePage.dart';
import 'package:flutter_application_1/Main_Screens/UserRecipes.dart';

import 'package:firebase_auth/firebase_auth.dart';

class KitchenManagementPage extends StatefulWidget {
  @override
  State<KitchenManagementPage> createState() => _KitchenManagementPageState();
}

class _KitchenManagementPageState extends State<KitchenManagementPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  void _fetchUser() {
    User? user = _auth.currentUser;
    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 1;

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange.shade300,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Kitchen Management',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
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
      body: Center(
        child: GridView.count(
          crossAxisCount: 2,
          padding: EdgeInsets.all(16.0),
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: <Widget>[
            _buildGridItem(context, Icons.create, 'Create Recipe', NewRecipePage()),
            _buildGridItem(context, Icons.book, 'My Recipes', UserRecipesPage()),
            _buildGridItem(context, Icons.calendar_month, 'Cooking Tasks', CookingSchedulerPage()),
            _buildGridItem(
              context,
              Icons.shopping_cart,
              'Shopping List',
              _user != null ? IngredientShoppingList(userId: _user!.uid) : Container(), //
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String title, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 50.0,
              color: Colors.orange,
            ),
            SizedBox(height: 10.0),
            Text(
              title,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateRecipePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Recipe'),
      ),
      body: Center(
        child: Text('Create Recipe Page'),
      ),
    );
  }
}

class MyRecipesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'My Recipes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text('My Recipes Page'),
      ),
    );
  }
}

class SavedRecipesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text('Saved Recipes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Text('Saved Recipes Page'),
      ),
    );
  }
}

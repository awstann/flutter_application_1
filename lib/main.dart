
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Main_Screens/CookUpCommunity.dart';
import 'package:flutter_application_1/Main_Screens/CookingLesson.dart';
import 'package:flutter_application_1/Main_Screens/CookingTasks.dart';
import 'package:flutter_application_1/Main_Screens/CreateRecipeUsingAI.dart';
import 'package:flutter_application_1/Main_Screens/HomePage.dart';
import 'package:flutter_application_1/Main_Screens/KitchenManagement.dart';
import 'package:flutter_application_1/Main_Screens/LibyanTraditionalFood.dart';
import 'package:flutter_application_1/Main_Screens/NewRecipePage.dart';
import 'package:flutter_application_1/Main_Screens/NotificationPage.dart';
import 'package:flutter_application_1/Main_Screens/OnBoardingScreens.dart';
import 'package:flutter_application_1/Main_Screens/RecipeDetailsPage.dart';
import 'package:flutter_application_1/Main_Screens/SavedRecipes.dart';
import 'package:flutter_application_1/Main_Screens/SearchPage.dart';
import 'package:flutter_application_1/Main_Screens/ShoppingList.dart';
import 'package:flutter_application_1/Main_Screens/SignUpScreen.dart';
import 'package:flutter_application_1/Main_Screens/UserProfilePage.dart';
import 'package:flutter_application_1/Main_Screens/UserRecipes.dart';
import 'package:flutter_application_1/Services/Auth_State_Handler.dart';
import 'Main_Screens/LogInScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cooking App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: AuthStateHandler(),
      debugShowCheckedModeBanner: false,
    );
  }
}

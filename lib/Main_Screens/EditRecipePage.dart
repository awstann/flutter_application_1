import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_1/sharedCode/Recipe_Model.dart';

class EditRecipePage extends StatefulWidget {
  final Recipe recipe;

  EditRecipePage({required this.recipe});

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final picker = ImagePicker();
  String? _recipeType;
  String? _category;
  String? _occasion;
  String? _timeUnit;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _ingredientsControllers = [];
  final TextEditingController _cookingTimeController = TextEditingController();
  final List<TextEditingController> _cookingStepsController = [];

  final TextEditingController _backgroundStoryController =
      TextEditingController();
  final TextEditingController _famousCitiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController.text = widget.recipe.name;
    _descriptionController.text = widget.recipe.description;
    _cookingTimeController.text = widget.recipe.cookingTime.split(' ')[0];
    _timeUnit = widget.recipe.cookingTime.split(' ')[1];
    _recipeType = widget.recipe.type;
    _category = widget.recipe.category;

    for (var ingredient in widget.recipe.ingredients) {
      _ingredientsControllers.add(TextEditingController(text: ingredient));
    }

    for (var step in widget.recipe.cookingSteps) {
      _cookingStepsController.add(TextEditingController(text: step));
    }

    if (_recipeType == 'Traditional Food') {
      _backgroundStoryController.text = widget.recipe.backgroundStory ?? '';
      _famousCitiesController.text = widget.recipe.famousCities?.join(', ') ?? '';
      _occasion = widget.recipe.occasion ?? '';
    }
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  void _addIngredientField() {
    setState(() {
      _ingredientsControllers.add(TextEditingController());
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _ingredientsControllers.removeAt(index);
    });
  }

  void _removeStepField(int index) {
    setState(() {
      _cookingStepsController.removeAt(index);
    });
  }

  void _addStepField() {
    setState(() {
      _cookingStepsController.add(TextEditingController());
    });
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl = widget.recipe.imageUrl;
        if (_image != null) {
          UploadTask uploadTask = FirebaseStorage.instance
              .ref('recipe_images/${user.uid}/${DateTime.now().toIso8601String()}')
              .putFile(_image!);
          TaskSnapshot taskSnapshot = await uploadTask;
          imageUrl = await taskSnapshot.ref.getDownloadURL();
        }

        List<String> ingredients = _ingredientsControllers
            .map((controller) => controller.text)
            .toList();

        List<String> cookingSteps = _cookingStepsController
            .map((controller) => controller.text)
            .toList();

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        String creator = 'CookUp'; // Default to 'CookUp' for admin
        if (userDoc.exists) {
          String role = userDoc['role'];
          if (role == 'chef' || role == 'user') {
            creator = userDoc['username'];
          }
        }

        Map<String, dynamic> recipeData = {
          'imageUrl': imageUrl,
          'name': _nameController.text,
          'description': _descriptionController.text.isEmpty
              ? 'There is no description for this recipe'
              : _descriptionController.text,
          'ingredients': ingredients,
          'cookingSteps': cookingSteps,
          'cookingTime': _cookingTimeController.text + ' ' + (_timeUnit ?? ''),
          'type': _recipeType,
          'category': _category,
          'rating': widget.recipe.rating,
          'bookmark': widget.recipe.by,
          'by': creator,
        };

        if (_recipeType == 'Traditional Food') {
          recipeData.addAll({
            'backgroundStory': _backgroundStoryController.text,
            'occasion': _occasion,
            'famousCities': _famousCitiesController.text.split(',').map((e) => e.trim()).toList(),
          });
        }

        // Check if the document exists before attempting to update it
        DocumentReference userRecipeDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('recipes')
            .doc(widget.recipe.id);

        DocumentSnapshot userRecipeSnapshot = await userRecipeDoc.get();

        if (userRecipeSnapshot.exists) {
          // Update the recipe in the user's "recipes" collection
          await userRecipeDoc.update(recipeData);
        } else {
          // Handle the case where the document does not exist
          print('User recipe document does not exist.');
        }

        // Optionally update the recipe in the appropriate global collection if the user is an admin or chef
        if (userDoc.exists) {
          String role = userDoc['role'];
          DocumentReference globalRecipeDoc;

          if (role == 'admin') {
            globalRecipeDoc = FirebaseFirestore.instance
                .collection('recipes')
                .doc(widget.recipe.id);
          } else if (role == 'chef') {
            globalRecipeDoc = FirebaseFirestore.instance
                .collection('chefsRecipes')
                .doc(widget.recipe.id);
          } else {
            globalRecipeDoc = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('recipes')
                .doc(widget.recipe.id);
          }

          DocumentSnapshot globalRecipeSnapshot = await globalRecipeDoc.get();

          if (globalRecipeSnapshot.exists) {
            // Update the global recipe document
            await globalRecipeDoc.update(recipeData);
          } else {
            // Handle the case where the document does not exist
            print('Global recipe document does not exist.');
          }
        }

        // Reset the input fields
        _resetFormFields();

        // Navigate back to the previous page
        Navigator.pop(context);
      }
    }
  }

  void _resetFormFields() {
    setState(() {
      _image = null;
      _nameController.clear();
      _descriptionController.clear();
      _ingredientsControllers.clear();
      _ingredientsControllers.add(TextEditingController());
      _cookingTimeController.clear();
      _cookingStepsController.clear();
      _cookingStepsController.add(TextEditingController());
      _recipeType = null;
      _category = null;
      _occasion = null;
      _backgroundStoryController.clear();
      _famousCitiesController.clear();
      _timeUnit = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var controller in _ingredientsControllers) {
      controller.dispose();
    }
    _cookingTimeController.dispose();
    for (var controller in _cookingStepsController) {
      controller.dispose();
    }

    _backgroundStoryController.dispose();
    _famousCitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Colors.orange.shade300,
        title: Text(
          'Edit Recipe',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _image == null
                  ? (widget.recipe.imageUrl.isNotEmpty
                      ? Image.network(widget.recipe.imageUrl)
                      : IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: getImage,
                          iconSize: 100,
                          color: Colors.orange,
                        ))
                  : Image.file(_image!),
              SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Recipe Name',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a recipe name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 10),
              Column(
                children: _ingredientsControllers.asMap().entries.map((entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Ingredient',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an ingredient';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      if (index > 0)
                        IconButton(
                          icon: Icon(Icons.remove_circle),
                          color: Colors.red,
                          onPressed: () => _removeIngredientField(index),
                        ),
                    ],
                  );
                }).toList(),
              ),
              IconButton(
                icon: Icon(Icons.add),
                color: Colors.orange,
                onPressed: _addIngredientField,
                iconSize: 30,
                padding: EdgeInsets.all(8),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cookingTimeController,
                      decoration: InputDecoration(
                        labelText: 'Cooking Time',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter cooking time';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _timeUnit,
                    items: ['mins', 'hrs']
                        .map((unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    hint: Text('Select unit'),
                    onChanged: (value) {
                      setState(() {
                        _timeUnit = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _recipeType != null &&
                        [
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
                        ].contains(_recipeType)
                    ? _recipeType
                    : null,
                decoration: InputDecoration(
                  labelText: 'Type',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                items: [
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
                ]
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _recipeType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a recipe type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _category != null &&
                        ['Breakfast', 'Lunch', 'Dinner', 'Eid\'s', 'Occasions']
                            .contains(_category)
                    ? _category
                    : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                items: ['Breakfast', 'Lunch', 'Dinner', 'Eid\'s', 'Occasions']
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              if (_recipeType == 'Traditional Food')
                Column(
                  children: [
                    TextFormField(
                      controller: _backgroundStoryController,
                      decoration: InputDecoration(
                        labelText: 'Background Story',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a background story';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _famousCitiesController,
                      decoration: InputDecoration(
                        labelText: 'Famous Cities',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter famous cities';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _occasion != null &&
                              ['Wedding', 'Eid', 'Ramadan', 'Party', 'Festival', 'Dessert']
                                  .contains(_occasion)
                          ? _occasion
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Occasion',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      items: [
                        'Wedding',
                        'Eid',
                        'Ramadan',
                        'Party',
                        'Festival',
                        'Dessert'
                      ]
                          .map((occasion) => DropdownMenuItem<String>(
                                value: occasion,
                                child: Text(occasion),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _occasion = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an occasion';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              Column(
                children: _cookingStepsController.asMap().entries.map((entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Cooking Step',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a cooking step';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      if (index > 0)
                        IconButton(
                          icon: Icon(Icons.remove_circle),
                          color: Colors.red,
                          onPressed: () => _removeStepField(index),
                        ),
                    ],
                  );
                }).toList(),
              ),
              IconButton(
                icon: Icon(Icons.add),
                color: Colors.orange,
                onPressed: _addStepField,
                iconSize: 30,
                padding: EdgeInsets.all(8),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: _saveRecipe,
                child: Text('Save Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

class CookingLessonsPage extends StatefulWidget {
  @override
  _CookingLessonsPageState createState() => _CookingLessonsPageState();
}

class _CookingLessonsPageState extends State<CookingLessonsPage> {
  bool isAdmin = false;
  bool isUser = false;
  late User loggedInUser;

  @override
  void initState() {
    super.initState();
    checkUserRole();
  }

  Future<void> checkUserRole() async {
    loggedInUser = FirebaseAuth.instance.currentUser!;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(loggedInUser.uid)
        .get();

    setState(() {
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('role')) {
          isAdmin = userData['role'] == 'admin';
          isUser = userData['role'] == 'user';
        }
      }
    });
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
          'Cooking Lessons',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection('CookingLessons').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No Cooking Lessons yet',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          var lessons = snapshot.data!.docs.map((doc) {
            return Lesson.fromDocument(doc);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LessonDetailPage(
                                lessonId: lessons[index].id,
                              ),
                            ),
                          );
                        },
                        child: LessonCard(lesson: lessons[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateLessonPage()),
                );
              },
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
              backgroundColor: Colors.orange.shade500,
            )
          : null,
    );
  }
}

class CreateLessonPage extends StatefulWidget {
  @override
  _CreateLessonPageState createState() => _CreateLessonPageState();
}

class _CreateLessonPageState extends State<CreateLessonPage> {
  File? _lessonImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<InstructionField> _instructionFields = [];

  @override
  void initState() {
    super.initState();
    _addInstructionField(); // Initialize with one instruction field
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var field in _instructionFields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  void _addInstructionField() {
    setState(() {
      _instructionFields.add(
        InstructionField(controller: TextEditingController()),
      );
    });
  }

  Future<void> _pickLessonImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _lessonImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveLesson() async {
    if (_lessonImage == null ||
        _nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _instructionFields.any((field) => field.controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Upload image to Firebase Storage
    String imageUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('lesson_images')
          .child(DateTime.now().toIso8601String() + '.jpg');
      await ref.putFile(_lessonImage!);
      imageUrl = await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed')),
      );
      return;
    }

    // Convert lesson instructions to a format suitable for Firestore
    List<Map<String, dynamic>> instructionsData = [];
    for (var field in _instructionFields) {
      String? mediaUrl;
      if (field.mediaFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('lesson_instructions')
            .child(DateTime.now().toIso8601String() +
                (field.type == StepType.image ? '.jpg' : '.mp4'));
        await ref.putFile(field.mediaFile!);
        mediaUrl = await ref.getDownloadURL();
      }
      instructionsData.add({
        'type': field.type.index,
        'text': field.controller.text,
        'mediaUrl': mediaUrl,
      });
    }

    // Save lesson to Firestore
    final lessonData = {
      'image': imageUrl,
      'name': _nameController.text,
      'description': _descriptionController.text,
      'instructions': instructionsData,
    };

    try {
      await FirebaseFirestore.instance
          .collection('CookingLessons')
          .add(lessonData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lesson saved successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lesson save failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Lesson'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickLessonImage,
              child: Text('Pick Lesson Image'),
            ),
            if (_lessonImage != null) Image.file(_lessonImage!),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Lesson Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Lesson Description'),
            ),
            ..._instructionFields.map((field) {
              return Column(
                children: [
                  TextField(
                    controller: field.controller,
                    decoration: InputDecoration(labelText: 'Instruction Text'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          field.mediaFile = File(pickedFile.path);
                          field.type = StepType.image;
                        });
                      }
                    },
                    child: Text('Pick Instruction Image'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          field.mediaFile = File(pickedFile.path);
                          field.type = StepType.video;
                        });
                      }
                    },
                    child: Text('Pick Instruction Video'),
                  ),
                  if (field.mediaFile != null)
                    field.type == StepType.image
                        ? Image.file(field.mediaFile!)
                        : Text('Video selected: ${field.mediaFile!.path}'),
                ],
              );
            }).toList(),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _addInstructionField,
            ),
            ElevatedButton(
              onPressed: _saveLesson,
              child: Text('Save Lesson'),
            ),
          ],
        ),
      ),
    );
  }
}


class InstructionField {
  final TextEditingController controller;
  File? mediaFile;
  StepType type;

  InstructionField({
    required this.controller,
    this.mediaFile,
    this.type = StepType.text,
  });
}


class LessonDetailPage extends StatelessWidget {
  final String lessonId;

  LessonDetailPage({required this.lessonId})
      : assert(lessonId.isNotEmpty, 'Lesson ID must be a non-empty string');

  Future<Lesson> _fetchLesson() async {
    final doc = await FirebaseFirestore.instance
        .collection('CookingLessons')
        .doc(lessonId)
        .get();
    return Lesson.fromDocument(doc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange[300],
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Lesson Details',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: FutureBuilder<Lesson>(
        future: _fetchLesson(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Lesson not found'));
          } else {
            final lesson = snapshot.data!;
            return ListView(
              padding: EdgeInsets.all(16.0),
              children: <Widget>[
                Image.network(lesson.image),
                SizedBox(height: 16.0),
                Text(
                  lesson.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(lesson.description),
                SizedBox(height: 16.0),
                Column(
                  children: List.generate(lesson.steps.length, (index) {
                    final step = lesson.steps[index];
                    return ExpansionTile(
                      title: Text(
                        'Step ${index + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildStepContent(step),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStepContent(LessonStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (step.mediaUrl.isNotEmpty) ...[
          step.type == StepType.image
              ? Image.network(step.mediaUrl)
              : VideoPlayerWidget(videoUrl: step.mediaUrl),
          SizedBox(height: 8.0),
        ],
        Text(step.content, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}


class Lesson {
  final String id;
  final String image;
  final String name;
  final String description;
  final List<LessonStep> steps;

  Lesson({
    required this.id,
    required this.image,
    required this.name,
    required this.description,
    required this.steps,
  });

  factory Lesson.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final stepsData = data['instructions'] as List<dynamic>? ?? [];
    final steps = stepsData.map((stepData) {
      return LessonStep.fromMap(stepData as Map<String, dynamic>);
    }).toList();

    return Lesson(
      id: doc.id,
      image: data['image'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      steps: steps,
    );
  }
}

// lesson_step.dart
enum StepType { text, image, video }

class LessonStep {
  final StepType type;
  final String content;
  final String mediaUrl;

  LessonStep({
    required this.type,
    required this.content,
    required this.mediaUrl,
  });

  factory LessonStep.fromMap(Map<String, dynamic> data) {
    return LessonStep(
      type: data['type'] != null
          ? StepType.values[data['type']]
          : StepType.text, // Default to StepType.text if null
      content: data['text'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'content': content,
      'mediaUrl': mediaUrl,
    };
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _restart() {
    setState(() {
      _controller.seekTo(Duration.zero);
      _controller.play();
    });
  }

  void _fastForward() {
    setState(() {
      final newPosition = _controller.value.position + Duration(seconds: 10);
      _controller.seekTo(newPosition);
    });
  }

  void _rewind() {
    setState(() {
      final newPosition = _controller.value.position - Duration(seconds: 10);
      _controller.seekTo(newPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Center(child: CircularProgressIndicator()),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.replay_10),
              onPressed: _rewind,
            ),
            IconButton(
              icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _playPause,
            ),
            IconButton(
              icon: Icon(Icons.forward_10),
              onPressed: _fastForward,
            ),
            IconButton(
              icon: Icon(Icons.restart_alt),
              onPressed: _restart,
            ),
          ],
        ),
      ],
    );
  }
}

class LessonCard extends StatelessWidget {
  final Lesson lesson;

  LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[50],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    lesson.image,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        lesson.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

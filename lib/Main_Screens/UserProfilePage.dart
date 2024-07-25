import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Main_Screens/CookUpCommunity.dart';
import 'package:flutter_application_1/Main_Screens/HomePage.dart';
import 'package:flutter_application_1/Main_Screens/KitchenManagement.dart';
import 'package:flutter_application_1/Main_Screens/SavedRecipes.dart';
import 'package:flutter_application_1/Services/Auth_State_Handler.dart';
import 'package:flutter_application_1/sharedCode/Recipe_Model.dart';
import 'package:image_picker/image_picker.dart';
import 'RecipeDetailsPage.dart';

class Userprofilepage extends StatefulWidget {
  const Userprofilepage({super.key});

  @override
  State<Userprofilepage> createState() => _UserprofilepageState();
}

class _UserprofilepageState extends State<Userprofilepage> {
  int _selectedIndex = 4;
  String _username = '';
  String _email = '';
  String _bio = '';
  String _profileImageUrl = '';
  File? _profileImage;
  List<Post> posts = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CookUpCommunity()));
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
          _email = data['email'] ?? '';
          _bio = data.containsKey('bio') ? data['bio'] : '';
          _profileImageUrl = data.containsKey('profileImageUrl')
              ? data['profileImageUrl']
              : '';
        });
      }
    }
  }

  Future<void> _fetchUserPosts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot postDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posts')
          .orderBy('postDate', descending: true)
          .get();
      setState(() {
        posts = postDocs.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Post(
            doc.id,
            data['userId'] ?? '',
            data['username'] ?? '',
            data['profileImage'] ?? '',
            data['content'] ?? '',
            data['postImageUrl'] ?? '',
            (data['postDate'] as Timestamp).toDate(),
            List<String>.from(data['likes'] ?? []),
            List<Comment>.from(data['comments']?.map((comment) {
              return Comment.fromMap(comment);
            }) ?? []),
          );
        }).toList();
      });
    }
  }

  Future<void> _updateProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? imageUrl;
      if (_profileImage != null) {
        UploadTask uploadTask = FirebaseStorage.instance
            .ref('profile_images/${user.uid}')
            .putFile(_profileImage!);
        TaskSnapshot taskSnapshot = await uploadTask;
        imageUrl = await taskSnapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'username': _username,
        'bio': _bio,
        'profileImageUrl': imageUrl ?? _profileImageUrl,
      });

      setState(() {
        _profileImageUrl = imageUrl ?? _profileImageUrl;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserPosts();
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: Icon(Icons.logout,color: Colors.white,),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AuthStateHandler()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchUserData();
            await _fetchUserPosts();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 0, 0, 0),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildStats(),
                  _buildBio(),
                  EditProfileInfo(),
                  _buildSectionTitle("Food Recipes", "See All"),
                  _buildRecipeSection(),
                  _buildSectionTitle("Posts", "See All"),
                  _buildPostSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : _profileImageUrl.isNotEmpty
                      ? NetworkImage(_profileImageUrl)
                      : AssetImage("assets/chef_1.jpg") as ImageProvider,
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _username,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                _email,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("Following", "150"),
          _buildStat("Followers", "2000"),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String count) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _bio.isEmpty
            ? "Bio: Passionate cook and food lover. Sharing my favorite recipes and culinary adventures. Follow me for delicious recipes and cooking tips!"
            : _bio,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget EditProfileInfo() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                      username: _username,
                      bio: _bio,
                      profileImageUrl: _profileImageUrl)));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.orange, width: 2),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
        child: Text(
          "Edit Information",
          style: TextStyle(fontSize: 18, color: Colors.orange),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String seeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              seeAll,
              style: TextStyle(
                  color: Colors.blue.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecipeSection() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('recipes')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching recipes: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No recipes found.'));
        }

        return Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var recipe = snapshot.data!.docs[index];
              var recipeData = recipe.data() as Map<String, dynamic>;
              var recipeObject = Recipe.fromFirestore(recipe);

              return _buildRecipeCard(recipeObject);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              image: NetworkImage(recipe.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  recipe.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostSection() {
    return Container(
      height: 400, // Adjust the height as needed
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          Post post = posts[index];
          return PostWidget(
            post: post,
            onEdit: (newDescription) => _editPost(index, newDescription),
            onDelete: () => _deletePost(index),
            currentUserId: FirebaseAuth.instance.currentUser!.uid,
            username: _username,
            profileImageUrl: _profileImageUrl,
          );
        },
      ),
    );
  }

  void _editPost(int index, String newDescription) {
    setState(() {
      posts[index].content = newDescription;
    });
  }

  void _deletePost(int index) {
    final postId = posts[index].postId;
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .delete();
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('posts')
        .doc(postId)
        .delete();

    setState(() {
      posts.removeAt(index);
    });
  }
}

class Post {
  final String postId;
  final String userId;
  final String username;
  final String profileImage;
  String content;
  final String postImageUrl;
  final DateTime postDate;
  List<String> likes;
  List<Comment> comments;

  Post(this.postId, this.userId, this.username, this.profileImage, this.content,
      this.postImageUrl, this.postDate, this.likes, this.comments);
}

class Comment {
  final String commentId;
  final String userId;
  final String username;
  final String profileImage;
  String text;
  final DateTime date;

  Comment(this.commentId, this.userId, this.username, this.profileImage,
      this.text, this.date);

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'userId': userId,
      'username': username,
      'profileImage': profileImage,
      'text': text,
      'date': date,
    };
  }

  static Comment fromMap(Map<String, dynamic> map) {
    return Comment(
      map['commentId'],
      map['userId'],
      map['username'],
      map['profileImage'],
      map['text'],
      (map['date'] as Timestamp).toDate(),
    );
  }
}

class PostWidget extends StatefulWidget {
  final Post post;
  final Function(String) onEdit;
  final VoidCallback onDelete;
  final String currentUserId;
  final String username;
  final String profileImageUrl;

  PostWidget(
      {required this.post,
      required this.onEdit,
      required this.onDelete,
      required this.currentUserId,
      required this.username,
      required this.profileImageUrl});

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool hasComments = false;
  bool isLiked = false;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editPostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editPostController.text = widget.post.content;
    isLiked = widget.post.likes.contains(widget.currentUserId);
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final commentsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.postId)
        .collection('comments')
        .orderBy('date')
        .get();

    setState(() {
      widget.post.comments = commentsSnapshot.docs
          .map((doc) => Comment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[50],
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.profileImageUrl),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.username,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${widget.post.postDate.toLocal()}'.split(' ')[0],
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Spacer(),
                if (widget.post.userId == widget.currentUserId) ...[
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _editPost(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeletePost(context),
                  ),
                ]
              ],
            ),
            SizedBox(height: 10),
            Text(widget.post.content),
            SizedBox(height: 10),
            widget.post.postImageUrl.startsWith('http')
                ? Image.network(widget.post.postImageUrl)
                : Image.file(File(widget.post.postImageUrl)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.orange : null),
                      onPressed: () {
                        setState(() {
                          isLiked = !isLiked;
                          if (isLiked) {
                            widget.post.likes.add(widget.currentUserId);
                          } else {
                            widget.post.likes.remove(widget.currentUserId);
                          }
                        });
                        FirebaseFirestore.instance
                            .collection('posts')
                            .doc(widget.post.postId)
                            .update({'likes': widget.post.likes});
                      },
                    ),
                    Text('${widget.post.likes.length} likes'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.comment,
                          color: hasComments ? Colors.orange : Colors.grey),
                      onPressed: () => _showComments(context),
                    ),
                    Text('${widget.post.comments.length} comments'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('Edit Post'),
          content: TextField(
            controller: _editPostController,
            decoration: InputDecoration(labelText: 'Edit your post'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.onEdit(_editPostController.text);
                Navigator.of(context).pop();
              },
              child: Text(
                'Save',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.onDelete();
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.post.comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(comment.profileImage),
                        ),
                        title: Text(comment.username),
                        subtitle: Text(comment.text),
                        trailing: comment.userId == widget.currentUserId
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () {
                                      _editComment(context, index, setModalState);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _confirmDeleteComment(
                                          context, index, setModalState);
                                    },
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              labelText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.orange),
                          onPressed: () async {
                            if (_commentController.text.isNotEmpty) {
                              final newComment = Comment(
                                  FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.post.postId)
                                      .collection('comments')
                                      .doc()
                                      .id,
                                  widget.currentUserId,
                                  FirebaseAuth.instance.currentUser!.displayName!,
                                  FirebaseAuth.instance.currentUser!.photoURL ??
                                      'https://example.com/default_profile_image.png',
                                  _commentController.text,
                                  DateTime.now());
                              setState(() {
                                widget.post.comments.add(newComment);
                                _commentController.clear();
                              });
                              await FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.post.postId)
                                  .collection('comments')
                                  .doc(newComment.commentId)
                                  .set(newComment.toMap());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editComment(
      BuildContext context, int index, StateSetter setModalState) {
    TextEditingController _editController =
        TextEditingController(text: widget.post.comments[index].text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('Edit Comment'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              labelText: 'Edit your comment',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setModalState(() {
                  widget.post.comments[index].text = _editController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text('Save', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteComment(
      BuildContext context, int index, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[50],
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setModalState(() {
                  widget.post.comments.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String username;
  final String bio;
  final String profileImageUrl;

  const EditProfilePage({
    required this.username,
    required this.bio,
    required this.profileImageUrl,
    Key? key,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? imageUrl;
      if (_profileImage != null) {
        UploadTask uploadTask = FirebaseStorage.instance
            .ref('profile_images/${user.uid}')
            .putFile(_profileImage!);
        TaskSnapshot taskSnapshot = await uploadTask;
        imageUrl = await taskSnapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'username': _usernameController.text,
        'bio': _bioController.text,
        'profileImageUrl': imageUrl ?? widget.profileImageUrl,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Edit Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : widget.profileImageUrl.isNotEmpty
                        ? NetworkImage(widget.profileImageUrl)
                        : AssetImage("assets/chef_1.jpg") as ImageProvider,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: 'Bio'),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

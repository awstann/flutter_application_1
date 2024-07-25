import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Main_Screens/HomePage.dart';
import 'package:flutter_application_1/Main_Screens/KitchenManagement.dart';
import 'package:flutter_application_1/Main_Screens/SavedRecipes.dart';
import 'package:flutter_application_1/Main_Screens/UserProfilePage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


// UserProfile Class
class UserProfile {
  final String username;
  final String avatarUrl;

  UserProfile(this.username, this.avatarUrl);
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

class CookUpCommunity extends StatefulWidget {
  @override
  _CookUpCommunityState createState() => _CookUpCommunityState();
}

class _CookUpCommunityState extends State<CookUpCommunity> {
  final List<UserProfile> userProfiles = [];
  final List<Post> posts = [];
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool hasFollowings = true;
  String currentUserProfileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfileImage();
    _refreshPage();
  }

  Future<void> _fetchUserProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          currentUserProfileImageUrl =
              data['profileImageUrl'] ?? 'https://example.com/default_profile_image.png';
        });
      }
    }
  }

  Future<void> _refreshPage() async {
    await _fetchFollowedUserProfiles();
    await _fetchPostsWithComments();
  }

  Future<void> _fetchFollowedUserProfiles() async {
    final followedUsersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('following')
        .get();

    setState(() {
      userProfiles.clear();
      if (followedUsersSnapshot.docs.isEmpty) {
        hasFollowings = false;
      } else {
        hasFollowings = true;
        userProfiles.addAll(followedUsersSnapshot.docs.map((doc) {
          final data = doc.data();
          return UserProfile(
              data['username'] ?? '', data['profileImage'] ?? 'https://example.com/default_profile_image.png');
        }).toList());
      }
    });
  }

  Future<void> _fetchPostsWithComments() async {
    final postsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('postDate', descending: true)
        .get();

    final commentsFutures = postsSnapshot.docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final post = Post(
        doc.id,
        data['userId'] ?? '',
        data['username'] ?? '',
        data['profileImage'] ?? 'https://example.com/default_profile_image.png',
        data['content'] ?? '',
        data['postImageUrl'] ?? 'https://example.com/default_post_image.png',
        (data['postDate'] as Timestamp).toDate(),
        List<String>.from(data['likes'] ?? []),
        [],
      );

      final commentsSnapshot = await doc.reference.collection('comments').get();
      post.comments = commentsSnapshot.docs
          .map((commentDoc) => Comment.fromMap(commentDoc.data() as Map<String, dynamic>))
          .toList();

      return post;
    }).toList();

    final fetchedPosts = await Future.wait(commentsFutures);

    setState(() {
      posts.clear();
      posts.addAll(fetchedPosts);
      isLoading = false;
    });
  }

  void _addNewPost(String description, File imageFile) async {
    final postId = FirebaseFirestore.instance.collection('posts').doc().id;
    final postImageUrl = await _uploadImageToStorage(postId, imageFile);

    final postData = {
      'userId': currentUser!.uid,
      'username': currentUser!.displayName,
      'profileImage': currentUserProfileImageUrl,
      'content': description,
      'postImageUrl': postImageUrl,
      'postDate': Timestamp.now(),
      'likes': [],
      'comments': [],
    };

    await FirebaseFirestore.instance.collection('posts').doc(postId).set(postData);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('posts')
        .doc(postId)
        .set(postData);

    setState(() {
      posts.insert(
          0,
          Post(
            postId,
            currentUser!.uid,
            currentUser!.displayName!,
            currentUserProfileImageUrl,
            description,
            postImageUrl,
            DateTime.now(),
            [],
            [],
          ));
    });
  }

  Future<String> _uploadImageToStorage(String postId, File imageFile) async {
    final storageRef = FirebaseStorage.instance.ref().child('post_images').child('$postId.jpg');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _editPost(int index, String newDescription) {
    setState(() {
      posts[index].content = newDescription;
    });
  }

  void _deletePost(int index) {
    final postId = posts[index].postId;
    FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('posts')
        .doc(postId)
        .delete();

    setState(() {
      posts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 0;
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => CookUpCommunity()));
          break;
        case 1:
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => KitchenManagementPage()));
          break;
        case 2:
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange.shade300,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('CookUp Community',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      height: 110,
                      child: Stack(
                        children: [
                          userProfiles.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_outline,
                                          size: 50, color: Colors.grey),
                                      Text("You do not follow any users",
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: userProfiles.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return Container(
                                          width: 80); // Placeholder for the + icon
                                    } else {
                                      UserProfile user = userProfiles[index - 1];
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 35,
                                              backgroundImage:
                                                  NetworkImage(user.avatarUrl),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.orange,
                                                      width: 1),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(user.username,
                                                style: TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 80,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SearchUsersPage()));
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add,
                                          color: Colors.orange, size: 35),
                                      SizedBox(height: 5),
                                      Text('add',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.orange)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(currentUserProfileImageUrl),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.orange, width: 1),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[50],
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CreatePostPage()),
                                );
                                if (result != null) {
                                  _addNewPost(
                                      result['description'], result['imageFile']);
                                }
                              },
                              child: Text(
                                'Create Post',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    posts.isEmpty
                        ? Center(
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.post_add,
                                      size: 50, color: Colors.grey),
                                  Text("There are no posts yet, you can create a post",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              Post post = posts[index];
                              return PostWidget(
                                post: post,
                                onEdit: (newDescription) =>
                                    _editPost(index, newDescription),
                                onDelete: () => _deletePost(index),
                                currentUserId: currentUser!.uid,
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}

class PostWidget extends StatefulWidget {
  final Post post;
  final Function(String) onEdit;
  final VoidCallback onDelete;
  final String currentUserId;

  PostWidget(
      {required this.post,
      required this.onEdit,
      required this.onDelete,
      required this.currentUserId});

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
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
                  backgroundImage: NetworkImage(widget.post.profileImage),
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
                    Text(widget.post.username,
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
                          color: widget.post.comments.isNotEmpty ? Colors.orange : Colors.grey),
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

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _publishPost() async {
    if (_descriptionController.text.isNotEmpty && _imageFile != null) {
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      final postImageUrl = await _uploadImageToStorage(postId);

      final postData = {
        'userId': currentUser!.uid,
        'username': currentUser!.displayName,
        'profileImage': currentUser!.photoURL ?? 'https://example.com/default_profile_image.png',
        'content': _descriptionController.text,
        'postImageUrl': postImageUrl,
        'postDate': Timestamp.now(),
        'likes': [],
        'comments': [],
      };

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .set(postData);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('posts')
          .doc(postId)
          .set(postData);

      Navigator.of(context).pop();
    }
  }

  Future<String> _uploadImageToStorage(String postId) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('post_images')
        .child('$postId.jpg');
    final uploadTask = storageRef.putFile(_imageFile!);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                color: Colors.grey[200],
                height: 250,
                width: double.infinity,
                child: _imageFile == null
                    ? Icon(Icons.add_a_photo, size: 100, color: Colors.grey)
                    : Image.file(_imageFile!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _publishPost,
              child: Text('Publish Post'),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchUsersPage extends StatefulWidget {
  @override
  _SearchUsersPageState createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];

  Future<void> _searchUsers(String query) async {
    final searchSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .get();

    setState(() {
      _searchResults = searchSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserProfile(data['username'] ?? '', data['profileImage'] ?? 'https://example.com/default_profile_image.png');
      }).toList();
    });
  }

  Future<void> _toggleFollow(UserProfile user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (user.username == currentUser!.displayName) {
      // Prevent the user from following/unfollowing themselves
      return;
    }
    final followingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(user.username);

    final followingSnapshot = await followingRef.get();
    if (followingSnapshot.exists) {
      followingRef.delete();
    } else {
      followingRef.set({
        'username': user.username,
        'profileImage': user.avatarUrl,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for users...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.orange),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onChanged: (query) {
                  if (query.isNotEmpty) {
                    _searchUsers(query);
                  } else {
                    setState(() {
                      _searchResults = [];
                    });
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.avatarUrl),
                  ),
                  title: Text(user.username),
                  trailing: ElevatedButton(
                    onPressed: () => _toggleFollow(user),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('following')
                          .doc(user.username)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        return Text(snapshot.hasData && snapshot.data!.exists ? 'Unfollow' : 'Follow');
                      },
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
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class NotificationPage extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      'source': 'CookUp',
      'title': 'Welcome!',
      'description': 'Thanks for installing our app.',
      'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'image': 'assets/CookUp_icon.webp'
    },
    {
      'source': 'User',
      'title': 'New Message',
      'description': 'You have received a new message.',
      'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'image': 'assets/CookUp_icon.webp'
    },
    {
      'source': 'Reminder',
      'title': 'Task Reminder',
      'description': 'Don\'t forget to complete your task.',
      'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'image': 'assets/CookUp_icon.webp'
    },
    {
      'source': 'Recipe',
      'title': 'New Recipe Added',
      'description': 'Check out this new delicious recipe!',
      'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'image': 'assets/CookUp_icon.webp'
    },
    {
      'source': 'Recipe',
      'title': 'New Recipe Added',
      'description': 'Check out this new delicious recipe!',
      'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'image': 'assets/CookUp_icon.webp'
    },
    {
      'source': 'Recipe',
      'title': 'New Recipe Added',
      'description': 'Check out this new delicious recipe!',
      'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'image': 'assets/CookUp_icon.webp'
    },
    {
      'source': 'Recipe',
      'title': 'New Recipe Added',
      'description': 'Check out this new delicious recipe!',
      'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'image': 'assets/chef_1.jpg'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Dismissible(
            key: Key(notification['title']!),
            background: slideLeftBackground(),
            secondaryBackground: slideLeftBackground(),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                final action = await showModalBottomSheet<Action>(
                  context: context,
                  builder: (context) => ActionSheet(),
                );
                return action == Action.delete;
              }
              return false;
            },
            child: GestureDetector(
              onTap: () {
                // Handle navigation to the source
                // For example, navigate to different screens based on the source
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationSourcePage(source: notification['source']!),
                  ),
                );
              },
              child: NotificationTile(notification: notification),
            ),
          );
        },
      ),
    );
  }

  Widget slideLeftBackground() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Icon(Icons.delete, color: Colors.red),
          SizedBox(width: 10),
          Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }
}

enum Action { delete, accept }

class ActionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Wrap(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete'),
            onTap: () => Navigator.of(context).pop(Action.delete),
          ),
          ListTile(
            leading: Icon(Icons.check, color: Colors.green),
            title: Text('Accept'),
            onTap: () => Navigator.of(context).pop(Action.accept),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final Map<String, String> notification;

  NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Colors.grey[50],
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Image.asset(
          notification['image']!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
        title: Text(
          notification['title']!,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['description']!),
            SizedBox(height: 2),
            Text(notification['source']!, style: TextStyle(fontStyle: FontStyle.italic)),
            Text(notification['time']!, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class NotificationSourcePage extends StatelessWidget {
  final String source;

  NotificationSourcePage({required this.source});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(source),
      ),
      body: Center(
        child: Text('This is the $source page'),
      ),
    );
  }
}
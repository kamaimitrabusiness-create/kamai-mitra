import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase skip: $e");
  }

  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  runApp(const MaterialApp(home: HomeScreen(), debugShowCheckedModeBanner: false));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int balance = 0;

  @override
  void initState() {
    super.initState();
    try {
      FirebaseDatabase.instance.ref("user_balance").onValue.listen((event) {
        if (mounted && event.snapshot.value != null) {
          setState(() => balance = int.tryParse(event.snapshot.value.toString()) ?? 0);
        }
      });
    } catch (e) {
      debugPrint("DB error: $e");
    }
  }

  void _openTaskList(String type) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => TaskListScreen(type: type)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kamai Mitra"), backgroundColor: Colors.green),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(30),
            child: Text("₹$balance", style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          _buildMenu(Icons.assignment, "Survey Tasks", () => _openTaskList("surveys")),
          _buildMenu(Icons.download, "App Install Tasks", () => _openTaskList("apps")),
        ],
      ),
    );
  }

  Widget _buildMenu(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.all(10), 
      child: ListTile(leading: Icon(icon), title: Text(title), onTap: onTap)
    );
  }
}

class TaskListScreen extends StatelessWidget {
  final String type;
  const TaskListScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${type.toUpperCase()} Tasks"), backgroundColor: Colors.green),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("tasks/$type").onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("Koi task nahi hai"));

          final data = snapshot.data!.snapshot.value;
          List<dynamic> list = data is Map ? data.values.toList() : (data as List);

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final item = list[i] as Map<dynamic, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.green, size: 40),
                  title: Text(item['title'] ?? 'No Title'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final url = item['link'];
                      if (url != null) {
                        final Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      }
                    },
                    child: const Text("Open"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
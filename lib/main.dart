import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint("Ads skip: $e");
    }
  }
  
  runApp(const MaterialApp(home: HomeScreen(), debugShowCheckedModeBanner: false));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase hat gaya hai, yahan static balance dikhayenge
  int balance = 0;

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

  void _openTaskList(String type) {
    // Abhi ke liye ye screen khulegi, par database load nahi hoga
    Navigator.push(context, MaterialPageRoute(builder: (context) => TaskListScreen(type: type)));
  }
}

class TaskListScreen extends StatelessWidget {
  final String type;
  const TaskListScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${type.toUpperCase()} Tasks"), backgroundColor: Colors.green),
      body: const Center(child: Text("Firebase connection remove kar diya hai, ab app crash nahi hogi!")),
    );
  }
}
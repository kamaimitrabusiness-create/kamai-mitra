import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // Firebase initialization ko try-catch mein rakha hai taaki crash na ho
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDfc9qqDr_C6BW6rm8LCscof9nvy5X0sUM",
        authDomain: "kamai-mitra.firebaseapp.com",
        databaseURL: "https://kamai-mitra-default-rtdb.firebaseio.com",
        projectId: "kamai-mitra",
        storageBucket: "kamai-mitra.firebasestorage.app",
        messagingSenderId: "468801020264",
        appId: "1:468801020264:web:96e358c2bdfdba95f2f6dd",
      ),
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  if (!kIsWeb) AdHelper.loadRewardedAd();

  runApp(const MaterialApp(home: HomeScreen(), debugShowCheckedModeBanner: false));
}

class AdHelper {
  static RewardedAd? _rewardedAd;

  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) => _rewardedAd = null,
      ),
    );
  }

  static void showRewardedAd(VoidCallback onRewardEarned) {
    if (kIsWeb) {
      onRewardEarned();
      return;
    }
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewardedAd();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onRewardEarned());
    } else {
      onRewardEarned();
      loadRewardedAd();
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Agar firebase initialize nahi hua toh ye ref null de sakta hai, 
  // isliye hum safe check use karenge
  late DatabaseReference _dbRef;
  int balance = 0;

  @override
  void initState() {
    super.initState();
    try {
      _dbRef = FirebaseDatabase.instance.ref("user_balance");
      _dbRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          setState(() => balance = int.tryParse(event.snapshot.value.toString()) ?? 0);
        }
      });
    } catch (e) {
      debugPrint("Database error: $e");
    }
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
    return Card(margin: const EdgeInsets.all(10), child: ListTile(leading: Icon(icon), title: Text(title), onTap: onTap));
  }

  void _openTaskList(String type) {
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
                    onPressed: () {
                      AdHelper.showRewardedAd(() async {
                        final url = item['link'];
                        if (url != null) {
                          final Uri uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        }
                      });
                    },
                    child: const Text("Watch Ad"),
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
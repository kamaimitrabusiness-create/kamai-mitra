import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  // Flutter binding ensure karna zaroori hai
  WidgetsFlutterBinding.ensureInitialized();

  // Try-catch block lagaya hai taaki Firebase error se app crash na ho
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // Mobile Ads initialize
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      AdHelper.loadRewardedAd();
    } catch (e) {
      debugPrint("Ads initialization error: $e");
    }
  }

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
  late DatabaseReference _dbRef;
  int balance = 0;

  @override
  void initState() {
    super.initState();
    // Firebase database connection
    try {
      _dbRef = FirebaseDatabase.instance.ref("user_balance");
      _dbRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          setState(() => balance = int.tryParse(event.snapshot.value.toString()) ?? 0);
        }
      });
    } catch (e) {
      debugPrint("Database connection error: $e");
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
    return Card(margin: const EdgeInsets.all(10), child: ListTile
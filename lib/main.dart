import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_features.dart';
import 'services/sync_engine.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/cluster_dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/menu_screen.dart'; 
import 'screens/stats_screen.dart';

// 🟢 NEW: Global Key to allow navigation from background services (like ApiService)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  HttpOverrides.global = MyHttpOverrides();
  runApp(const AlfresaApp());
}

class AlfresaApp extends StatelessWidget {
  const AlfresaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 🟢 NEW: Register the global key here
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Alfresa Alert App',
      theme: ThemeData(fontFamily: 'Poppins', useMaterial3: false),
      home: const SplashScreen(), 
    );
  }
}

class MainScaffold extends StatelessWidget {
  final UserProfile user;
  const MainScaffold({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SyncEngine(user),
      child: const MainScreenContent(),
    );
  }
}

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  State<MainScreenContent> createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent> with WidgetsBindingObserver {
  int _currentIndex = 0;
  List<Widget> _pages = []; 
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupModules();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        Provider.of<SyncEngine>(context, listen: false).syncData();
      }
    }
  }

  void _setupModules() {
    if (!mounted) return;
    
    final user = Provider.of<SyncEngine>(context, listen: false).user;
    setState(() {
      _pages = [];
      _navItems = [];

      // 1. Dashboard
      _pages.add(const ClusterDashboardScreen());
      _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Monitor"));

      // 2. Map (Conditional)
      if (user.hasAccess(AppModule.locationMap)) {
        _pages.add(const MapScreen());
        _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"));
      }

      // 3. Analytics (Conditional)
      if (user.hasAccess(AppModule.graphData)) {
        _pages.add(const StatsScreen());
        _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Analytics"));
      }

      // 4. Menu
      _pages.add(MenuScreen(user: user));
      _navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted || _pages.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator())); 

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: _navItems,
      ),
    );
  }
}
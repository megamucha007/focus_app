import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Regista a plataforma web apenas se estiver a rodar no browser de testes
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainFocusScreen(),
    );
  }
}

class MainFocusScreen extends StatefulWidget {
  const MainFocusScreen({super.key});

  @override
  State<MainFocusScreen> createState() => _MainFocusScreenState();
}

class _MainFocusScreenState extends State<MainFocusScreen> {
  int _currentIndex = 0;
  late final WebViewController _instagramController;
  late final WebViewController _tiktokController;
  bool _isLoading = true;

  // Código CSS/JS para esconder os Reels no Instagram
  final String _instagramScript = '''
    (function() {
      const style = document.createElement('style');
      style.type = 'text/css';
      style.innerHTML = `
        a[href*="/reels/"] { display: none !important; }
        svg[aria-label="Reels"], svg[aria-label="Clips"] { display: none !important; }
      `;
      document.head.appendChild(style);
    })();
  ''';

  // Código CSS/JS para esconder a feed "For You" no TikTok
  final String _tiktokScript = '''
    (function() {
      const style = document.createElement('style');
      style.type = 'text/css';
      style.innerHTML = `
        a[data-e2e="nav-foryou"], a[data-e2e="nav-following"] { display: none !important; }
        div[data-e2e="recommend-list-item-container"] { display: none !important; }
      `;
      document.head.appendChild(style);
    })();
  ''';

  @override
  void initState() {
    super.initState();

    // Inicialização do Controller do Instagram
    _instagramController = WebViewController();
    if (!kIsWeb) {
      _instagramController.setJavaScriptMode(JavaScriptMode.unrestricted);
      _instagramController.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _instagramController.runJavaScript(_instagramScript);
          },
        ),
      );
    }
    _instagramController.loadRequest(Uri.parse('https://www.instagram.com/direct/inbox/'));

    // Inicialização do Controller do TikTok
    _tiktokController = WebViewController();
    if (!kIsWeb) {
      _tiktokController.setJavaScriptMode(JavaScriptMode.unrestricted);
      _tiktokController.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _tiktokController.runJavaScript(_tiktokScript);
          },
        ),
      );
    }
    _tiktokController.loadRequest(Uri.parse('https://www.tiktok.com/messages'));
  }

  @override
  Widget build(BuildContext context) {
    final activeController =
        _currentIndex == 0 ? _instagramController : _tiktokController;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Instagram (Modo Foco)' : 'TikTok (Streaks)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => activeController.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              WebViewWidget(controller: _instagramController),
              WebViewWidget(controller: _tiktokController),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const
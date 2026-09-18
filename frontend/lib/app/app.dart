import 'package:flutter/material.dart';

import '../core/player/playback_session.dart';
import '../features/downloads/downloads_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/mini_player/mini_player_bar.dart';
import '../features/player/professional_player_screen.dart';
import '../features/settings/settings_screen.dart';

class StreamDownloaderApp extends StatelessWidget {
  const StreamDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream Downloader',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    LibraryScreen(),
    ProfessionalPlayerScreen(
      title: 'Player local',
      path: '',
      isAudio: true,
    ),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackSession.instance;
    final hasActivePlayback = playback.hasActivePlayback;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (hasActivePlayback)
            Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayerBar(
                title: playback.currentTitle ?? 'Reprodução',
                isPlaying: playback.isPlaying,
                onTap: () {
                  if (playback.currentPath == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfessionalPlayerScreen(
                        title: playback.currentTitle ?? 'Player',
                        path: playback.currentPath!,
                        isAudio: playback.isAudio,
                        queue: playback.queue,
                        initialIndex: playback.currentIndex,
                      ),
                    ),
                  );
                },
                onPlayPause: () {
                  playback.setPlaybackState(playing: !playback.isPlaying);
                },
                onPrevious: () {},
                onNext: () {},
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Descobrir',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_rounded),
            label: 'Biblioteca',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_fill_rounded),
            label: 'Player',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_rounded),
            label: 'Downloads',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

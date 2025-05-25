import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/edited_media_model.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioSelectorWidget extends StatefulWidget {
  final AudioTrack? selectedAudio;
  final Function(AudioTrack) onAudioSelected;
  final Function() onAudioRemoved;

  const AudioSelectorWidget({
    Key? key,
    this.selectedAudio,
    required this.onAudioSelected,
    required this.onAudioRemoved,
  }) : super(key: key);

  @override
  State<AudioSelectorWidget> createState() => _AudioSelectorWidgetState();
}

class _AudioSelectorWidgetState extends State<AudioSelectorWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingTrackId;
  String _searchQuery = '';
  String _selectedCategory = 'Trending';
  
  // Audio categories and tracks
  final Map<String, List<AudioTrackItem>> _audioCategories = {
    'Trending': [
      AudioTrackItem(
        id: '1',
        name: 'Summer Vibes',
        artist: 'DJ Tropical',
        duration: const Duration(seconds: 30),
        path: 'assets/audio/summer_vibes.mp3',
        coverUrl: null,
      ),
      AudioTrackItem(
        id: '2',
        name: 'Urban Beat',
        artist: 'City Sounds',
        duration: const Duration(seconds: 45),
        path: 'assets/audio/urban_beat.mp3',
        coverUrl: null,
      ),
      AudioTrackItem(
        id: '3',
        name: 'Chill Lofi',
        artist: 'Relaxation Station',
        duration: const Duration(seconds: 60),
        path: 'assets/audio/chill_lofi.mp3',
        coverUrl: null,
      ),
    ],
    'Pop': [
      AudioTrackItem(
        id: '4',
        name: 'Happy Dance',
        artist: 'Pop Masters',
        duration: const Duration(seconds: 40),
        path: 'assets/audio/happy_dance.mp3',
        coverUrl: null,
      ),
      AudioTrackItem(
        id: '5',
        name: 'Feel Good',
        artist: 'Sunshine Band',
        duration: const Duration(seconds: 35),
        path: 'assets/audio/feel_good.mp3',
        coverUrl: null,
      ),
    ],
    'Hip Hop': [
      AudioTrackItem(
        id: '6',
        name: 'Street Flow',
        artist: 'MC Fresh',
        duration: const Duration(seconds: 50),
        path: 'assets/audio/street_flow.mp3',
        coverUrl: null,
      ),
      AudioTrackItem(
        id: '7',
        name: 'Trap Beats',
        artist: 'Beat Maker Pro',
        duration: const Duration(seconds: 45),
        path: 'assets/audio/trap_beats.mp3',
        coverUrl: null,
      ),
    ],
    'Electronic': [
      AudioTrackItem(
        id: '8',
        name: 'Future Bass',
        artist: 'EDM World',
        duration: const Duration(seconds: 55),
        path: 'assets/audio/future_bass.mp3',
        coverUrl: null,
      ),
      AudioTrackItem(
        id: '9',
        name: 'Synthwave',
        artist: 'Retro Future',
        duration: const Duration(seconds: 60),
        path: 'assets/audio/synthwave.mp3',
        coverUrl: null,
      ),
    ],
    'Sound Effects': [
      AudioTrackItem(
        id: '10',
        name: 'Applause',
        artist: 'SFX Library',
        duration: const Duration(seconds: 5),
        path: 'assets/audio/applause.mp3',
        coverUrl: null,
      ),
      AudioTrackItem(
        id: '11',
        name: 'Laugh Track',
        artist: 'SFX Library',
        duration: const Duration(seconds: 3),
        path: 'assets/audio/laugh.mp3',
        coverUrl: null,
      ),
      AudioTrackItem(
        id: '12',
        name: 'Dramatic',
        artist: 'SFX Library',
        duration: const Duration(seconds: 4),
        path: 'assets/audio/dramatic.mp3',
        coverUrl: null,
      ),
    ],
  };

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPreview(AudioTrackItem track) async {
    if (_playingTrackId == track.id) {
      await _audioPlayer.stop();
      setState(() {
        _playingTrackId = null;
      });
    } else {
      await _audioPlayer.play(AssetSource(track.path));
      setState(() {
        _playingTrackId = track.id;
      });
      
      // Auto stop after preview duration
      Future.delayed(const Duration(seconds: 10), () {
        if (_playingTrackId == track.id) {
          _audioPlayer.stop();
          setState(() {
            _playingTrackId = null;
          });
        }
      });
    }
  }

  void _selectTrack(AudioTrackItem track) {
    final audioTrack = AudioTrack(
      name: track.name,
      path: track.path,
      duration: track.duration,
    );
    widget.onAudioSelected(audioTrack);
  }

  List<AudioTrackItem> get _filteredTracks {
    if (_searchQuery.isEmpty) {
      return _audioCategories[_selectedCategory] ?? [];
    }
    
    final allTracks = _audioCategories.values.expand((tracks) => tracks).toList();
    return allTracks.where((track) {
      return track.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          track.artist.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          // Current selection or search bar
          if (widget.selectedAudio != null)
            _buildCurrentSelection()
          else
            _buildSearchBar(),
          
          // Category tabs (only show if not searching)
          if (_searchQuery.isEmpty)
            _buildCategoryTabs(),
          
          // Track list
          Expanded(
            child: _buildTrackList(),
          ),
          
          // Volume slider
          if (widget.selectedAudio != null)
            _buildVolumeControl(),
        ],
      ),
    );
  }

  Widget _buildCurrentSelection() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedAudio!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.selectedAudio!.duration.inSeconds}s',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onAudioRemoved,
            icon: const Icon(
              Icons.close,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search for sounds...',
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _audioCategories.keys.length,
        itemBuilder: (context, index) {
          final category = _audioCategories.keys.elementAt(index);
          final isSelected = category == _selectedCategory;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white30,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackList() {
    final tracks = _filteredTracks;
    
    if (tracks.isEmpty) {
      return const Center(
        child: Text(
          'No tracks found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isPlaying = _playingTrackId == track.id;
        final isSelected = widget.selectedAudio?.name == track.name;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.white.withOpacity(0.2) 
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _playPreview(track),
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              track.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${track.artist} • ${_formatDuration(track.duration)}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            trailing: TextButton(
              onPressed: () => _selectTrack(track),
              child: Text(
                isSelected ? 'Selected' : 'Use',
                style: TextStyle(
                  color: isSelected ? Colors.green : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVolumeControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.volume_down,
            color: Colors.white54,
          ),
          Expanded(
            child: Slider(
              value: widget.selectedAudio!.volume,
              onChanged: (value) {
                final updatedTrack = widget.selectedAudio!.copyWith(volume: value);
                widget.onAudioSelected(updatedTrack);
              },
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
            ),
          ),
          const Icon(
            Icons.volume_up,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class AudioTrackItem {
  final String id;
  final String name;
  final String artist;
  final Duration duration;
  final String path;
  final String? coverUrl;

  AudioTrackItem({
    required this.id,
    required this.name,
    required this.artist,
    required this.duration,
    required this.path,
    this.coverUrl,
  });
}
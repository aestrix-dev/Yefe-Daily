import 'package:stacked/stacked.dart';
import 'models/audio_model.dart';

class AudioViewModel extends BaseViewModel {
  List<AudioCategoryModel> _audioCategories = [];
  String? _showUpgradeCardForCategory;
  bool _isPremiumUser = false;

  // Getters
  List<AudioCategoryModel> get audioCategories => _audioCategories;
  String? get showUpgradeCardForCategory => _showUpgradeCardForCategory;
  bool get isPremiumUser => _isPremiumUser;

  void onModelReady() {
    _loadAudioData();
  }

  void _loadAudioData() {
    _audioCategories = [
      AudioCategoryModel(
        id: 'tower_talk',
        title: 'Tower Talk',
        audios: [
          AudioModel(
            id: 'quiet_man_1',
            title: 'The Quiet Man',
            duration: '7min',
            audioUrl:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            categoryId: 'tower_talk',
            isPremium: true, // More than 6:30
          ),
          AudioModel(
            id: 'quiet_man_2',
            title: 'The Quiet Man',
            duration: '7min',
            audioUrl:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            categoryId: 'tower_talk',
            isPremium: true, // More than 6:30
          ),
          AudioModel(
            id: 'quiet_man_3',
            title: 'The Quiet Man',
            duration: '7min',
            audioUrl:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
            categoryId: 'tower_talk',
            isPremium: true, // More than 6:30
          ),
          AudioModel(
            id: 'quiet_man_4',
            title: 'The Quiet Man',
            duration: '7min',
            audioUrl:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
            categoryId: 'tower_talk',
            isPremium: true, // More than 6:30
          ),
        ],
      ),
      AudioCategoryModel(
        id: 'restful_rhythms',
        title: 'Restful Rhythms',
        audios: [
          AudioModel(
            id: 'quiet_man_restful',
            title: 'The Quiet Man',
            duration: '4:32',
            audioUrl:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
            categoryId: 'restful_rhythms',
            isPremium: false, // Less than 6:30
            subtitle: 'Peaceful Piano',
          ),
          AudioModel(
            id: 'yoruba_praise',
            title: 'Yoruba Praise Medley',
            duration: '4:32',
            audioUrl:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
            categoryId: 'restful_rhythms',
            isPremium: false, // Less than 6:30
            subtitle: 'Heritage Voices',
          ),
        ],
      ),
    ];

    notifyListeners();
  }

  void toggleUpgradeCard(String categoryId) {
    if (_showUpgradeCardForCategory == categoryId) {
      _showUpgradeCardForCategory = null;
    } else {
      _showUpgradeCardForCategory = categoryId;
    }
    notifyListeners();
  }

  void upgradeToPremium() {
    _isPremiumUser = true;
    _showUpgradeCardForCategory = null;

    print('=== UPGRADED TO PREMIUM ===');
    print('User now has access to all premium audio content');
    print('=========================');

    notifyListeners();
  }

  void handleAudioTap(AudioModel audio) {
    print('Audio tapped: ${audio.title}');
    // This will be called from the view to show the bottom sheet
  }
}

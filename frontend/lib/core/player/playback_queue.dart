class PlaybackQueue {
  PlaybackQueue({List<String>? initialItems}) : _items = List<String>.from(initialItems ?? const []);

  final List<String> _items;
  int _currentIndex = 0;
  bool _shuffleEnabled = false;
  bool _repeatAll = false;
  bool _repeatOne = false;

  List<String> get items => List.unmodifiable(_items);
  int get currentIndex => _currentIndex;
  bool get shuffleEnabled => _shuffleEnabled;
  bool get repeatAll => _repeatAll;
  bool get repeatOne => _repeatOne;

  bool get hasItems => _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty;

  String? get currentItem => hasItems ? _items[_currentIndex] : null;

  void setItems(List<String> items) {
    _items.clear();
    _items.addAll(items);
    if (_items.isNotEmpty) {
      _currentIndex = 0;
    }
  }

  void addItem(String item) {
    if (!_items.contains(item)) {
      _items.add(item);
    }
  }

  void addItems(List<String> items) {
    for (final item in items) {
      addItem(item);
    }
  }

  void removeItem(String item) {
    final index = _items.indexOf(item);
    if (index == -1) return;
    _items.removeAt(index);
    if (_items.isEmpty) {
      _currentIndex = 0;
      return;
    }
    if (_currentIndex >= _items.length) {
      _currentIndex = _items.length - 1;
    }
  }

  void clear() {
    _items.clear();
    _currentIndex = 0;
  }

  String? next() {
    if (_items.isEmpty) return null;
    if (_repeatOne) return _items[_currentIndex];
    if (_shuffleEnabled) {
      final nextIndex = _nextRandomIndex();
      _currentIndex = nextIndex;
      return _items[_currentIndex];
    }
    if (_repeatAll && _currentIndex >= _items.length - 1) {
      _currentIndex = 0;
      return _items[_currentIndex];
    }
    if (_currentIndex < _items.length - 1) {
      _currentIndex++;
      return _items[_currentIndex];
    }
    return null;
  }

  String? previous() {
    if (_items.isEmpty) return null;
    if (_repeatOne) return _items[_currentIndex];
    if (_shuffleEnabled) {
      final previousIndex = _previousRandomIndex();
      _currentIndex = previousIndex;
      return _items[_currentIndex];
    }
    if (_currentIndex > 0) {
      _currentIndex--;
      return _items[_currentIndex];
    }
    if (_repeatAll && _items.isNotEmpty) {
      _currentIndex = _items.length - 1;
      return _items[_currentIndex];
    }
    return _items[_currentIndex];
  }

  void toggleShuffle() => _shuffleEnabled = !_shuffleEnabled;
  void setShuffle(bool enabled) => _shuffleEnabled = enabled;
  void setRepeatAll(bool enabled) {
    _repeatAll = enabled;
    if (enabled) {
      _repeatOne = false;
    }
  }

  void setRepeatOne(bool enabled) {
    _repeatOne = enabled;
    if (enabled) {
      _repeatAll = false;
    }
  }

  int _nextRandomIndex() {
    if (_items.length < 2) return 0;
    final available = List<int>.generate(_items.length, (index) => index)
      ..remove(_currentIndex);
    if (available.isEmpty) return 0;
    final randomIndex = available[DateTime.now().millisecondsSinceEpoch % available.length];
    return randomIndex;
  }

  int _previousRandomIndex() {
    if (_items.length < 2) return 0;
    final available = List<int>.generate(_items.length, (index) => index)
      ..remove(_currentIndex);
    if (available.isEmpty) return 0;
    final randomIndex = available[(DateTime.now().millisecondsSinceEpoch + 1) % available.length];
    return randomIndex;
  }
}

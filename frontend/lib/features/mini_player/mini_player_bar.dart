import 'package:flutter/material.dart';

class MiniPlayerBar extends StatelessWidget {
  final String title;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MiniPlayerBar({
    super.key,
    required this.title,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          elevation: 10,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Text('Reprodução local', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.skip_previous_rounded),
                    tooltip: 'Anterior',
                  ),
                  IconButton(
                    onPressed: onPlayPause,
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    tooltip: isPlaying ? 'Pausar' : 'Reproduzir',
                  ),
                  IconButton(
                    onPressed: onNext,
                    icon: const Icon(Icons.skip_next_rounded),
                    tooltip: 'Próximo',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

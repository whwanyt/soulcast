part of '../speech_output_settings_page.dart';

class _SpeakerIdStepper extends StatelessWidget {
  const _SpeakerIdStepper({required this.speakerId, required this.onChanged});

  final int speakerId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t.speechOutputSettings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: t.decreaseSpeaker,
            onPressed: speakerId <= minTtsSpeakerId
                ? null
                : () => onChanged(speakerId - 1),
            icon: const Icon(LucideIcons.minus),
          ),
          Expanded(
            child: Text(
              t.speakerValue(id: speakerId),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: t.increaseSpeaker,
            onPressed: speakerId >= maxTtsSpeakerId
                ? null
                : () => onChanged(speakerId + 1),
            icon: const Icon(LucideIcons.plus),
          ),
        ],
      ),
    );
  }
}

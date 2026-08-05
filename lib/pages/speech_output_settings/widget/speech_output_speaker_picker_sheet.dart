part of '../speech_output_settings_page.dart';

/// 从模型目录中选择 TTS 说话人的底部面板。
class SpeechOutputSpeakerPickerSheet extends StatefulWidget {
  const SpeechOutputSpeakerPickerSheet({
    required this.speakers,
    required this.selectedSid,
    super.key,
  });

  final List<TtsSpeaker> speakers;
  final int selectedSid;

  @override
  State<SpeechOutputSpeakerPickerSheet> createState() =>
      _SpeechOutputSpeakerPickerSheetState();
}

class _SpeechOutputSpeakerPickerSheetState
    extends State<SpeechOutputSpeakerPickerSheet> {
  late final TextEditingController _queryController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.speechOutputSettings;
    final filtered = _filteredSpeakers();
    final height = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                t.speakerPick,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: t.speakerSearchHint,
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _queryController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(LucideIcons.x),
                        ),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        t.speakerEmpty,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final speaker = filtered[index];
                        final selected = speaker.sid == widget.selectedSid;
                        final title = speaker.hasName
                            ? t.speakerNamedValue(
                                name: speaker.name,
                                id: speaker.sid,
                              )
                            : t.speakerUnnamed(id: speaker.sid);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.page,
                          ),
                          leading: Icon(
                            selected
                                ? LucideIcons.circleCheck
                                : LucideIcons.userRound,
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: selected,
                          onTap: () => Navigator.of(context).pop(speaker.sid),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<TtsSpeaker> _filteredSpeakers() {
    final q = _query.toLowerCase();
    if (q.isEmpty) {
      return widget.speakers;
    }
    return widget.speakers
        .where((speaker) {
          if (speaker.sid.toString().contains(q)) {
            return true;
          }
          return speaker.name.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }
}

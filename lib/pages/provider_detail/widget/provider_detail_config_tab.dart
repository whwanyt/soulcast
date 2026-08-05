part of 'provider_detail_widgets.dart';

/// AI 服务商连接配置页签。
class ProviderDetailConfigTab extends StatelessWidget {
  const ProviderDetailConfigTab({
    super.key,
    required this.selectedProvider,
    required this.onProviderSaved,
    required this.onProviderDeleted,
  });

  final AiProviderEntity? selectedProvider;
  final ValueChanged<ProviderDetailProviderDraft> onProviderSaved;
  final ValueChanged<AiProviderEntity> onProviderDeleted;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ProviderDetailForm(
          key: ValueKey(selectedProvider?.id ?? 'new-provider'),
          provider: selectedProvider,
          onSaved: onProviderSaved,
          onDeleted: selectedProvider == null ? null : onProviderDeleted,
        ),
      ],
    );
  }
}

part of 'provider_detail_widgets.dart';

/// 新建或编辑本地模型配置的底部面板。
class ProviderDetailModelEditorSheet extends StatelessWidget {
  const ProviderDetailModelEditorSheet({
    super.key,
    required this.model,
    required this.onSaved,
  });

  final AiModelEntity? model;
  final Future<void> Function(ProviderDetailModelDraft draft) onSaved;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final translations = context.t.providerSettings;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            model == null ? translations.addModel : translations.editModel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ProviderDetailModelForm(model: model, onSaved: onSaved),
        ],
      ),
    );
  }
}

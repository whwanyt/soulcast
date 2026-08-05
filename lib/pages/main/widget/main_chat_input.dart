import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nf_extended_text_field/nf_extended_text_field.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/browse_file_library/browse_file_library.dart';
import 'package:soulcast/features/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

import 'main_chat_at_plugin_menu.dart';
import 'main_chat_attach_sheet.dart';
import 'main_chat_create_image_special_text.dart';
import 'main_chat_draft_attachments.dart';
import 'main_chat_input_actions.dart';

/// 主页面消息输入区，整合草稿、发送/停止、模型与工具开关和语音输入。
class MainChatInput extends StatefulWidget {
  const MainChatInput({
    super.key,
    required this.enabled,
    required this.isSending,
    required this.draftMessage,
    required this.onDraftChanged,
    required this.onSubmitted,
    required this.onStopPressed,
    required this.onToolsPressed,
    required this.onMcpPressed,
    required this.modelLabel,
    required this.onModelPressed,
    this.draftAttachments = const [],
    this.onPickDraftImages,
    this.onPickDraftDocuments,
    this.onImportLibraryImage,
    this.onRemoveDraftAttachment,
    this.isVoiceListening = false,
    this.voicePartialText = '',
    this.onVoicePressed,
    this.useBlurBackground = false,
  });

  final bool enabled;
  final bool isSending;
  final String draftMessage;
  final List<ChatAttachmentPart> draftAttachments;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onStopPressed;
  final VoidCallback onToolsPressed;
  final VoidCallback onMcpPressed;
  final String modelLabel;
  final VoidCallback onModelPressed;
  final Future<void> Function()? onPickDraftImages;
  final Future<void> Function()? onPickDraftDocuments;
  final Future<void> Function(String path)? onImportLibraryImage;
  final ValueChanged<String>? onRemoveDraftAttachment;
  final bool isVoiceListening;
  final String voicePartialText;
  final VoidCallback? onVoicePressed;

  /// 角色会话时使用毛玻璃底，透出背后头像背景。
  final bool useBlurBackground;

  @override
  State<MainChatInput> createState() => _MainChatInputState();
}

class _MainChatInputState extends State<MainChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _menuEntry;
  bool _hasText = false;
  bool _showAtMenu = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.draftMessage;
    _hasText = widget.draftMessage.trim().isNotEmpty;
    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant MainChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftMessage == widget.draftMessage ||
        _controller.text == widget.draftMessage) {
      return;
    }

    _controller.text = widget.draftMessage;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _hasText = widget.draftMessage.trim().isNotEmpty;
    _syncAtMenuVisibility();
  }

  @override
  void dispose() {
    _removeAtMenu();
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canSubmit =
        widget.enabled &&
        !widget.isSending &&
        (_hasText || widget.draftAttachments.isNotEmpty);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
      height: 1.35,
    );
    final mentionStyle = (textStyle ?? theme.textTheme.bodyLarge)?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );
    // 输入区 surface 为白/深底，用 higher container + 一点 primary 叠色保证可见。
    final mentionBackground = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.12),
      colorScheme.surfaceContainerHighest,
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.draftAttachments.isNotEmpty) ...[
            MainChatDraftAttachmentsBar(
              attachments: widget.draftAttachments,
              onRemove: widget.onRemoveDraftAttachment ?? (_) {},
            ),
            const SizedBox(height: 10),
          ],
          if (widget.isVoiceListening)
            _buildVoiceTranscript(context, colorScheme, textStyle)
          else
            _buildTextField(
              context,
              colorScheme,
              textStyle,
              mentionStyle,
              mentionBackgroundColor: mentionBackground,
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              MainChatInputActionButton(
                tooltip: context.t.main.input.add,
                icon: LucideIcons.plus,
                onPressed: widget.enabled ? _handleAddPressed : null,
              ),
              const SizedBox(width: 4),
              MainChatInputActionButton(
                tooltip: context.t.main.toolPanel.open,
                icon: LucideIcons.wrench,
                onPressed: widget.enabled ? _handleToolsPressed : null,
              ),
              const SizedBox(width: 4),
              MainChatInputActionButton(
                tooltip: context.t.main.mcpPanel.open,
                icon: LucideIcons.server,
                onPressed: widget.enabled ? _handleMcpPressed : null,
              ),
              const SizedBox(width: 4),
              MainChatInputActionButton(
                tooltip: widget.modelLabel,
                icon: LucideIcons.bot,
                onPressed: widget.enabled ? _handleModelPressed : null,
              ),
              const Spacer(),
              MainChatInputVoiceButton(
                isListening: widget.isVoiceListening,
                enabled:
                    widget.enabled &&
                    !widget.isSending &&
                    widget.onVoicePressed != null,
                onPressed: widget.onVoicePressed,
              ),
              const SizedBox(width: 4),
              if (widget.isSending)
                MainChatInputStopButton(onPressed: widget.onStopPressed)
              else
                MainChatInputSendButton(
                  onPressed: _submitCurrent,
                  canSubmit: canSubmit,
                ),
            ],
          ),
        ],
      ),
    );

    final borderRadius = BorderRadius.circular(AppRadii.xl);
    final panel = widget.useBlurBackground
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: AppShadows.input(colorScheme.shadow),
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.52),
                    borderRadius: borderRadius,
                  ),
                  child: content,
                ),
              ),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: borderRadius,
              boxShadow: AppShadows.input(colorScheme.shadow),
            ),
            child: content,
          );

    return CompositedTransformTarget(link: _layerLink, child: panel);
  }

  Widget _buildVoiceTranscript(
    BuildContext context,
    ColorScheme colorScheme,
    TextStyle? textStyle,
  ) {
    final text = widget.voicePartialText.trim().isEmpty
        ? context.t.main.input.voiceListening
        : widget.voicePartialText;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: textStyle?.copyWith(
            color: widget.voicePartialText.trim().isEmpty
                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.72)
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    ColorScheme colorScheme,
    TextStyle? textStyle,
    TextStyle? mentionStyle, {
    required Color mentionBackgroundColor,
  }) {
    return ExtendedTextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      minLines: 1,
      maxLines: 5,
      textInputAction: TextInputAction.send,
      cursorColor: colorScheme.primary,
      style: textStyle,
      specialTextSpanBuilder: MainChatCreateImageSpecialTextSpanBuilder(
        mentionStyle:
            mentionStyle ??
            TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w400),
        backgroundColor: mentionBackgroundColor,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        hintText: context.t.main.input.hint,
        hintStyle: textStyle?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      onSubmitted: widget.isSending ? null : _submit,
      onTap: _syncAtMenuVisibility,
    );
  }

  Future<void> _handleAddPressed() async {
    _unfocusInput();
    final action = await showMainChatAttachSheet(context);
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case MainChatAttachAction.images:
        await widget.onPickDraftImages?.call();
      case MainChatAttachAction.fileLibrary:
        final path = await showFileLibraryImagePicker(context);
        if (!mounted || path == null || path.isEmpty) {
          return;
        }
        await widget.onImportLibraryImage?.call(path);
      case MainChatAttachAction.documents:
        await widget.onPickDraftDocuments?.call();
    }
  }

  void _handleToolsPressed() {
    _unfocusInput();
    widget.onToolsPressed();
  }

  void _handleMcpPressed() {
    _unfocusInput();
    widget.onMcpPressed();
  }

  void _handleModelPressed() {
    _unfocusInput();
    widget.onModelPressed();
  }

  void _submit(String value) {
    final text = value.trim();
    final hasAttachments = widget.draftAttachments.isNotEmpty;
    if ((text.isEmpty && !hasAttachments) ||
        !widget.enabled ||
        widget.isSending) {
      return;
    }
    _hideAtMenu();
    _unfocusInput();
    widget.onSubmitted(text);
  }

  void _submitCurrent() {
    _submit(_controller.text);
  }

  void _unfocusInput() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _hideAtMenu();
    } else {
      _syncAtMenuVisibility();
    }
  }

  void _handleTextChanged() {
    final text = _controller.text;
    widget.onDraftChanged(text);
    final hasText = text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
    _syncAtMenuVisibility();
  }

  /// 光标前 token 恰好为单独的 `@` 时展示插件菜单。
  bool _shouldShowAtMenu() {
    if (!widget.enabled || widget.isSending || !_focusNode.hasFocus) {
      return false;
    }
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      return false;
    }
    final cursor = selection.baseOffset.clamp(0, text.length);
    if (cursor <= 0) {
      return false;
    }
    final before = text.substring(0, cursor);
    final match = RegExp(r'(^|[\s])@$').firstMatch(before);
    return match != null;
  }

  void _syncAtMenuVisibility() {
    final shouldShow = _shouldShowAtMenu();
    if (shouldShow == _showAtMenu) {
      if (shouldShow) {
        _menuEntry?.markNeedsBuild();
      }
      return;
    }
    if (shouldShow) {
      _showAtMenuOverlay();
    } else {
      _hideAtMenu();
    }
  }

  void _showAtMenuOverlay() {
    _removeAtMenu();
    _showAtMenu = true;
    final overlay = Overlay.of(context, rootOverlay: true);
    _menuEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideAtMenu,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.bottomLeft,
              offset: const Offset(0, -8),
              child: MainChatAtPluginMenu(
                onCreateImageSelected: _insertCreateImageMention,
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_menuEntry!);
  }

  void _hideAtMenu() {
    if (!_showAtMenu && _menuEntry == null) {
      return;
    }
    _showAtMenu = false;
    _removeAtMenu();
  }

  void _removeAtMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  void _insertCreateImageMention() {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.isValid
        ? selection.baseOffset.clamp(0, text.length)
        : text.length;
    if (cursor <= 0 || text[cursor - 1] != '@') {
      _hideAtMenu();
      return;
    }

    final replacement = '${ChatCreateImageMention.keywordOf(context.t)} ';
    final nextText = text.replaceRange(cursor - 1, cursor, replacement);
    final nextCursor = cursor - 1 + replacement.length;
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextCursor),
    );
    _hideAtMenu();
    _focusNode.requestFocus();
  }
}

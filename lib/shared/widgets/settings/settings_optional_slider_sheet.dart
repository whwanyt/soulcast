import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 可选数值设置底部面板。
class SettingsOptionalSliderSheet extends StatefulWidget {
  const SettingsOptionalSliderSheet({
    super.key,
    required this.title,
    required this.note,
    required this.enabled,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.divisions,
    required this.formatValue,
    required this.onChanged,
  });

  final String title;
  final String note;
  final bool enabled;
  final double value;
  final double min;
  final double max;
  final double step;
  final int divisions;
  final String Function(double value) formatValue;
  final ValueChanged<({bool enabled, double value})> onChanged;

  @override
  State<SettingsOptionalSliderSheet> createState() =>
      _SettingsOptionalSliderSheetState();
}

class _SettingsOptionalSliderSheetState
    extends State<SettingsOptionalSliderSheet> {
  late bool _enabled;
  late double _value;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _value = _snap(widget.value);
  }

  double _snap(double value) {
    final clamped = value.clamp(widget.min, widget.max);
    if (widget.step <= 0) {
      return clamped.toDouble();
    }
    final steps = ((clamped - widget.min) / widget.step).round();
    return (widget.min + steps * widget.step).clamp(widget.min, widget.max);
  }

  void _commit() {
    widget.onChanged((enabled: _enabled, value: _value));
  }

  void _nudge(double direction) {
    if (!_enabled) {
      return;
    }
    setState(() => _value = _snap(_value + direction * widget.step));
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canDecrease = _enabled && _value > widget.min + 1e-9;
    final canIncrease = _enabled && _value < widget.max - 1e-9;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _enabled,
                onChanged: (enabled) {
                  setState(() => _enabled = enabled);
                  _commit();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _enabled ? 1 : 0.45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    widget.formatValue(_value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _enabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: '-',
                      onPressed: canDecrease ? () => _nudge(-1) : null,
                      icon: const Icon(LucideIcons.minus, size: 18),
                    ),
                    Expanded(
                      child: Slider(
                        value: _value,
                        min: widget.min,
                        max: widget.max,
                        divisions: widget.divisions,
                        label: widget.formatValue(_value),
                        onChanged: _enabled
                            ? (value) => setState(() => _value = _snap(value))
                            : null,
                        onChangeEnd: _enabled ? (_) => _commit() : null,
                      ),
                    ),
                    IconButton(
                      tooltip: '+',
                      onPressed: canIncrease ? () => _nudge(1) : null,
                      icon: const Icon(LucideIcons.plus, size: 18),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.formatValue(widget.min),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      widget.formatValue(widget.max),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                widget.note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 打开可启停数值参数的设置底部面板。
Future<void> showSettingsOptionalSliderSheet({
  required BuildContext context,
  required String title,
  required String note,
  required bool enabled,
  required double value,
  required double min,
  required double max,
  required double step,
  required int divisions,
  required String Function(double value) formatValue,
  required ValueChanged<({bool enabled, double value})> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) {
      return SettingsOptionalSliderSheet(
        title: title,
        note: note,
        enabled: enabled,
        value: value,
        min: min,
        max: max,
        step: step,
        divisions: divisions,
        formatValue: formatValue,
        onChanged: onChanged,
      );
    },
  );
}

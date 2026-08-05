import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 始终可调的数值设置底部面板。
class SettingsSliderSheet extends StatefulWidget {
  const SettingsSliderSheet({
    super.key,
    required this.title,
    required this.note,
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
  final double value;
  final double min;
  final double max;
  final double step;
  final int divisions;
  final String Function(double value) formatValue;
  final ValueChanged<double> onChanged;

  @override
  State<SettingsSliderSheet> createState() => _SettingsSliderSheetState();
}

class _SettingsSliderSheetState extends State<SettingsSliderSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
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
    widget.onChanged(_value);
  }

  void _nudge(double direction) {
    setState(() => _value = _snap(_value + direction * widget.step));
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canDecrease = _value > widget.min + 1e-9;
    final canIncrease = _value < widget.max - 1e-9;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              IconButton(
                onPressed: canDecrease ? () => _nudge(-1) : null,
                icon: const Icon(LucideIcons.minus),
              ),
              Expanded(
                child: Text(
                  widget.formatValue(_value),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: canIncrease ? () => _nudge(1) : null,
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: (value) {
              setState(() => _value = _snap(value));
              _commit();
            },
          ),
          const SizedBox(height: AppSpacing.md),
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

/// 打开数值设置底部面板。
Future<void> showSettingsSliderSheet({
  required BuildContext context,
  required String title,
  required String note,
  required double value,
  required double min,
  required double max,
  required double step,
  required int divisions,
  required String Function(double value) formatValue,
  required ValueChanged<double> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) {
      return SettingsSliderSheet(
        title: title,
        note: note,
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

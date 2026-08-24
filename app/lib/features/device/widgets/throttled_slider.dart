import 'package:flutter/material.dart';

/// A slider that behaves like docs/03-aplikacja.md#throttling-suwaków
/// requires: [onChanged] fires at most ~25 Hz while dragging, but
/// [onChangeEnd] always fires with the exact release value so a throttled
/// drop never leaves the UI a step away from the device.
///
/// Shared by [BrightnessSlider] and [CctSlider] (and any slider capability
/// that follows) because the throttling and drag-vs-remote reconciliation
/// logic is easy to get subtly wrong twice.
///
/// Simplification: the doc reconciles a remote echo against local state by
/// checking whether 300ms have passed since the last interaction. This
/// widget instead just trusts the local drag value for the whole drag and
/// switches back to the remote value the instant the drag ends — same
/// effect (no mid-drag fighting), fewer moving parts.
class ThrottledSlider extends StatefulWidget {
  const ThrottledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
    this.valueLabel,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final String Function(double value)? valueLabel;

  @override
  State<ThrottledSlider> createState() => _ThrottledSliderState();
}

class _ThrottledSliderState extends State<ThrottledSlider> {
  double? _dragValue;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  static const _minInterval = Duration(milliseconds: 40); // ~25 Hz

  @override
  Widget build(BuildContext context) {
    final displayValue = (_dragValue ?? widget.value).clamp(
      widget.min,
      widget.max,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.valueLabel == null
                ? widget.label
                : '${widget.label} · ${widget.valueLabel!(displayValue)}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Slider(
            value: displayValue,
            min: widget.min,
            max: widget.max,
            onChanged: (value) {
              setState(() => _dragValue = value);
              final now = DateTime.now();
              if (now.difference(_lastSent) >= _minInterval) {
                _lastSent = now;
                widget.onChanged(value);
              }
            },
            onChangeEnd: (value) {
              widget.onChangeEnd(value);
              setState(() => _dragValue = null);
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

// Enum for the shape of the spotlight highlight
enum SpotlightShape {
  circle,
  rectangle,
}

// A typedef for the custom tooltip builder function
typedef SpotlightTooltipBuilder = Widget Function(
  VoidCallback onNext,
  VoidCallback onSkip,
);

// Data class for a single step in the tour
class SpotlightStep {
  final String id;
  final String? text; // Now optional
  final SpotlightShape shape;
  final Alignment contentAlignment;
  final SpotlightTooltipBuilder? tooltipBuilder;

  SpotlightStep({
    required this.id,
    this.text,
    this.shape = SpotlightShape.rectangle,
    this.contentAlignment = Alignment.center,
    this.tooltipBuilder,
  }) : assert(text != null || tooltipBuilder != null,
            'Either text or tooltipBuilder must be provided.');
}

// Controller to manage the state and flow of the tour
class SpotlightController extends ChangeNotifier {
  final List<SpotlightStep> steps;
  int _currentIndex = -1;
  final Map<String, GlobalKey> _targets = {};

  SpotlightController({required this.steps});

  int get currentIndex => _currentIndex;
  bool get isTourActive => _currentIndex != -1;
  SpotlightStep? get currentStep => isTourActive ? steps[_currentIndex] : null;

  void _registerTarget(String id, GlobalKey key) {
    _targets[id] = key;
  }

  void start() {
    if (steps.isNotEmpty) {
      _currentIndex = 0;
      notifyListeners();
    }
  }

  void next() {
    if (_currentIndex < steps.length - 1) {
      _currentIndex++;
    } else {
      stop();
    }
    notifyListeners();
  }

  void stop() {
    _currentIndex = -1;
    notifyListeners();
  }

  GlobalKey? getKeyForCurrentStep() {
    if (currentStep == null) return null;
    return _targets[currentStep!.id];
  }
}

// The main provider widget that should wrap your screen/app
class FeatureSpotlight extends StatefulWidget {
  final Widget child;
  const FeatureSpotlight({super.key, required this.child});

  static FeatureSpotlightState of(BuildContext context) {
    final state = context.findAncestorStateOfType<FeatureSpotlightState>();
    assert(state != null, 'Cannot find FeatureSpotlight in ancestor tree');
    return state!;
  }

  @override
  State<FeatureSpotlight> createState() => FeatureSpotlightState();
}

class FeatureSpotlightState extends State<FeatureSpotlight> {
  SpotlightController? _activeController;
  OverlayEntry? _overlayEntry;

  void startTour(SpotlightController controller) {
    setState(() {
      _activeController = controller;
      _activeController?.addListener(_updateOverlay);
      _activeController?.start();
    });
  }

  void _stopTour() {
    _activeController?.removeListener(_updateOverlay);
    _activeController?.stop();
    setState(() {
      _activeController = null;
    });
  }

  void _updateOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_activeController?.isTourActive ?? false) {
      _overlayEntry = OverlayEntry(
        builder: (context) {
          final key = _activeController!.getKeyForCurrentStep();
          if (key == null || key.currentContext == null) {
            return const SizedBox.shrink();
          }

          final renderBox = key.currentContext!.findRenderObject() as RenderBox;
          final targetSize = renderBox.size;
          final targetOffset = renderBox.localToGlobal(Offset.zero);

          final currentStep = _activeController!.currentStep!;

          return _SpotlightOverlay(
            targetOffset: targetOffset,
            targetSize: targetSize,
            shape: currentStep.shape,
            text: currentStep.text,
            tooltipBuilder: currentStep.tooltipBuilder,
            onTap: () => _activeController?.next(),
            onSkip: _stopTour,
          );
        },
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
    setState(() {}); // Re-render to remove overlay when tour ends
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// The widget that marks a child as a target for a spotlight step
class SpotlightTarget extends StatefulWidget {
  final String id;
  final SpotlightController controller;
  final Widget child;

  const SpotlightTarget({
    super.key,
    required this.id,
    required this.controller,
    required this.child,
  });

  @override
  State<SpotlightTarget> createState() => _SpotlightTargetState();
}

class _SpotlightTargetState extends State<SpotlightTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller._registerTarget(widget.id, _key);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}

// The actual overlay widget that draws the spotlight and text
class _SpotlightOverlay extends StatelessWidget {
  final Offset targetOffset;
  final Size targetSize;
  final SpotlightShape shape;
  final String? text;
  final SpotlightTooltipBuilder? tooltipBuilder;
  final VoidCallback onTap;
  final VoidCallback onSkip;

  const _SpotlightOverlay({
    required this.targetOffset,
    required this.targetSize,
    required this.shape,
    this.text,
    this.tooltipBuilder,
    required this.onTap,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final targetRect = targetOffset & targetSize;

    // Determine if tooltip should be above or below the target
    final bool isTooltipBelow = targetRect.center.dy < screenSize.height / 2;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background scrim
          GestureDetector(
            onTap: onTap,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                // Replaced deprecated withOpacity with Color.fromARGB
                // 0.6 * 255 = 153
                Color.fromARGB(153, 0, 0, 0),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: targetOffset.dy,
                    left: targetOffset.dx,
                    child: _buildHighlight(targetSize),
                  ),
                ],
              ),
            ),
          ),
          // Tooltip content
          Positioned(
            top: isTooltipBelow ? targetRect.bottom + 16 : null,
            bottom:
                isTooltipBelow ? null : screenSize.height - targetRect.top + 16,
            left: 20,
            right: 20,
            child: tooltipBuilder != null
                ? tooltipBuilder!(onTap, onSkip)
                : _buildDefaultTooltipContent(),
          ),
          // Skip button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: onSkip,
              child: const Text('Skip', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlight(Size size) {
    switch (shape) {
      case SpotlightShape.circle:
        final radius =
            size.width > size.height ? size.width / 2 : size.height / 2;
        return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        );
      case SpotlightShape.rectangle:
        return Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }

  Widget _buildDefaultTooltipContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onTap,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

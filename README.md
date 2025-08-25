# Feature Spotlight: Guided Tours & Feature Showcases for Flutter

**Feature Spotlight** is a simple, declarative Flutter package for creating guided tours and feature showcases. Effortlessly highlight widgets to guide your users through new features or complex UIs with smooth animations and fully customizable tooltips.

------------------------------------------------------------------------

## ✨ Features

-   🎯 **Declarative API** -- Simply wrap your widgets with `SpotlightTarget` and let the package handle the rest.
-   🎨 **Fully Customizable** -- Use the `tooltipBuilder` to create completely custom UI for your tour steps.
-   🚀 **Easy to Use** -- Get a tour up and running in minutes with a straightforward controller.
-   ✨ **Smooth Animations** -- Fluid animations between tour steps create a polished user experience.
-   🔍 **Multiple Shapes** -- Support for circle, rectangle, and custom spotlight shapes.
-   📱 **Responsive** -- Works seamlessly across different screen sizes and orientations.

------------------------------------------------------------------------

## 🚀 Installation

Add `feature_spotlight` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  feature_spotlight: ^1.0.0  # Use the latest version from pub.dev
```

Install the package:

```sh
flutter pub get
```

------------------------------------------------------------------------

## 📱 Basic Usage

### 1. Wrap Your App

Wrap your `MaterialApp`'s child with the `FeatureSpotlight` widget:

```dart
import 'package:flutter/material.dart';
import 'package:feature_spotlight/feature_spotlight.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FeatureSpotlight(
        child: MyHomePage(),
      ),
    );
  }
}
```

### 2. Create a Controller and Define Steps

```dart
class _MyHomePageState extends State<MyHomePage> {
  late SpotlightController _controller;

  @override
  void initState() {
    super.initState();
    
    // Create a controller and define your steps
    _controller = SpotlightController(
      steps: [
        SpotlightStep(
          id: 'profile-icon',
          text: 'This is the default tooltip. Tap here to see your profile.',
          shape: SpotlightShape.circle,
        ),
        SpotlightStep(
          id: 'settings-button',
          text: 'Access your settings and preferences here.',
          shape: SpotlightShape.rectangle,
        ),
        SpotlightStep(
          id: 'add-button',
          text: 'Create new content with this button.',
          shape: SpotlightShape.circle,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Spotlight Demo'),
        actions: [
          // Wrap your target widgets
          SpotlightTarget(
            id: 'profile-icon',
            controller: _controller,
            child: IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {},
            ),
          ),
          SpotlightTarget(
            id: 'settings-button',
            controller: _controller,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Start the tour
            FeatureSpotlight.of(context).startTour(_controller);
          },
          child: const Text('Start Tour'),
        ),
      ),
      floatingActionButton: SpotlightTarget(
        id: 'add-button',
        controller: _controller,
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

------------------------------------------------------------------------

## 🎨 Full Customization

For complete control over the tooltip's appearance, use the `tooltipBuilder` property on a `SpotlightStep`. This function gives you `onNext` and `onSkip` callbacks to control the tour:

```dart
SpotlightStep(
  id: 'add-button',
  shape: SpotlightShape.circle,
  tooltipBuilder: (onNext, onSkip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.deepPurple,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This is a custom tooltip!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You can put any widget you want in here. Add images, buttons, or complex layouts.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onSkip,
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                ),
                child: const Text('Got it!'),
              ),
            ],
          ),
        ],
      ),
    );
  },
),
```

------------------------------------------------------------------------

## 📋 SpotlightStep Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier for the step |
| `text` | `String?` | Default tooltip text (optional if using `tooltipBuilder`) |
| `shape` | `SpotlightShape` | Shape of the spotlight (`circle`, `rectangle`) |
| `tooltipBuilder` | `Widget Function(VoidCallback, VoidCallback)?` | Custom tooltip builder with `onNext` and `onSkip` callbacks |

------------------------------------------------------------------------

## 🔄 Showing the Tour Only Once

The package **does not manage when the tour should be shown**. This logic belongs in your application's state. You can use a state management solution or a simple package like `shared_preferences` to store a flag.

### Using SharedPreferences

```dart
import 'package:shared_preferences/shared_preferences.dart';

class _MyHomePageState extends State<MyHomePage> {
  bool _showTour = false;

  @override
  void initState() {
    super.initState();
    _checkTourStatus();
  }

  Future<void> _checkTourStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('has_seen_tour') ?? false;
    
    setState(() {
      _showTour = !hasSeenTour;
    });

    // Auto-start tour for new users
    if (_showTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FeatureSpotlight.of(context).startTour(_controller);
      });
    }
  }

  Future<void> _markTourAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tour', true);
    setState(() {
      _showTour = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... your UI
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _showTour
            ? ElevatedButton(
                onPressed: () {
                  FeatureSpotlight.of(context).startTour(_controller);
                  _markTourAsSeen();
                },
                child: const Text('Start Tour'),
              )
            : ElevatedButton(
                onPressed: () {
                  // Allow users to replay the tour
                  FeatureSpotlight.of(context).startTour(_controller);
                },
                child: const Text('Replay Tour'),
              ),
      ),
    );
  }
}
```

------------------------------------------------------------------------

## 🛠 Advanced Usage

### Custom Spotlight Shapes

```dart
SpotlightStep(
  id: 'custom-widget',
  shape: SpotlightShape.rectangle,
  // Add custom padding around the spotlight
  padding: const EdgeInsets.all(8.0),
),
```

### Programmatic Tour Control

```dart
class TourManager {
  static void startFeatureTour(BuildContext context, SpotlightController controller) {
    FeatureSpotlight.of(context).startTour(controller);
  }

  static void skipTour(BuildContext context) {
    FeatureSpotlight.of(context).skipTour();
  }

  static void nextStep(BuildContext context) {
    FeatureSpotlight.of(context).nextStep();
  }
}
```

### Tour Events & Callbacks

```dart
_controller = SpotlightController(
  steps: [...],
  onTourStarted: () {
    print('Tour started!');
  },
  onTourCompleted: () {
    print('Tour completed!');
    _markTourAsSeen();
  },
  onTourSkipped: () {
    print('Tour was skipped');
    _markTourAsSeen();
  },
);
```

------------------------------------------------------------------------

## 📝 Best Practices

### ✅ Do's

- **Keep tooltips concise** -- Users want to get through tours quickly
- **Use consistent styling** -- Match your app's design language
- **Test on different screen sizes** -- Ensure tooltips fit properly
- **Provide skip options** -- Always give users a way out
- **Show tours contextually** -- Display them when features are introduced

### ❌ Don'ts

- **Don't overwhelm users** -- Limit tours to 3-5 steps maximum
- **Don't show tours repeatedly** -- Use persistent storage to track completion
- **Don't block critical functionality** -- Ensure users can still use the app
- **Don't use tiny touch targets** -- Make buttons easy to tap

------------------------------------------------------------------------

## 🤝 Contributing

Contributions are welcome! If you find a bug or want a new feature:

1. **Check existing issues** on our GitHub repository
2. **Open a detailed issue** describing the problem or enhancement
3. **Submit a pull request** with your changes

------------------------------------------------------------------------

## 📜 License

This package is licensed under the **MIT License**. See the LICENSE file for details.

------------------------------------------------------------------------

## 🔗 Links

- **Package**: [pub.dev/packages/feature_spotlight](https://pub.dev/packages/feature_spotlight)
- **Repository**: [GitHub Repository](https://github.com/your-username/feature_spotlight)
- **Issues**: [Report bugs or request features](https://github.com/your-username/feature_spotlight/issues)
- **Documentation**: [API Documentation](https://pub.dev/documentation/feature_spotlight/latest/)

------------------------------------------------------------------------

**Made with ❤️ for the Flutter community**#   f e a t u r e _ s p o t l i g h t 
 
 #   f e a t u r e _ s p o t l i g h t 
 
 

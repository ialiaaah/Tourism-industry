import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';

// Type definitions to enforce a consistent use of the API
typedef ARViewCreatedCallback = void Function(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager);

/// Factory method for creating a platform-dependent AR view
abstract class PlatformARView {
  factory PlatformARView(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return AndroidARView();
      case TargetPlatform.iOS:
        return IosARView();
      default:
        throw FlutterError;
    }
  }

  Widget build(
      {@required BuildContext context,
      @required ARViewCreatedCallback arViewCreatedCallback,
      @required PlaneDetectionConfig planeDetectionConfig});

  /// Callback function that is executed once the view is established
  void onPlatformViewCreated(int id);
}

/// Instantiates [ARSessionManager], [ARObjectManager] and returns them to the widget instantiating the [ARView] using the [arViewCreatedCallback]
createManagers(
    int id,
    BuildContext? context,
    ARViewCreatedCallback? arViewCreatedCallback,
    PlaneDetectionConfig? planeDetectionConfig) {
  if (context == null ||
      arViewCreatedCallback == null ||
      planeDetectionConfig == null) {
    return;
  }
  arViewCreatedCallback(ARSessionManager(id, context, planeDetectionConfig),
      ARObjectManager(id), ARAnchorManager(id), ARLocationManager());
}

/// Android-specific implementation of [PlatformARView]
/// Uses Hybrid Composition to increase peformance on Android 9 and below (https://flutter.dev/docs/development/platform-integration/platform-views)
class AndroidARView implements PlatformARView {
  late BuildContext? _context;
  late ARViewCreatedCallback? _arViewCreatedCallback;
  late PlaneDetectionConfig? _planeDetectionConfig;

  @override
  void onPlatformViewCreated(int id) {
    print("Android platform view created!");
    createManagers(id, _context, _arViewCreatedCallback, _planeDetectionConfig);
  }

  @override
  Widget build(
      {BuildContext? context,
      ARViewCreatedCallback? arViewCreatedCallback,
      PlaneDetectionConfig? planeDetectionConfig}) {
    _context = context;
    _arViewCreatedCallback = arViewCreatedCallback;
    _planeDetectionConfig = planeDetectionConfig;
    // This is used in the platform side to register the view.
    final String viewType = 'ar_flutter_plugin';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onPlatformViewCreated,
    );
  }
}

/// iOS-specific implementation of [PlatformARView]
class IosARView implements PlatformARView {
  BuildContext? _context;
  ARViewCreatedCallback? _arViewCreatedCallback;
  PlaneDetectionConfig? _planeDetectionConfig;

  @override
  void onPlatformViewCreated(int id) {
    print("iOS platform view created!");
    createManagers(id, _context, _arViewCreatedCallback, _planeDetectionConfig);
  }

  @override
  Widget build(
      {BuildContext? context,
      ARViewCreatedCallback? arViewCreatedCallback,
      PlaneDetectionConfig? planeDetectionConfig}) {
    _context = context;
    _arViewCreatedCallback = arViewCreatedCallback;
    _planeDetectionConfig = planeDetectionConfig;
    // This is used in the platform side to register the view.
    final String viewType = 'ar_flutter_plugin';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onPlatformViewCreated,
    );
  }
}

/// If camera permission is granted, [ARView] creates a platform-dependent view from the factory method [PlatformARView]. To instantiate an [ARView],
/// the calling widget needs to pass the callback function [onARViewCreated] to which the function [createManagers] returns managers such as the
/// [ARSessionManager] and the [ARObjectManager]. [planeDetectionConfig] is passed to the constructor to determine which types of planes the underlying
/// AR frameworks should track (defaults to none).
/// If camera permission is not given, the user is prompted to grant it. To modify the UI of the prompts, the following named parameters can be used:
/// [permissionPromptDescription], [permissionPromptButtonText] and [permissionPromptParentalRestriction].
class ARView extends StatefulWidget {
  final String permissionPromptDescription;
  final String permissionPromptButtonText;
  final String permissionPromptParentalRestriction;

  /// Function to be called when the AR View is created
  final ARViewCreatedCallback onARViewCreated;

  /// Configures the type of planes ARCore and ARKit should track. defaults to none
  final PlaneDetectionConfig planeDetectionConfig;

  /// Configures whether or not to display the device's platform type above the AR view. Defaults to false
  final bool showPlatformType;

  ARView(
      {Key? key,
      required this.onARViewCreated,
      this.planeDetectionConfig = PlaneDetectionConfig.none,
      this.showPlatformType = false,
      this.permissionPromptDescription =
          "Camera permission must be given to the app for AR functions to work",
      this.permissionPromptButtonText = "Grant Permission",
      this.permissionPromptParentalRestriction =
          "Camera permission is restriced by the OS, please check parental control settings"})
      : super(key: key);
  @override
  _ARViewState createState() => _ARViewState(
      showPlatformType: this.showPlatformType,
      permissionPromptDescription: this.permissionPromptDescription,
      permissionPromptButtonText: this.permissionPromptButtonText,
      permissionPromptParentalRestriction:
          this.permissionPromptParentalRestriction);
}

class _ARViewState extends State<ARView> {
  // Use 'provisional' as the initial state so we show a loading spinner
  // instead of the permission-denied UI while the async check runs.
  PermissionStatus _cameraPermission = PermissionStatus.provisional;
  bool showPlatformType;
  String permissionPromptDescription;
  String permissionPromptButtonText;
  String permissionPromptParentalRestriction;

  _ARViewState(
      {required this.showPlatformType,
      required this.permissionPromptDescription,
      required this.permissionPromptButtonText,
      required this.permissionPromptParentalRestriction});

  @override
  void initState() {
    super.initState();
    _checkThenRequest();
  }

  // Check status first — if already granted, skip the request dialog.
  _checkThenRequest() async {
    final status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) {
      if (mounted) setState(() => _cameraPermission = status);
      return;
    }
    final requested = await Permission.camera.request();
    if (mounted) setState(() => _cameraPermission = requested);
  }

  requestCameraPermission() async {
    final cameraPermission = await Permission.camera.request();
    if (mounted) setState(() => _cameraPermission = cameraPermission);
  }

  requestCameraPermissionFromSettings() async {
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
    if (mounted) setState(() => _cameraPermission = cameraPermission);
  }

  @override
  build(BuildContext context) {
    switch (_cameraPermission) {
      case (PermissionStatus.provisional): // loading — permission check in flight
        {
          return const Center(child: CircularProgressIndicator());
        }
      case (PermissionStatus.limited):
      case (PermissionStatus.granted):
        {
          return Column(children: [
            if (showPlatformType) Text(Theme.of(context).platform.toString()),
            Expanded(
                child: PlatformARView(Theme.of(context).platform).build(
                    context: context,
                    arViewCreatedCallback: widget.onARViewCreated,
                    planeDetectionConfig: widget.planeDetectionConfig)),
          ]);
        }
      case (PermissionStatus.denied):
        {
          return Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(permissionPromptDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(permissionPromptButtonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDFAF58),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async => {await requestCameraPermission()})
            ],
          ));
        }
      case (PermissionStatus.permanentlyDenied):
        {
          return Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(permissionPromptDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: Text(permissionPromptButtonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDFAF58),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async =>
                      {await requestCameraPermissionFromSettings()})
            ],
          ));
        }
      case (PermissionStatus.restricted):
        {
          return Center(
            child: Text(permissionPromptParentalRestriction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
          );
        }
      default:
        return const SizedBox.shrink();
    }
  }
}

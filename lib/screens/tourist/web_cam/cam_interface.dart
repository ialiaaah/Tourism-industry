// Conditional export: uses real web camera on web, stub on native
export 'cam_stub.dart'
    if (dart.library.html) 'cam_web.dart';

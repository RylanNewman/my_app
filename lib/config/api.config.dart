// import 'dart:io';

// import 'package:flutter/foundation.dart';

// class ApiConfig {
//   /// Returns the base URL for the .NET API depending on platform and environment.
//   static String get baseUrl {
//     // 1. If passed via flutter run --dart-define=BASE_URL=...
//     const String envUrl = String.fromEnvironment('BASE_URL');
//     if (envUrl.isNotEmpty) {
//       return envUrl;
//     }

//     // 2. Web browser target
//     if (kIsWeb) {
//       return 'http://localhost:5246/api';
//     }

//     // 3. Android Emulator (10.0.2.2 points to host machine's localhost)
//     if (Platform.isAndroid) {
//       return 'http://10.0.2.2:5246/api';
//     }

//     // 4. iOS Simulator / macOS / Desktop
//     return 'http://localhost:5246/api';
//   }
// }

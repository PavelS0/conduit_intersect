import 'package:aqueduct/aqueduct.dart';

///
/// Entry point for app
///
Future main() async {
  final app = Application<AppChannel>();
  await app.start(numberOfInstances: 1);

  print("Application started on port: ${app.options.port}.");
  print("Use Ctrl-C (SIGINT) to stop running the application.");
}

class AppChannel extends ApplicationChannel {
  @override
  Controller get entryPoint {
    final router = new Router();

    return router;
  }
}

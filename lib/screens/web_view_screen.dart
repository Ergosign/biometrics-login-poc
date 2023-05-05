import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// This screen hols the logic and the ui for the WebView
class WebViewScreen extends StatefulWidget {
  /// This screen holds the logic and the ui for the WebView
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  final localAuth = LocalAuthentication();
  final storage = const FlutterSecureStorage();

  bool authenticated = false;
  Map<String, String> loginData = {};

  bool get hasLoginData => loginData.isNotEmpty;

  @override
  void initState() {
    super.initState();

    deleteAll();

    storageRead();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterCallback',
        onMessageReceived: (message) async {
          if (message.message == 'authenticated') {
            setState(() {
              authenticated = true;
            });
          }

          if (message.message == 'focused' && hasLoginData) {
            await fillUserData();
          }

          if (message.message.startsWith('loginData:') && !hasLoginData) {
            await saveUserData(message.message);
          }
        },
      )
      ..loadFlutterAsset('assets/index.html');
  }

  Future<void> fillUserData() async {
    final authorized = await authenticateUser();

    if (authorized && hasLoginData) {
      final username = loginData.entries.first.key;
      final password = loginData.entries.first.value;

      await controller.runJavaScript('fillLoginForm("$username","$password")');
    }
  }

  Future<void> saveUserData(String message) async {
    final splitMessage = message.split(':');
    final username = splitMessage[1].split(',')[0].trim();
    final password = splitMessage[1].split(',')[1].trim();

    final hasUsername = await storage.containsKey(key: 'myWebSite_username');
    final hasPassword = await storage.containsKey(key: 'myWebSite_password');

    if (hasUsername && hasPassword) {
      return;
    }

    await addData(username, password);
  }

  Future<bool> authenticateUser() async {
    var authorized = false;

    try {
      authorized = await localAuth.authenticate(
        localizedReason: 'Please authenticate to login.',
      );
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) {
      return false;
    }

    return authorized;
  }

  Future<void> deleteAll() async {
    await storage.deleteAll();

    setState(() {
      loginData = {};
    });
  }

  Future<void> addData(String username, String password) async {
    await storage.write(
      key: 'myWebSite_username',
      value: username,
    );
    await storage.write(
      key: username,
      value: password,
    );

    await storageRead();
  }

  Future<void> storageRead() async {
    final allValues = await storage.readAll();

    if (allValues.isNotEmpty && allValues.containsKey('myWebSite_username')) {
      final username = allValues.entries
          .firstWhere((e) => e.key == 'myWebSite_username')
          .value;
      final password =
          allValues.entries.firstWhereOrNull((e) => e.key == username)?.value;

      if (password != null) {
        setState(() {
          loginData = <String, String>{username: password};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: authenticated
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('logged in'),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            authenticated = false;
                          });
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                )
              : WebViewWidget(controller: controller),
        ),
      ),
    );
  }
}

library flutter_recaptcha_v2;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecaptchaV2 extends StatefulWidget {
  final String apiKey;
  final String pluginURL = "https://recaptcha-flutter-plugin.firebaseapp.com/";
  final RecaptchaV2Controller controller;
  final ValueChanged<String> onResponse;

  RecaptchaV2({
    this.apiKey,
    RecaptchaV2Controller controller,
    this.onResponse,
  })  : controller = controller ?? RecaptchaV2Controller(),
        assert(apiKey != null, "Google ReCaptcha API KEY is missing.");

  @override
  State<StatefulWidget> createState() => _RecaptchaV2State();
}

class _RecaptchaV2State extends State<RecaptchaV2> {
  RecaptchaV2Controller controller;
  WebViewController webViewController;

  void onListen() {
    if (controller.visible) {
      if (webViewController != null) {
        webViewController.clearCache();
        webViewController.reload();
      }
    }
    setState(() {
      controller.visible;
    });
  }

  @override
  void initState() {
    controller = widget.controller;
    controller.addListener(onListen);
    super.initState();
  }

  @override
  void didUpdateWidget(RecaptchaV2 oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(onListen);
      controller = widget.controller;
      controller.removeListener(onListen);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.removeListener(onListen);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller.visible
        ? Stack(
            children: <Widget>[
              WebView(
                initialUrl: "${widget.pluginURL}?api_key=${widget.apiKey}",
                javascriptMode: JavascriptMode.unrestricted,
                javascriptChannels: <JavascriptChannel>[
                  JavascriptChannel(
                    name: 'RecaptchaFlutterChannel',
                    onMessageReceived: (JavascriptMessage receiver) {
                      // print(receiver.message);
                      String _token = receiver.message;
                      widget.onResponse(_token);
                      controller.hide();
                    },
                  ),
                ].toSet(),
                onWebViewCreated: (_controller) {
                  webViewController = _controller;
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          child: Text("CANCEL RECAPTCHA"),
                          onPressed: () {
                            controller.hide();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Container();
  }
}

class RecaptchaV2Controller extends ChangeNotifier {
  bool isDisposed = false;
  List<VoidCallback> _listeners = [];

  bool _visible = false;
  bool get visible => _visible;

  void show() {
    _visible = true;
    if (!isDisposed) notifyListeners();
  }

  void hide() {
    _visible = false;
    if (!isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _listeners = [];
    isDisposed = true;
    super.dispose();
  }

  @override
  void addListener(listener) {
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }
}

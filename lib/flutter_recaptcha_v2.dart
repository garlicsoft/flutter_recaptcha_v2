library flutter_recaptcha_v2;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sprintf/sprintf.dart';

enum RecaptchaPluginType {
  defaultPlugin,
  alternatePlugin,
}

class RecaptchaV2 extends StatefulWidget {
  final String apiKey;
  final String baseURL;
  final RecaptchaPluginType type;
  final RecaptchaV2Controller controller;
  final ValueChanged<String> onResponse;
  final String htmlContent = '''
<!doctype html>
<html class=\"no-js\" lang=\"\">

<head>
  <meta charset=\"utf-8\">
  <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=1\">
  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
  <meta http-equiv=\"content-language\" content=\"en\" />
  <!-- SEO -->
  <title>RECAPTCHA - FLUTTER PLUGIN</title>
  <meta name=\"description\" content=\"A Flutter plugin for Google ReCaptcha\">
  <meta name=\"keywords\" content=\"flutter, recaptcha, plugin, captcha\">
  <meta name=\"author\" content=\"http://wearetopgroup.com\">
  <!-- Social Sharing Info -->
  <meta property=\"og:url\" content=\"\" />
  <meta property=\"og:title\" content=\"RECAPTCHA - FLUTTER PLUGIN\" />
  <meta property=\"og:description\" content=\"A Flutter plugin for Google ReCaptcha\" />
  <meta property=\"og:image\" content=\".../assets/images/share.jpg\" />
  <meta property=\"og:image:width\" content=\"1200\" /> <!-- Full HD: WIDTH -->
  <meta property=\"og:image:height\" content=\"630\" /> <!-- Full HD: HEIGHT -->
  <!-- Viewport and mobile -->
  <meta name=\"viewport\"
    content=\"width=device-width, initial-scale=1.0, user-scalable=no, maximum-scale=1.0, minimum-scale=1.0\">
  <!-- FAVICON -->
  <link rel=\"image_src\" href=\"./images/favicon.ico\" />
  <link rel=\"icon\" type=\"image/gif\" href=\"./images/favicon.ico\" />
  <script src=\"%s\" async defer>
  </script>
</head>
<body>
  <div id=\"html_element\"></div>
  <script type=\"text/javascript\">
    var onloadCallback = function () {
      console.log(\"grecaptcha is ready!\");
      grecaptcha.render(\'html_element\', {
        \'sitekey\': \"%s\",
        \'callback\': verifyCallback
      });
    };
    function verifyCallback(token) {
      console.log(token);
      // console.log(grecaptcha.getResponse());
      try {
        RecaptchaFlutterChannel.postMessage(token);
      } catch (e) {
        console.log(\"Something wrong...\");
      }
    }
  </script>
</body>
</html>
  ''';

  String defaultPluginURL =
      "https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit";
  String alternatePluginURL =
      "https://www.recaptcha.net/recaptcha/api.js?onload=onloadCallback&render=explicit";

  RecaptchaV2({
    this.apiKey,
    this.baseURL,
    this.type,
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
    String pluginURL = widget.type == RecaptchaPluginType.defaultPlugin
        ? widget.defaultPluginURL
        : widget.alternatePluginURL;
    return controller.visible
        ? Stack(
            children: <Widget>[
              WebView(
                initialUrl: "${widget.baseURL}",
                htmlContent:
                    sprintf(widget.htmlContent, [pluginURL, widget.apiKey]),
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

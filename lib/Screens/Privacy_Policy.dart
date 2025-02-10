import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';

class PrivacyPolicy extends StatefulWidget {
  final String? title;
  const PrivacyPolicy({super.key, this.title});
  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? privacy;
  String url = "";
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  late final WebViewController _controller;
  @override
  void initState() {
    super.initState();
    getSetting();
    if (privacy != "" && privacy != null) {}
    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
  }

  void changeTextColor() {
    final String jsCode = '''
    var style = document.createElement('style');
    style.innerHTML = 'body { color: ${Theme.of(context).colorScheme.webFontColor}; }';
    document.head.appendChild(style);
  ''';
    _controller.runJavaScript(jsCode);
  }

  webviewInitialized() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).colorScheme.lightWhite)
      ..loadHtmlString(privacy!)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (final int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageFinished: (final String url) {
            changeTextColor();
          },
          onPageStarted: (final String url) {
            debugPrint('Page started loading: $url');
          },
          onWebResourceError: (final WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (final NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (final JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      );
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled catch (_) {}
  }

  Widget noInternet(final BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            noIntImage(),
            noIntText(context),
            noIntDec(context),
            AppBtn(
              title: getTranslated(context, TRY_AGAIN_INT_LBL),
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();
                Future.delayed(const Duration(seconds: 2)).then(
                  (final _) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                          builder: (final BuildContext context) => super.widget,
                        ),
                      );
                    } else {
                      await buttonController!.reverse();
                      setState(
                        () {},
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: getAppBar(widget.title!, context),
      body: _isNetworkAvail
          ? _isLoading
              ? getProgress(context)
              : privacy != "" && privacy != null
                  ? Padding(
                      padding: const EdgeInsets.all(
                        10.0,
                      ),
                      child: WebViewWidget(controller: _controller),)
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: Text(
                          getTranslated(context, NodataFound)!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                          ),
                        ),
                      ),
                    )
          : noInternet(context),
    );
  }

  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        String? type;
        if (widget.title == getTranslated(context, PRIVACY)!) {
          type = PRIVACY_POLLICY;
        } else if (widget.title == getTranslated(context, TERM)!) {
          type = TERM_COND;
        }
        final parameter = {TYPE: type};
        final Response response = await post(
          getSettingApi,
          body: parameter,
        ).timeout(
          const Duration(
            seconds: timeOut,
          ),
        );
        print("###$parameter ${response.body}");
        final getdata = json.decode(response.body);
        final bool error = getdata["error"];
        final String? msg = getdata["message"];
        if (!error) {
          privacy = getdata["data"].toString();
          webviewInitialized();
        } else {
          setSnackbar(msg!);
        }
        setState(() {
          _isLoading = false;
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, somethingMSg)!);
      }
    } else {
      setState(
        () {
          _isLoading = false;
          _isNetworkAvail = false;
        },
      );
    }
  }

  setSnackbar(final String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
        ),
        backgroundColor: Theme.of(context).colorScheme.white,
        elevation: 1.0,
      ),
    );
  }
}

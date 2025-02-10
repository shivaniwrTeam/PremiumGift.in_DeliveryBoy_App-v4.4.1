import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Notification_Model.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});
  @override
  State<StatefulWidget> createState() => StateNoti();
}

List<Notification_Model> notiList = [];
int offset = 0;
int total = 0;
bool isLoadingmore = true;
bool _isLoading = true;

class StateNoti extends State<NotificationList> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController controller = ScrollController();
  List<Notification_Model> tempList = [];
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  @override
  void initState() {
    getNotification();
    controller.addListener(_scrollListener);
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
    super.initState();
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
                      getNotification();
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

  Future<void> _refresh() {
    setState(
      () {
        _isLoading = true;
      },
    );
    offset = 0;
    total = 0;
    notiList.clear();
    return getNotification();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      key: _scaffoldKey,
      appBar: getAppBar(getTranslated(context, NOTIFICATION)!, context),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer(context)
              : notiList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: kToolbarHeight,
                      ),
                      child: Center(
                        child: Text(
                          getTranslated(context, noNoti)!,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: _refresh,
                      child: ListView.builder(
                        controller: controller,
                        itemCount: (offset < total)
                            ? notiList.length + 1
                            : notiList.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (final context, final index) {
                          return (index == notiList.length && isLoadingmore)
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : listItem(index);
                        },
                      ),
                    )
          : noInternet(
              context,
            ),
    );
  }

  Widget listItem(final int index) {
    final Notification_Model model = notiList[index];
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(
          8.0,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    model.date!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primarytheme,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    child: Text(
                      model.title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    model.desc!,
                  ),
                ],
              ),
            ),
            if (model.img != '') SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(
                          model.img!,
                        ),
                        radius: 25,
                      ),
                    ),
                  ) else Container(
                    height: 0,
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> getNotification() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };
        final Response response = await post(
          getNotificationApi,
          headers: headers,
          body: parameter,
        ).timeout(
          const Duration(
            seconds: timeOut,
          ),
        );
        if (response.statusCode == 200) {
          final getdata = json.decode(
            response.body,
          );
          final bool error = getdata["error"];
          if (!error) {
            total = int.parse(
              getdata["total"],
            );
            if (offset < total) {
              tempList.clear();
              final data = getdata["data"];
              tempList = (data as List)
                  .map(
                    (final data) => Notification_Model.fromJson(data),
                  )
                  .toList();
              notiList.addAll(tempList);
              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }
        }
        if (mounted) {
          setState(
            () {
              _isLoading = false;
            },
          );
        }
      } on TimeoutException catch (_) {
        setSnackbar(
          getTranslated(context, somethingMSg)!,
        );
        setState(
          () {
            _isLoading = false;
          },
        );
      }
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }
    return;
  }

  setSnackbar(final String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.white,
        elevation: 1.0,
      ),
    );
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            isLoadingmore = true;
            if (offset < total) getNotification();
          },
        );
      }
    }
  }
}

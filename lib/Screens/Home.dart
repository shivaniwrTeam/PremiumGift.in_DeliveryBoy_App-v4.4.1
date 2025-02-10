import 'dart:async';
import 'dart:convert';
import 'package:deliveryboy/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Localization/Language_Constant.dart';
import '../Model/Order_Model.dart';
import '../Provider/Theme.dart';
import '../main.dart';
import 'CashCollection.dart';
import 'Login.dart';
import 'NotificationLIst.dart';
import 'OrderDetail.dart';
import 'Privacy_Policy.dart';
import 'Profile.dart';
import 'WalletHistsory.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<StatefulWidget> createState() {
    return StateHome();
  }
}

int? total;
int? offset;
List<Order_Model> orderList = [];
bool isLoadingmore = true;

class StateHome extends State<Home> with TickerProviderStateMixin {
  bool _isLoading = true;
  int curDrwSel = 0;
  late ThemeNotifier themeNotifier;
  bool isDark = false;
  List<String?> languageList = [];
  List<String?> ThemeList = [];
  int? selectLan;
  int? selectTheme;
  bool _isNetworkAvail = true;
  List<Order_Model> tempList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  String? profile;
  String? pass;
  String? mob;
  ScrollController controller = ScrollController();
  List<String> statusList = [
    ALL,
    PLACED,
    PROCESSED,
    SHIPED,
    DELIVERD,
    CANCLED,
    RETURNED,
    awaitingPayment,
  ];
  String? activeStatus = '';
  final GlobalKey<FormState> _formkey1 = GlobalKey<FormState>();
  final passController = TextEditingController();
  @override
  void initState() {
    offset = 0;
    total = 0;
    orderList.clear();
    getSetting();
    getSaveDetail();
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
    controller.addListener(_scrollListener);
    Future.delayed(
      Duration.zero,
      () {
        ThemeList = [
          "System Defualt",
          "Light Mode",
          "Dark Mode",
        ];
      },
    );
    super.initState();
  }

  getSaveDetail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String getlng = await getPrefrence(LAGUAGE_CODE) ?? '';
    final String? getthem = prefs.getString(APP_THEME);
    mob = prefs.getString(MOBILE);
    selectLan = langCode.indexOf(getlng == '' ? "en" : getlng);
    selectTheme = themeCode.indexOf(
      getthem == '' || getthem == DEFAULT_SYSTEM || getthem == null
          ? DEFAULT_SYSTEM
          : getthem == LIGHT
              ? LIGHT
              : DARK,
    );
  }

  List<String> themeCode = [
    DEFAULT_SYSTEM,
    LIGHT,
    DARK,
  ];
  List<String> langCode = [
    ENGLISH,
    HINDI,
    CHINESE,
    SPANISH,
    ARABIC,
    RUSSIAN,
    JAPANESE,
    DEUTSCH,
  ];
  get lightWhite => null;
  @override
  Widget build(final BuildContext context) {
    themeNotifier = context.read<ThemeNotifier>();
    return Selector<ThemeNotifier, ThemeMode>(
        selector: (final _, final themeProvider) => themeProvider.getThemeMode(),
        builder: (final context, final data, final child) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: lightWhite,
            appBar: AppBar(
              title: Text(
                appName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primarytheme,
                ),
              ),
              iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.primarytheme,),
              backgroundColor: Theme.of(context).colorScheme.white,
              actions: [
                InkWell(
                  onTap: filterDialog,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.filter_alt_outlined,
                      color: Theme.of(context).colorScheme.primarytheme,
                    ),
                  ),
                ),
              ],
            ),
            drawer: _getDrawer(),
            body: _isNetworkAvail
                ? _isLoading
                    ? shimmer(context)
                    : RefreshIndicator(
                        key: _refreshIndicatorKey,
                        onRefresh: _refresh,
                        child: SingleChildScrollView(
                          controller: controller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailHeader(),
                                if (orderList.isEmpty) Center(
                                        child: Text(
                                          getTranslated(context, noItem)!,
                                        ),
                                      ) else ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: (offset! < total!)
                                            ? orderList.length + 1
                                            : orderList.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (final context, final index) {
                                          return (index == orderList.length &&
                                                  isLoadingmore)
                                              ? const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : orderItem(
                                                  index,
                                                );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),
                      )
                : noInternet(context),
          );
        },);
  }

  void filterDialog() {
    showDialog(
      context: context,
      builder: (final BuildContext context) {
        return AlertDialog(
          elevation: 2.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(
                5.0,
              ),
            ),
          ),
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: 19.0,
                    bottom: 16.0,
                  ),
                  child: Text(
                    getTranslated(context, FILTER_BY)!,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,),
                  ),
                ),
                const Divider(),
                OverflowBar(alignment: MainAxisAlignment.center, children: [
                  SingleChildScrollView(
                    child: Column(
                      children: getStatusList(),
                    ),
                  ),
                ],),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> getStatusList() {
    return statusList
        .asMap()
        .map(
          (final index, final element) => MapEntry(
            index,
            Column(
              children: [
                SizedBox(
                  width: double.maxFinite,
                  child: TextButton(
                    child: Center(
                      child: Text(
                        capitalize(
                          statusList[index],
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                              color:
                                  Theme.of(context).colorScheme.lightfontColor,
                            ),
                      ),
                    ),
                    onPressed: () {
                      setState(
                        () {
                          activeStatus = index == 0 ? "" : statusList[index];
                          _isLoading = true;
                          isLoadingmore = true;
                          offset = 0;
                          orderList.clear();
                        },
                      );
                      getOrder();
                      Navigator.pop(context, 'option $index');
                    },
                  ),
                ),
                const Divider(
                  height: 1,
                ),
              ],
            ),
          ),
        )
        .values
        .toList();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            isLoadingmore = true;
            if (offset! < total!) getOrder();
          },
        );
      }
    }
  }

  _getDrawer() {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.white,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              _getHeader(),
              _getDivider(),
              _getDrawerItem(
                0,
                getTranslated(context, HOME_LBL)!,
                Icons.home_outlined,
              ),
              _getDivider(),
              _getDrawerItem(
                1,
                getTranslated(context, WALLET)!,
                Icons.account_balance_wallet_outlined,
              ),
              _getDrawerItem(
                2,
                getTranslated(context, CASH_COLL)!,
                Icons.money_outlined,
              ),
              _getDivider(),
              _getDrawerItem(
                7,
                getTranslated(context, "Change Theme")!,
                Icons.color_lens,
              ),
              _getDrawerItem(
                6,
                getTranslated(context, ChangeLanguage)!,
                Icons.translate,
              ),
              _getDivider(),
              _getDrawerItem(
                3,
                getTranslated(context, PRIVACY)!,
                Icons.lock_outline,
              ),
              _getDrawerItem(
                4,
                getTranslated(context, TERM)!,
                Icons.speaker_notes_outlined,
              ),
              if (CUR_USERID == "" || CUR_USERID == "") Container() else _getDivider(),
              if (CUR_USERID == "" || CUR_USERID == "") Container() else _getDrawerItem(
                      5,
                      getTranslated(context, 'DEL_ACC_LBL')!,
                      Icons.delete,
                    ),
              if (CUR_USERID == "" || CUR_USERID == "") Container() else _getDrawerItem(
                      8,
                      getTranslated(context, LOGOUT)!,
                      Icons.input,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  _getHeader() {
    return InkWell(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primarytheme,
        ),
        padding: const EdgeInsets.only(
          left: 10.0,
          bottom: 10,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CUR_USERNAME!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).colorScheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (CUR_BALANCE != "") Text(
                            getPriceFormat(
                              context,
                              double.parse(CUR_BALANCE),
                            )!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    color: Theme.of(context).colorScheme.white,),
                            softWrap: true,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ) else const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTranslated(context, EDIT_PROFILE_LBL)!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.white,
                                ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 5.0),
                            child: Icon(
                              Icons.arrow_forward_ios_outlined,
                              color: Theme.of(context).colorScheme.white,
                              size: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(
                top: 20,
                right: 20,
              ),
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: imagePlaceHolder(62, context),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (final context) => const Profile(),
          ),
        );
        setState(
          () {},
        );
      },
    );
  }

  _getDivider() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Divider(
        height: 1,
      ),
    );
  }

  _getDrawerItem(
    final int index,
    final String title,
    final IconData icn,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: ListTile(
        dense: true,
        leading: Icon(
          icn,
          color: Theme.of(context).colorScheme.lightfontColor2,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
          ),
        ),
        onTap: () {
          setState(
            () {
              curDrwSel = index;
            },
          );
          Navigator.of(context).pop();
          if (title == getTranslated(context, HOME_LBL)!) {
            Navigator.pushNamedAndRemoveUntil(context, "/home", (final r) => false);
          } else if (title == getTranslated(context, NOTIFICATION)!) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (final context) => const NotificationList(),
              ),
            );
          } else if (title == getTranslated(context, "Change Theme")!) {
            colorDialog();
          } else if (title == getTranslated(context, LOGOUT)!) {
            logOutDailog();
          } else if (title == getTranslated(context, ChangeLanguage)!) {
            languageDialog();
          } else if (title == getTranslated(context, PRIVACY)!) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (final context) => PrivacyPolicy(
                  title: getTranslated(context, PRIVACY),
                ),
              ),
            );
          } else if (title == getTranslated(context, TERM)!) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (final context) => PrivacyPolicy(
                  title: getTranslated(context, TERM),
                ),
              ),
            );
          } else if (title == getTranslated(context, WALLET)!) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (final context) => const WalletHistory(),
              ),
            );
          } else if (title == getTranslated(context, CASH_COLL)!) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (final context) => const CashCollection(),
              ),
            );
          } else if (title == getTranslated(context, 'DEL_ACC_LBL')) {
            _showDialog();
          }
        },
      ),
    );
  }

  _showDialog() async {
    await showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.fontColor.withOpacity(0.5),
        transitionBuilder: (final context, final a1, final a2, final widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(opacity: a1.value, child: deleteConfirmDailog()),
          );
        },
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        pageBuilder: (final context, final animation1, final animation2) {
          return Container();
        },);
  }

  deleteConfirmDailog() {
    int from = 0;
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),),
      title: Text(getTranslated(context, 'DEL_YR_ACC_LBL')!,
          textAlign: TextAlign.center,),
      content: StatefulBuilder(builder: (final context, final StateSetter setStater) {
        return Form(
          key: _formkey1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                from == 0
                    ? getTranslated(context, 'DEL_ACC_TXT_LBL')!
                    : getTranslated(context, 'ADD_PASS_DEL_LBL')!,
                textAlign: TextAlign.center,
                style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .fontColor
                        .withOpacity(0.8),),
              ),
              if (from == 1)
                Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),),
                      height: 50,
                      child: TextFormField(
                        controller: passController,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor,),
                        onSaved: (final val) {
                          setStater(() {
                            pass = val;
                          });
                        },
                        validator: (final value) => validatePass(value, context),
                        enabled: true,
                        textAlign: TextAlign.left,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    Theme.of(context).colorScheme.lightWhite,),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(15.0, 10.0, 10, 10.0),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          fillColor: Theme.of(context).colorScheme.lightWhite,
                          filled: true,
                          isDense: true,
                          hintText: getTranslated(context, 'Password'),
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.7),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                        ),
                      ),
                    ),),
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0, top: 20),
                child: from == 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 10, bottom: 10, start: 20, end: 20,),
                                  height: 40,
                                  alignment: FractionalOffset.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0),),
                                  ),
                                  child: Text(getTranslated(context, 'Cancel')!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold,
                                          ),),),),
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setStater(() {
                                  from = 1;
                                });
                              },
                              child: Container(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 10, bottom: 10, start: 20, end: 20,),
                                  height: 40,
                                  alignment: FractionalOffset.center,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primarytheme,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0),),
                                  ),
                                  child: Text(
                                      getTranslated(context, 'CONFIRM_LBL')!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white,
                                            fontWeight: FontWeight.bold,
                                          ),),),),
                        ],
                      )
                    : InkWell(
                        onTap: () {
                          final form = _formkey1.currentState!;
                          form.save();
                          if (form.validate()) {
                            setState(() {});
                            Navigator.of(context, rootNavigator: true)
                                .pop(true);
                            setDeleteAcc();
                          }
                        },
                        child: Container(
                            margin: EdgeInsetsDirectional.only(
                                top: 10,
                                bottom: 10,
                                start: deviceWidth! / 5.3,
                                end: deviceWidth! / 5.3,),
                            height: 40,
                            alignment: FractionalOffset.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primarytheme,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Text(getTranslated(context, 'DEL_ACC_LBL')!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold,
                                    ),),),),
              ),
            ],
          ),
        );
      },),
    );
  }

  Future<void> setDeleteAcc() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          USER_ID: CUR_USERID,
          PASSWORD: passController.text.trim(),
          MOBILE: mob,
        };
        final response = await post(
          setDeleteAccApi,
          body: parameter,
          headers: headers,
        ).timeout(
          const Duration(
            seconds: timeOut,
          ),
        );
        if (response.statusCode == 200) {
          final getdata = json.decode(response.body);
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            setSnackbar(msg!);
            passController.clear();
            SchedulerBinding.instance.addPostFrameCallback((final _) async {
              Navigator.of(context).pushAndRemoveUntil(
                  CupertinoPageRoute(
                    builder: (final context) => const Login(),
                  ),
                  (final Route<dynamic> route) => false,);
            });
            setState(() {});
          } else {
            setState(() {});
            setSnackbar(msg!);
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  colorDialog() async {
    await dialogAnimate(
      context,
      StatefulBuilder(
        builder: (final BuildContext context, final StateSetter setStater) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                  child: Text(
                    "Choose Theme",
                    style:
                        Theme.of(this.context).textTheme.titleMedium!.copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                            ),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    child: Builder(builder: (final context) {
                      return Column(
                        children: getThemeList(
                          context,
                        ),
                      );
                    },),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> getThemeList(final BuildContext ctx) {
    return ThemeList.asMap()
        .map(
          (final index, final element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  selectTheme = index;
                  _themeLan(
                    themeCode[index],
                    ctx,
                    index,
                  );
                  setState(
                    () {},
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 25.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectTheme == index
                                ? Theme.of(context).colorScheme.primarytheme
                                : Theme.of(context).colorScheme.white,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primarytheme,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: selectTheme == index
                                ? Icon(
                                    Icons.check,
                                    size: 17.0,
                                    color: Theme.of(context).colorScheme.white,
                                  )
                                : Icon(
                                    Icons.check_box_outline_blank,
                                    size: 15.0,
                                    color: Theme.of(context).colorScheme.white,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 15.0,
                          ),
                          child: Text(
                            getTranslated(context, ThemeList[index]!)!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor,),
                          ),
                        ),
                      ],
                    ),
                    if (index == ThemeList.length - 1) Container(
                            margin: const EdgeInsetsDirectional.only(
                              bottom: 10,
                            ),
                          ) else const Divider(),
                  ],
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  languageDialog() async {
    await dialogAnimate(
      context,
      StatefulBuilder(
        builder: (final BuildContext context, final StateSetter setStater) {
          languageList = [
            getTranslated(context, 'English'),
            getTranslated(context, 'Hindi'),
            getTranslated(context, 'Chinese'),
            getTranslated(context, 'Spanish'),
            getTranslated(context, 'Arabic'),
            getTranslated(context, 'Russian'),
            getTranslated(context, 'Japanese'),
            getTranslated(context, 'Deutch'),
          ];
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                  child: Text(
                    getTranslated(context, CHOOSE_LANGUAGE_LBL)!,
                    style:
                        Theme.of(this.context).textTheme.titleMedium!.copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                            ),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: getLngList(
                        context,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> getLngList(final BuildContext ctx) {
    return languageList
        .asMap()
        .map(
          (final index, final element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  setState(
                    () {
                      selectLan = index;
                      _changeLan(langCode[index], ctx);
                    },
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 25.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectLan == index
                                ? Theme.of(context).colorScheme.primarytheme
                                : Theme.of(context).colorScheme.white,
                            border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.primarytheme,),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: selectLan == index
                                ? Icon(
                                    Icons.check,
                                    size: 17.0,
                                    color: Theme.of(context).colorScheme.white,
                                  )
                                : Icon(
                                    Icons.check_box_outline_blank,
                                    size: 15.0,
                                    color: Theme.of(context).colorScheme.white,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 15.0,
                          ),
                          child: Text(
                            languageList[index]!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor,),
                          ),
                        ),
                      ],
                    ),
                    if (index == languageList.length - 1) Container(
                            margin: const EdgeInsetsDirectional.only(
                              bottom: 10,
                            ),
                          ) else const Divider(),
                  ],
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  Future<void> _themeLan(
    final String language,
    final BuildContext ctx,
    final int index,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (index == 0) {
      themeNotifier.setThemeMode(ThemeMode.system);
      prefs.setString(APP_THEME, DEFAULT_SYSTEM);
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      if (mounted) {
        setState(
          () {
            isDark = brightness == Brightness.dark;
            if (isDark) {
              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
            } else {
              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
            }
          },
        );
      }
    } else if (index == 1) {
      themeNotifier.setThemeMode(ThemeMode.light);
      prefs.setString(APP_THEME, LIGHT);
      if (mounted) {
        setState(() {
          isDark = false;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        });
      }
    } else {
      themeNotifier.setThemeMode(ThemeMode.dark);
      prefs.setString(APP_THEME, DARK);
      if (mounted) {
        setState(() {
          isDark = true;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        });
      }
    }
    ISDARK = isDark.toString();
    Navigator.pop(context);
  }

  Future<void> _changeLan(
    final String language,
    final BuildContext ctx,
  ) async {
    final Locale locale = await setLocale(language);
    MyApp.setLocale(ctx, locale);
  }

  @override
  void dispose() {
    buttonController!.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    offset = 0;
    total = 0;
    orderList.clear();
    setState(
      () {
        _isLoading = true;
      },
    );
    orderList.clear();
    return getOrder();
  }

  logOutDailog() async {
    await showDialog(
      context: context,
      builder: (final BuildContext context) {
        return StatefulBuilder(
          builder: (final BuildContext context, final StateSetter setStater) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    5.0,
                  ),
                ),
              ),
              content: Text(
                getTranslated(context, LOGOUTTXT)!,
                style: Theme.of(this.context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                    ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    getTranslated(context, LOGOUTNO)!,
                    style: Theme.of(this.context)
                        .textTheme
                        .titleSmall!
                        .copyWith(
                          color: Theme.of(context).colorScheme.lightfontColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    getTranslated(context, LOGOUTYES)!,
                    style:
                        Theme.of(this.context).textTheme.titleSmall!.copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  onPressed: () {
                    clearUserSession();
                    Navigator.of(context).pushAndRemoveUntil(
                        CupertinoPageRoute(
                          builder: (final context) => const Login(),
                        ),
                        (final Route<dynamic> route) => false,);
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
                      getOrder();
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

  Future<void> getOrder() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (offset == 0) {
        orderList = [];
      }
      try {
        CUR_USERID = await getPrefrence(ID);
        CUR_USERNAME = await getPrefrence(USERNAME);
        final parameter = {
          USER_ID: CUR_USERID,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };
        if (activeStatus != "") {
          if (activeStatus == awaitingPayment) activeStatus = "awaiting";
          parameter[ACTIVE_STATUS] = activeStatus;
        }
        final Response response =
            await post(getOrdersApi, body: parameter, headers: headers).timeout(
          const Duration(
            seconds: timeOut,
          ),
        );
        print("param order*****$parameter********$getOrdersApi");
        final getdata = json.decode(response.body);
        final bool error = getdata["error"];
        total = int.parse(getdata["total"]);
        if (!error) {
          if (offset! < total!) {
            tempList.clear();
            final data = getdata["data"];
            tempList = (data as List)
                .map((final data) => Order_Model.fromJson(data))
                .toList();
            orderList.addAll(tempList);
            offset = offset! + perPage;
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
      } on FormatException catch (e) {
        setSnackbar(e.message);
      }
    } else {
      if (mounted) {
        setState(
          () {
            _isNetworkAvail = false;
          },
        );
      }
    }
    return;
  }

  Future<void> getUserDetail() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        CUR_USERID = await getPrefrence(ID);
        final parameter = {ID: CUR_USERID};
        print("cur_userid****$CUR_USERID");
        final Response response =
            await post(getBoyDetailApi, body: parameter, headers: headers)
                .timeout(
          const Duration(
            seconds: timeOut,
          ),
        );
        final getdata = json.decode(response.body);
        final bool error = getdata["error"];
        if (!error) {
          final data = getdata["data"];
          CUR_BALANCE = double.parse(data[BALANCE]).toStringAsFixed(2);
          CUR_BONUS = data[BONUS];
          CUR_DRIVING_LICENSE = data[DRIVING_LICENSE];
          setListPrefrence(DRIVING_LICENSE, CUR_DRIVING_LICENSE);
        }
      } on TimeoutException catch (_) {
        setSnackbar(
          getTranslated(context, somethingMSg)!,
        );
      }
    } else {
      if (mounted) {
        setState(
          () {
            _isNetworkAvail = false;
          },
        );
      }
    }
    return;
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

  orderItem(final int index) {
    final Order_Model model = orderList[index];
    Color back;
    if ((model.activeStatus) == DELIVERD) {
      back = Colors.green;
    } else if ((model.activeStatus) == SHIPED) {
      back = Colors.orange;
    } else if ((model.activeStatus) == CANCLED ||
        model.activeStatus == RETURNED) {
      back = Colors.red;
    } else if ((model.activeStatus) == PROCESSED) {
      back = Colors.indigo;
    } else if (model.activeStatus == WAITING) {
      back = Theme.of(context).colorScheme.fontColor;
    } else if (model.itemList![0].status! == 'return_request_decline') {
      back = Colors.red;
    } else if (model.itemList![0].status! == 'return_request_pending') {
      back = Colors.indigo.withOpacity(0.85);
    } else {
      back = Colors.cyan;
    }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(5.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      getTranslated(context, OrderNumber)! + model.id!,
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2,),
                      decoration: BoxDecoration(
                        color: back,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(
                            4.0,
                          ),
                        ),
                      ),
                      child: Text(
                        model.activeStatus
                            .toString()
                            .replaceAll('_', ' ')
                            .toTitleCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Theme.of(context).colorScheme.primarytheme,
                          ),
                          Expanded(
                            child: Text(
                              model.name != "" && model.name!.isNotEmpty
                                  ? " ${capitalize(
                                      model.name!,
                                    )}"
                                  : " ",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      child: Row(
                        children: [
                          Icon(
                            Icons.call,
                            size: 14,
                            color: Theme.of(context).colorScheme.fontColor,
                          ),
                          Text(
                            " ${model.mobile!}",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _launchCaller(index);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.money,
                            size: 14,
                            color: Theme.of(context).colorScheme.primarytheme,
                          ),
                          Expanded(
                            child: Text(
                              " ${getTranslated(context, TOTAL_AMOUNT)!}: ${getPriceFormat(
                                context,
                                double.parse(
                                  model.payable!,
                                ),
                              )!}",
                              overflow: TextOverflow.clip,
                              softWrap: true,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.payment,
                            size: 14,
                            color: Theme.of(context).colorScheme.primarytheme,
                          ),
                          Expanded(
                            child: Text(
                              " ${model.payMethod!}",
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 14,
                      color: Theme.of(context).colorScheme.primarytheme,
                    ),
                    Text(
                      " ${getTranslated(context, OrderNumber)!}: ${model.orderDate!}",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (final context) => OrderDetail(
                model: orderList[index],
              ),
            ),
          );
          setState(
            () {
              getUserDetail();
            },
          );
        },
      ),
    );
  }

  _launchCaller(final index) async {
    final url = "tel:${orderList[index].mobile}";
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _detailHeader() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(
                18.0,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Theme.of(context).colorScheme.fontColor,
                  ),
                  Text(
                    getTranslated(context, ORDER)!,
                  ),
                  Text(
                    total.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(
                18.0,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Theme.of(context).colorScheme.fontColor,
                  ),
                  Text(
                    getTranslated(context, BAL_LBL)!,
                  ),
                  if (CUR_BALANCE != "") Text(
                          getPriceFormat(
                            context,
                            double.parse(
                              CUR_BALANCE,
                            ),
                          )!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ) else const SizedBox(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Icon(
                    Icons.wallet_giftcard_outlined,
                    color: Theme.of(context).colorScheme.fontColor,
                  ),
                  Text(
                    getTranslated(context, BONUS_LBL)!,
                  ),
                  Text(
                    CUR_BONUS!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> getSetting() async {
    try {
      CUR_USERID = await getPrefrence(ID);
      final parameter = {TYPE: CURRENCY};
      final Response response =
          await post(getSettingApi, body: parameter, headers: headers).timeout(
        const Duration(
          seconds: timeOut,
        ),
      );
      if (response.statusCode == 200) {
        final getdata = json.decode(response.body);
        final bool error = getdata["error"];
        final String? msg = getdata["message"];
        if (!error) {
          CUR_CURRENCY = getdata["currency"] ?? "";
          SUPPORTED_LOCALES = getdata["supported_locals"] != "" &&
                  getdata["supported_locals"] != null
              ? getdata["supported_locals"]
              : "hi";
          if (getdata["system_settings"]
              .toString()
              .contains(MAINTAINANCE_MODE)) {
            Is_APP_IN_MAINTANCE = getdata["system_settings"][MAINTAINANCE_MODE];
          }
          if (Is_APP_IN_MAINTANCE != "1") {
            getUserDetail();
            getOrder();
          }
          if (getdata["system_settings"]
              .toString()
              .contains(MAINTAINANCE_MESSAGE)) {
            IS_APP_MAINTENANCE_MESSAGE =
                getdata["system_settings"][MAINTAINANCE_MESSAGE];
          }
          if (Is_APP_IN_MAINTANCE == "1") {
            appMaintenanceDialog(context);
          }
        } else {
          setSnackbar(msg!);
        }
      }
    } on TimeoutException catch (_) {
      setSnackbar(
        getTranslated(context, somethingMSg)!,
      );
    } on FormatException catch (e) {
      setSnackbar(e.message);
    }
  }

  Future<void> appMaintenanceDialog(final BuildContext context) async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (final BuildContext context, final StateSetter setStater) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),),
          title: Text(
            getTranslated(context, APP_MAINTENANCE)!,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,
                fontSize: 16,),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                child: Lottie.asset('assets/animation/maintenance.json'),
              ),
              const SizedBox(
                height: 25,
              ),
              if (IS_APP_MAINTENANCE_MESSAGE != '') Text(
                      IS_APP_MAINTENANCE_MESSAGE!,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.normal,
                          fontSize: 12,),
                    ) else const SizedBox(),
            ],
          ),
        ),
      );
    },),);
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'Login.dart';

class SetPass extends StatefulWidget {
  final String mobileNumber;
  const SetPass({
    super.key,
    required this.mobileNumber,
  })  : assert(mobileNumber != "");
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<SetPass> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final confirmpassController = TextEditingController();
  final passwordController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  String? password;
  String? comfirmpass;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  Future<void> validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> checkNetwork() async {
    final bool avail = await isNetworkAvailable();
    if (avail) {
      getResetPass();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((final _) async {
        setState(() {
          _isNetworkAvail = false;
        });
        await buttonController!.reverse();
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  setSnackbar(final String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
        ),
        backgroundColor: Theme.of(context).colorScheme.lightWhite,
        elevation: 1.0,
      ),
    );
  }

  Widget noInternet(final BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kToolbarHeight),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, TRY_AGAIN_INT_LBL),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();
              Future.delayed(const Duration(seconds: 2)).then((final _) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                          builder: (final BuildContext context) => super.widget,),);
                } else {
                  await buttonController!.reverse();
                  setState(() {});
                }
              });
            },
          ),
        ],),
      ),
    );
  }

  Future<void> getResetPass() async {
    try {
      final data = {
        MOBILENO: widget.mobileNumber,
        NEWPASS: password,
      };
      final Response response =
          await post(getResetPassApi, body: data, headers: headers)
              .timeout(const Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        final getdata = json.decode(response.body);
        final bool error = getdata["error"];
        final String? msg = getdata["message"];
        await buttonController!.reverse();
        if (!error) {
          setSnackbar(PASS_SUCCESS_MSG);
          Future.delayed(const Duration(seconds: 1)).then((final _) {
            Navigator.of(context).pushReplacement(CupertinoPageRoute(
              builder: (final BuildContext context) => const Login(),
            ),);
          });
        } else {
          setSnackbar(msg!);
        }
      }
      setState(() {});
    } on TimeoutException catch (_) {
      setSnackbar(somethingMSg);
      await buttonController!.reverse();
    }
  }

  subLogo() {
    return Expanded(
      child: Center(
          child: SvgPicture.asset(
        'assets/images/homelogo.svg',
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.primarytheme,
          BlendMode.srcIn,
        ),
      ),),
    );
  }

  forgotpassTxt() {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Center(
        child: Text(
          getTranslated(context, FORGOT_PASSWORDTITILE)!,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  setPass() {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 30.0),
      child: TextFormField(
        keyboardType: TextInputType.text,
        obscureText: true,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
        controller: passwordController,
        validator: (final value) => validatePass(value, context),
        onSaved: (final String? value) {
          password = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Theme.of(context).colorScheme.fontColor,
          ),
          hintText: getTranslated(context, PASSHINT_LBL),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 25),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setConfirmpss() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 25.0,
        right: 25.0,
        top: 20.0,
      ),
      child: TextFormField(
        keyboardType: TextInputType.text,
        obscureText: true,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
        controller: confirmpassController,
        validator: (final value) {
          if (value!.isEmpty) {
            return getTranslated(context, CON_PASS_REQUIRED_MSG);
          }
          if (value != password) {
            return getTranslated(context, CON_PASS_NOT_MATCH_MSG);
          } else {
            return null;
          }
        },
        onSaved: (final String? value) {
          comfirmpass = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Theme.of(context).colorScheme.fontColor,
          ),
          hintText: CONFIRMPASSHINT_LBL,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 25),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  backBtn() {
    return Platform.isIOS
        ? Container(
            padding: const EdgeInsets.only(top: 20.0, left: 10.0),
            alignment: Alignment.topLeft,
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: InkWell(
                  child: Icon(Icons.arrow_back_ios_outlined,
                      color: Theme.of(context).colorScheme.primarytheme,),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          )
        : Container();
  }

  @override
  void initState() {
    super.initState();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this,);
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

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled catch (_) {}
  }

  setPassBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      child: AppBtn(
        title: getTranslated(context, SET_PASSWORD),
        btnAnim: buttonSqueezeanimation,
        btnCntrl: buttonController,
        onBtnSelected: () async {
          validateAndSubmit();
        },
      ),
    );
  }

  expandedBottomView() {
    return Expanded(
      child: SingleChildScrollView(
        child: Form(
          key: _formkey,
          child: Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            margin: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
            ),
            child: Column(
              children: [
                forgotpassTxt(),
                setPass(),
                setConfirmpss(),
                setPassBtn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _isNetworkAvail
          ? Container(
              color: Theme.of(context).colorScheme.lightWhite,
              padding: const EdgeInsets.only(
                bottom: 20.0,
              ),
              child: Column(
                children: <Widget>[
                  backBtn(),
                  subLogo(),
                  expandedBottomView(),
                ],
              ),
            )
          : noInternet(context),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:deliveryboy/Helper/translate.dart';
import 'package:deliveryboy/Screens/register_deliveryboy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'Home.dart';
import 'Privacy_Policy.dart';
import 'Send_Otp.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final mobileController =
      TextEditingController(text: isDemoApp ? "1234567890" : "");
  final passwordController =
      TextEditingController(text: isDemoApp ? "12345678" : "");
  String? countryName;
  FocusNode? passFocus;
  FocusNode? monoFocus = FocusNode();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool visible = false;
  String? password;
  String? mobile;
  String? username;
  String? email;
  String? id;
  String? mobileno;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool showPassword = false;
  void toggleShowPassword() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  @override
  void initState() {
    super.initState();
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

  Future<void> validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  Future<void> checkNetwork() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getLoginUser();
    } else {
      Future.delayed(const Duration(seconds: 2)).then(
        (final _) async {
          await buttonController!.reverse();
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        },
      );
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.lightWhite,
        elevation: 1.0,
      ),
    );
  }

  Widget noInternet(final BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: kToolbarHeight,
        ),
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

  Future<void> getLoginUser() async {
    final data = {
      MOBILE: mobile,
      PASSWORD: password,
    };
    try {
      final response = await post(
        getUserLoginApi,
        body: data,
      ).timeout(
        const Duration(
          seconds: timeOut,
        ),
      );
      if (response.statusCode == 200) {
        final getdata = json.decode(response.body);
        final bool error = getdata["error"];
        final String? msg = getdata["message"];
        await buttonController!.reverse();
        if (!error) {
          setSnackbar(msg!);
          print("LOGIN DATA is ${response.body}");
          final i = getdata["data"];
          id = i[ID];
          username = i[USERNAME];
          email = i[EMAIL];
          mobile = i[MOBILE];
          CUR_USERID = id;
          CUR_USERNAME = username;
          saveUserDetail(id!, username!, email!, mobile!, getdata['token']);
          setPrefrenceBool(isLogin, true);
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (final context) => const Home(),
            ),
          );
        } else {
          setSnackbar(msg!);
        }
      } else {
        await buttonController!.reverse();
      }
    } on TimeoutException catch (_) {
      await buttonController!.reverse();
      setSnackbar(getTranslated(context, somethingMSg)!);
    }
  }

  _subLogo() {
    return Expanded(
      flex: 4,
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

  signInTxt() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 30.0,
      ),
      child: Align(
        child: Text(
          getTranslated(context, SIGNIN_LBL)!,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  termAndPolicyTxt() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 30.0,
        left: 25.0,
        right: 25.0,
        top: 10.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            getTranslated(context, CONTINUE_AGREE_LBL)!,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal,
                ),
          ),
          const SizedBox(
            height: 3.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (final context) => PrivacyPolicy(
                        title: getTranslated(
                          context,
                          TERM,
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  getTranslated(context, TERMS_SERVICE_LBL)!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ),
              const SizedBox(
                width: 5.0,
              ),
              Text(
                getTranslated(context, AND_LBL)!,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.normal,
                    ),
              ),
              const SizedBox(
                width: 5.0,
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (final context) => PrivacyPolicy(
                        title: getTranslated(context, PRIVACY),
                      ),
                    ),
                  );
                },
                child: Text(
                  getTranslated(context, PRIVACY_POLICY_LBL)!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  setMobileNo() {
    return Container(
      width: deviceWidth! * 0.7,
      padding: const EdgeInsets.only(
        top: 30.0,
      ),
      child: TextFormField(
        onFieldSubmitted: (final v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.number,
        controller: mobileController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.normal,
        ),
        focusNode: monoFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        validator: (final value) => validateMob(
          value,
          context,
        ),
        onSaved: (final String? value) {
          mobile = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.call_outlined,
            color: Theme.of(context).colorScheme.fontColor,
            size: 17,
          ),
          hintText: getTranslated(context, MOBILEHINT_LBL),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,
              ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            maxHeight: 20,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.fontColor,
            ),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.lightWhite,
            ),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    );
  }

  setPass() {
    return Container(
      width: deviceWidth! * 0.7,
      padding: const EdgeInsets.only(top: 20.0),
      child: TextFormField(
        keyboardType: TextInputType.text,
        obscureText: !showPassword,
        focusNode: passFocus,
        style: TextStyle(
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
            size: 17,
          ),
          suffixIcon: IconButton(
            onPressed: toggleShowPassword,
            icon: Icon(
              showPassword ? Icons.visibility : Icons.visibility_off,
              color: Theme.of(context).colorScheme.fontColor,
              size: 17,
            ),
          ),
          hintText: getTranslated(context, PASSHINT_LBL),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,
              ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            maxHeight: 20,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            maxHeight: 30,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.fontColor,
            ),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.lightWhite,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  forgetPass() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 25.0,
        right: 45.0,
        top: 15.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (final context) => SendOtp(
                    title: getTranslated(context, FORGOT_PASS_TITLE),
                  ),
                ),
              );
            },
            child: Text(
              getTranslated(context, FORGOT_PASSWORD_LBL)!,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  loginBtn() {
    return AppBtn(
      title: getTranslated(context, SIGNIN_LBL),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        validateAndSubmit();
      },
    );
  }

  _expandedBottomView() {
    return Expanded(
      flex: 6,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  signInTxt(),
                  setMobileNo(),
                  setPass(),
                  forgetPass(),
                  loginBtn(),
                  registerButton(),
                  const SizedBox(
                    height: 5,
                  ),
                  termAndPolicyTxt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  registerButton() {
    return RichText(
      text: TextSpan(
        text: "Donthaveanaccount".translate(context),
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontSize: 16.0,
        ),
        children: <TextSpan>[
          TextSpan(
            text: 'Signup'.translate(context),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (final context, final animation, final secondaryAnimation) {
                    return const RegisterDeliveryBoyScreen();
                  },
                ),);
              },
            style: TextStyle(
              color: Theme.of(context).colorScheme.primarytheme,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
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
                  _subLogo(),
                  _expandedBottomView(),
                ],
              ),
            )
          : noInternet(context),
    );
  }
}

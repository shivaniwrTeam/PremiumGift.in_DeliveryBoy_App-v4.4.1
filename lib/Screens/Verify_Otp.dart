import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'Set_Password.dart';

class VerifyOtp extends StatefulWidget {
  final String? mobileNumber;
  final String? countryCode;
  final String? title;
  const VerifyOtp(
      {super.key,
      required String this.mobileNumber,
      this.countryCode,
      this.title,})
      : assert(mobileNumber != "");
  @override
  _MobileOTPState createState() => _MobileOTPState();
}

class _MobileOTPState extends State<VerifyOtp> with TickerProviderStateMixin {
  final dataKey = GlobalKey();
  String? password;
  String? mobile;
  String? countrycode;
  String? otp;
  bool isCodeSent = false;
  String _verificationId = "";
  String signature = "";
  bool _isClickable = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  @override
  void initState() {
    super.initState();
    getUserDetails();
    getSingature();
    _onVerifyCode();
    Future.delayed(const Duration(seconds: 60)).then(
      (final _) {
        _isClickable = true;
      },
    );
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

  Future<void> getSingature() async {
    signature = await SmsAutoFill().getAppSignature;
    SmsAutoFill().listenForCode;
  }

  getUserDetails() async {
    mobile = await getPrefrence(MOBILE);
    countrycode = await getPrefrence(COUNTRY_CODE);
    setState(() {});
  }

  Future<void> checkNetworkOtp() async {
    final bool avail = await isNetworkAvailable();
    if (avail) {
      if (_isClickable) {
        _onVerifyCode();
      } else {
        setSnackbar(getTranslated(context, OTPWR)!);
      }
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
      Future.delayed(const Duration(seconds: 60)).then(
        (final _) async {
          final bool avail = await isNetworkAvailable();
          if (avail) {
            if (_isClickable) {
              _onVerifyCode();
            } else {
              setSnackbar(getTranslated(context, OTPWR)!);
            }
          } else {
            await buttonController!.reverse();
            setSnackbar(
              getTranslated(context, somethingMSg)!,
            );
          }
        },
      );
    }
  }

  verifyBtn() {
    return AppBtn(
      title: getTranslated(context, VERIFY_AND_PROCEED),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        _onFormSubmitted();
      },
    );
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

  Future<void> _onVerifyCode() async {
    setState(() {
      isCodeSent = true;
    });
    verificationCompleted(final AuthCredential phoneAuthCredential) {
      _firebaseAuth.signInWithCredential(phoneAuthCredential).then(
        (final UserCredential value) {
          if (value.user != "") {
            setSnackbar(getTranslated(context, OTPMSG)!);
            setPrefrence(MOBILE, mobile!);
            setPrefrence(COUNTRY_CODE, countrycode!);
            if (widget.title == FORGOT_PASS_TITLE) {
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (final context) => SetPass(
                    mobileNumber: mobile!,
                  ),
                ),
              );
            }
          } else {
            setSnackbar(OTPERROR);
          }
        },
      ).catchError(
        (final error) {
          setSnackbar(
            error.toString(),
          );
        },
      );
    }

    verificationFailed(final FirebaseAuthException authException) {
      setSnackbar(authException.message!);
      setState(() {
        isCodeSent = false;
      });
    }

    codeSent(final String verificationId, [final int? forceResendingToken]) async {
      _verificationId = verificationId;
      setState(() {
        _verificationId = verificationId;
      });
    }

    codeAutoRetrievalTimeout(final String verificationId) {
      _verificationId = verificationId;
      setState(() {
        _isClickable = true;
        _verificationId = verificationId;
      });
    }

    if (isFirebaseAuth) {
      await _firebaseAuth.verifyPhoneNumber(
          phoneNumber: "+${widget.countryCode}${widget.mobileNumber}",
          timeout: const Duration(seconds: 60),
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,);
    } else {
      print("Clicking on resend");
    }
  }

  Future<void> _onFormSubmitted() async {
    final String code = otp!.trim();
    if (code.length == 6) {
      _playAnimation();
      final AuthCredential authCredential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: code,);
      if (isFirebaseAuth) {
        _firebaseAuth.signInWithCredential(authCredential).then(
          (final UserCredential value) async {
            if (value.user != "") {
              await buttonController!.reverse();
              setSnackbar(getTranslated(context, OTPMSG)!);
              setPrefrence(MOBILE, mobile!);
              setPrefrence(COUNTRY_CODE, countrycode!);
              if (widget.title == SEND_OTP_TITLE) {
              } else if (widget.title == FORGOT_PASS_TITLE) {
                Future.delayed(const Duration(seconds: 2)).then((final _) {
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (final context) => SetPass(
                        mobileNumber: mobile!,
                      ),
                    ),
                  );
                });
              }
            } else {
              setSnackbar(
                getTranslated(context, OTPERROR)!,
              );
              await buttonController!.reverse();
            }
          },
        ).catchError(
          (final error) async {
            setSnackbar(error.toString());
            await buttonController!.reverse();
          },
        );
      } else {
        final Response response = await post(verifyOTP,
            body: {
              "mobile": mobile,
              "otp": otp,
            },
            headers: headers,);
        final getdata = json.decode(response.body);
        if (getdata['error']!) {
          setSnackbar(getdata['message'].toString());
          await buttonController!.reverse();
        } else {
          await buttonController!.reverse();
          setSnackbar(getTranslated(context, OTPMSG)!);
          setPrefrence(MOBILE, mobile!);
          setPrefrence(COUNTRY_CODE, countrycode!);
          Future.delayed(const Duration(seconds: 2)).then((final _) {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (final context) => SetPass(
                  mobileNumber: mobile!,
                ),
              ),
            );
          });
        }
      }
    } else {
      setSnackbar(
        getTranslated(context, ENTEROTP)!,
      );
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled catch (_) {}
  }

  getImage() {
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

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  monoVarifyText() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 30.0,
      ),
      child: Center(
        child: Text(
          getTranslated(context, MOBILE_NUMBER_VARIFICATION)!,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  otpText() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 50.0,
        left: 20.0,
        right: 20.0,
      ),
      child: Center(
        child: Text(
          getTranslated(context, SENT_VERIFY_CODE_TO_NO_LBL)!,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,
              ),
        ),
      ),
    );
  }

  mobText() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10.0,
        left: 20.0,
        right: 20.0,
        top: 10.0,
      ),
      child: Center(
        child: Text(
          "+$countrycode-$mobile",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,
              ),
        ),
      ),
    );
  }

  otpLayout() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 50.0,
        right: 50.0,
      ),
      child: Center(
        child: PinFieldAutoFill(
          decoration: UnderlineDecoration(
            textStyle: TextStyle(
                fontSize: 20, color: Theme.of(context).colorScheme.fontColor,),
            colorBuilder:
                FixedColorBuilder(Theme.of(context).colorScheme.lightWhite),
          ),
          currentCode: otp,
          onCodeChanged: (final String? code) {
            otp = code;
          },
          onCodeSubmitted: (final String code) {
            otp = code;
          },
        ),
      ),
    );
  }

  resendText() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 30.0,
        left: 25.0,
        right: 25.0,
        top: 10.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getTranslated(context, DIDNT_GET_THE_CODE)!,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal,
                ),
          ),
          InkWell(
            onTap: () async {
              await buttonController!.reverse();
              if (isFirebaseAuth) {
                checkNetworkOtp();
              } else {
                setState(() {
                  isCodeSent = true;
                });
                final Response response = await post(resendOtpApi,
                    body: {
                      "mobile": mobile,
                    },
                    headers: headers,);
                final getdata = json.decode(response.body);
                if (getdata['error']) {
                  setSnackbar(getdata['message']);
                  setState(() {
                    isCodeSent = false;
                  });
                } else {
                  setState(() {
                    isCodeSent = true;
                  });
                  setSnackbar(getTranslated(context, "otpsendSuccessfully")!);
                }
              }
            },
            child: Text(
              getTranslated(context, RESEND_OTP)!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  expandedBottomView() {
    return Expanded(
      flex: 6,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                monoVarifyText(),
                otpText(),
                mobText(),
                otpLayout(),
                verifyBtn(),
                resendText(),
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
      body: Container(
        color: Theme.of(context).colorScheme.lightWhite,
        padding: const EdgeInsets.only(
          bottom: 20.0,
        ),
        child: Column(
          children: <Widget>[
            getImage(),
            expandedBottomView(),
          ],
        ),
      ),
    );
  }
}

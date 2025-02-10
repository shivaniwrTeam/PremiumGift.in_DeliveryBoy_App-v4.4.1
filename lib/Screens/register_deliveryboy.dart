import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:deliveryboy/Helper/Color.dart';
import 'package:deliveryboy/Helper/translate.dart';
import 'package:deliveryboy/Helper/validator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';

class RegisterDeliveryBoyScreen extends StatefulWidget {
  const RegisterDeliveryBoyScreen({super.key});
  @override
  State<RegisterDeliveryBoyScreen> createState() =>
      _RegisterDeliveryBoyScreenState();
}

class _RegisterDeliveryBoyScreenState extends State<RegisterDeliveryBoyScreen> {
  final _formKey = GlobalKey<FormState>();
  File? licenseFrontImage;
  File? licenseBackImage;
  final ImagePicker imagePicker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  ValueNotifier<bool> inProgress = ValueNotifier(false);
  bool showPassword = false;
  bool showPasswordagain = false;
  void toggleShowPassword() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  void toggleShowPasswordagain() {
    setState(() {
      showPasswordagain = !showPasswordagain;
    });
  }

  getDecoration(final String hint, final IconData prefixIcon, {final IconButton? suffixIcon}) {
    return InputDecoration(
      prefixIcon: Icon(
        prefixIcon,
        color: Theme.of(context).colorScheme.fontColor,
        size: 17,
      ),
      hintText: hint,
      suffixIcon: suffixIcon,
      hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor.withOpacity(0.4),
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
        borderRadius: BorderRadius.circular(7.0),
      ),
    );
  }

  _subLogo() {
    return Center(
        child: SvgPicture.asset(
      'assets/images/homelogo.svg',
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.primarytheme,
        BlendMode.srcIn,
      ),
    ),);
  }

  @override
  void initState() {
    Future.delayed(
      Duration.zero,
      () {
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _subLogo(),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
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
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: <Widget>[
                        const SizedBox(
                          height: 10,
                        ),
                        Text("Registration".translate(context)),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          padding: EdgeInsets.zero,
                          child: TextFormField(
                            controller: _nameController,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.normal,
                            ),
                            decoration: getDecoration(
                                "name".translate(context), Icons.person,),
                            validator: (final value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: _mobileController,
                          decoration: getDecoration(
                              "number".translate(context), Icons.phone,),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.normal,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (final value) {
                            if (value?.contains(" ") ?? false) {
                              return "Please remove spaces";
                            }
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your mobile number';
                            }
                            return Validator.validatePhoneNumber(value);
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: getDecoration(
                              "email".translate(context), Icons.email,),
                          validator: (final value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your email';
                            }
                            return Validator.validateEmail(value);
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: _passwordController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: getDecoration(
                              "password".translate(context), Icons.key,
                              suffixIcon: IconButton(
                                onPressed: toggleShowPassword,
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  size: 17,
                                ),
                              ),),
                          obscureText: !showPassword,
                          validator: (final value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter a password';
                            }
                            return validatePass(value, context);
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: _confirmPasswordController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: getDecoration(
                              "password again".translate(context), Icons.key,
                              suffixIcon: IconButton(
                                onPressed: toggleShowPasswordagain,
                                icon: Icon(
                                  showPasswordagain
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  size: 17,
                                ),
                              ),),
                          obscureText: !showPasswordagain,
                          validator: (final value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return validatePass(value, context);
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: _addressController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: getDecoration(
                              "address".translate(context), Icons.location_on,),
                          validator: (final value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Text("Driving License".translate(context)),
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          children: [
                            Column(
                              children: [
                                Text("Front".translate(context)),
                                const SizedBox(
                                  height: 6,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final XFile? xFile = await imagePicker.pickImage(
                                        source: ImageSource.gallery,);
                                    if (xFile != null) {
                                      licenseFrontImage = File(xFile.path);
                                      setState(() {});
                                    }
                                  },
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius:
                                            BorderRadius.circular(10),),
                                    child: licenseFrontImage != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.file(
                                              licenseFrontImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(Icons.upload,
                                                color: Colors.grey,),),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 10.0,
                            ),
                            Column(
                              children: [
                                Text("Back".translate(context)),
                                const SizedBox(
                                  height: 6,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final XFile? xFile = await imagePicker.pickImage(
                                        source: ImageSource.gallery,);
                                    if (xFile != null) {
                                      licenseBackImage = File(xFile.path);
                                      setState(() {});
                                    }
                                  },
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius:
                                            BorderRadius.circular(10),),
                                    child: licenseBackImage != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.file(
                                              licenseBackImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(Icons.upload,
                                                color: Colors.grey,),),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        ValueListenableBuilder(
                            valueListenable: inProgress,
                            builder: (final context, final isProgress, final child) {
                              return MaterialButton(
                                  height: 45,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primarytheme,
                                  disabledColor: Theme.of(context)
                                      .colorScheme
                                      .primarytheme,
                                  disabledElevation: 0,
                                  onPressed: isProgress
                                      ? null
                                      : () async {
                                          if (_formKey.currentState
                                                  ?.validate() ??
                                              false) {
                                            try {
                                              final MultipartRequest request =
                                                  MultipartRequest("POST",
                                                      registerDeliveryBoy,);
                                              if (licenseFrontImage == null ||
                                                  licenseBackImage == null) {
                                                setSnackbar(context,
                                                    "Please upload image",);
                                                return;
                                              }
                                              inProgress.value = true;
                                              final MultipartFile
                                                  frontLicenseImgeMultipart =
                                                  await MultipartFile.fromPath(
                                                      "driving_license[]",
                                                      licenseFrontImage!.path,);
                                              final MultipartFile
                                                  backLicenseImgeMultipart =
                                                  await MultipartFile.fromPath(
                                                      "driving_license[]",
                                                      licenseBackImage!.path,);
                                              request.files.add(
                                                  frontLicenseImgeMultipart,);
                                              request.files.add(
                                                  backLicenseImgeMultipart,);
                                              request.fields.addAll({
                                                "name": _nameController.text,
                                                "mobile":
                                                    _mobileController.text,
                                                "email": _emailController.text,
                                                "password":
                                                    _passwordController.text,
                                                "confirm_password":
                                                    _confirmPasswordController
                                                        .text,
                                                "address":
                                                    _addressController.text,
                                              });
                                              final StreamedResponse response =
                                                  await request.send();
                                              final Uint8List responseData =
                                                  await response.stream
                                                      .toBytes();
                                              final String responseString =
                                                  String.fromCharCodes(
                                                      responseData,);
                                              final getdata =
                                                  json.decode(responseString);
                                              inProgress.value = false;
                                              if (!getdata['error']) {
                                                setSnackbar(context,
                                                    getdata['message'],);
                                                Navigator.pop(context);
                                              } else {
                                                throw getdata['message'];
                                              }
                                            } catch (e) {
                                              inProgress.value = false;
                                              setSnackbar(
                                                  context, e.toString(),);
                                            }
                                          }
                                        },
                                  child: isProgress
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Submit'.translate(context),
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .white,),
                                        ),);
                            },),
                        const SizedBox(height: 20.0),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: RichText(
                            text: TextSpan(
                              text:
                                  "Already have an account".translate(context),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontSize: 16.0,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Signin'.translate(context),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pop(context);
                                    },
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primarytheme,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

setSnackbar(final BuildContext context, final String msg) {
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

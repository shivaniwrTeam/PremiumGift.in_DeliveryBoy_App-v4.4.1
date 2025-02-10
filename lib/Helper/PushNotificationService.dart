import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'Constant.dart';
import 'Session.dart';
import 'String.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
FirebaseMessaging messaging = FirebaseMessaging.instance;

class PushNotificationService {
  final BuildContext? context;
  final Function? updateHome;
  PushNotificationService({this.context, this.updateHome});
  Future initialise() async {
    iOSPermission();
    messaging.getToken().then(
      (final token) async {
        CUR_USERID = await getPrefrence(ID);
        if (CUR_USERID != null && CUR_USERID != "") _registerToken(token);
      },
    );
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
    FirebaseMessaging.onMessage.listen(
      (final RemoteMessage message) {
        final data = message.notification!;
        final title = data.title.toString();
        final body = data.body.toString();
        final image = message.data['image'] ?? '';
        var type = '';
        type = message.data['type'] ?? '';
        if (image != "") {
          generateImageNotication(title, body, image, type);
        } else {
          generateSimpleNotication(title, body, type);
        }
      },
    );
  }

  Future<void> iOSPermission() async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _registerToken(final String? token) async {
    final parameter = {USER_ID: CUR_USERID, FCM_ID: token};
    await post(updateFcmApi, body: parameter, headers: headers).timeout(
      const Duration(seconds: timeOut),
    );
  }

  static Future<String> _downloadAndSaveImage(
    final String url,
    final String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static Future<void> generateImageNotication(
    final String title,
    final String msg,
    final String image,
    final String type,
  ) async {
    final largeIconPath = await _downloadAndSaveImage(image, 'largeIcon');
    final bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
    final bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: msg,
      htmlFormatSummaryText: true,
    );
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'big text channel id',
      'big text channel name',
      channelDescription: 'big text channel description',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation,
    );
    final platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, msg, platformChannelSpecifics, payload: type);
  }

  static Future<void> generateSimpleNotication(
    final String title,
    final String msg,
    final String type,
  ) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      msg,
      platformChannelSpecifics,
      payload: type,
    );
  }
}

Future<dynamic> myForgroundMessageHandler(final RemoteMessage message) async {
  return Future<void>.value();
}

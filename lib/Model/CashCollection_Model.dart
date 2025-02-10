import 'package:deliveryboy/Helper/String.dart';
import 'Order_Model.dart';

class CashColl_Model {
  String? id;
  String? name;
  String? mobile;
  String? orderId;
  String? cashReceived;
  String? type;
  String? amount;
  String? message;
  String? transDate;
  String? date;
  List<Order_Model>? orderDetails;
  CashColl_Model(
      {this.id,
      this.name,
      this.mobile,
      this.date,
      this.type,
      this.message,
      this.amount,
      this.cashReceived,
      this.orderId,
      this.transDate,
      this.orderDetails,});
  factory CashColl_Model.fromJson(final Map<String, dynamic> parsedJson) {
    List<Order_Model> orderDetails = [];
    final ordDet = parsedJson['order_details'] as List;
    if (ordDet.isEmpty) {
      orderDetails = [];
    } else {
      orderDetails = ordDet.map((final data) => Order_Model.fromJson(data)).toList();
    }
    return CashColl_Model(
        id: parsedJson[ID] ?? "",
        name: parsedJson[NAME] ?? "",
        mobile: parsedJson[MOBILE] ?? "",
        type: parsedJson[TYPE] ?? "",
        date: parsedJson[DATE_DEL] ?? "",
        amount: parsedJson[AMOUNT] ?? "",
        cashReceived: parsedJson[CASH_RECEIVED] ?? "",
        message: parsedJson[MESSAGE] ?? "",
        orderId: parsedJson[ORDERID] ?? "",
        transDate: parsedJson[TRANS_DATE] ?? "",
        orderDetails: orderDetails,);
  }
}

class OrderDetail_Model {
  String? id;
  String? userId;
  String? deliveryBoyId;
  String? addressId;
  String? mobile;
  String? total;
  String? deliveryCharge;
  String? isDeliveryChargeReturnable;
  String? walletBalance;
  String? promoCode;
  String? promoDiscount;
  String? discount;
  String? totalPayable;
  String? finalTotal;
  String? paymentMethod;
  String? latitude;
  String? longitude;
  String? address;
  String? deliveryTime;
  String? deliveryDate;
  String? activeStatus;
  String? dateAdded;
  String? otp;
  String? notes;
  String? username;
  String? countryCode;
  String? name;
  String? courierAgency;
  String? trackingId;
  String? url;
  String? isReturnable;
  String? isCancelable;
  String? isAlreadyReturned;
  String? isAlreadyCancelled;
  String? returnRequestSubmitted;
  String? totalTaxPercent;
  String? totalTaxAmount;
  List<String?>? listStatus = [];
  List<String?>? listDate = [];
  List<OrderItem>? itemList;
  List<Attachment>? attachList = [];
  OrderDetail_Model(
      {this.attachList,
      this.listDate,
      this.listStatus,
      this.id,
      this.userId,
      this.deliveryBoyId,
      this.addressId,
      this.mobile,
      this.total,
      this.deliveryCharge,
      this.isDeliveryChargeReturnable,
      this.walletBalance,
      this.promoCode,
      this.promoDiscount,
      this.discount,
      this.totalPayable,
      this.finalTotal,
      this.paymentMethod,
      this.latitude,
      this.longitude,
      this.address,
      this.deliveryTime,
      this.deliveryDate,
      this.activeStatus,
      this.dateAdded,
      this.otp,
      this.notes,
      this.username,
      this.countryCode,
      this.name,
      this.courierAgency,
      this.trackingId,
      this.url,
      this.isReturnable,
      this.isCancelable,
      this.isAlreadyReturned,
      this.isAlreadyCancelled,
      this.returnRequestSubmitted,
      this.totalTaxPercent,
      this.totalTaxAmount,
      this.itemList,});
  static OrderDetail_Model orderDetail_ModelFromJson(
      final Map<String, dynamic> json,) {
    final List<String?> lStatus = [];
    final List<String?> lDate = [];
    final allStatus = json[STATUS];
    for (final curStatus in allStatus) {
      lStatus.add(curStatus[0]);
      lDate.add(curStatus[1]);
    }
    List<Attachment> attachmentList = [];
    final attachments = json[ATTACHMENTS] as List;
    if (attachments.isEmpty) {
      attachmentList = [];
    } else {
      attachmentList =
          attachments.map((final data) => Attachment.fromJson(data)).toList();
    }
    List<OrderItem> itemList = [];
    var order = json[ORDER_ITEMS] as List?;
    if (order == "" || order!.isEmpty) {
      order = [];
    } else {
      itemList = order.map((final data) => OrderItem.fromJson(data)).toList();
    }
    return OrderDetail_Model(
        id: json[ID],
        userId: json[USER_ID],
        deliveryBoyId: json[DELIVERY_BOY_ID],
        mobile: json[MOBILE],
        total: json[TOTAL],
        deliveryCharge: json[DELIVERY_CHARGE],
        attachList: attachmentList,
        listStatus: lStatus,
        listDate: lDate,
        itemList: itemList,
        paymentMethod: json[PAYMENT_METHOD],
        isCancelable: json[ISCANCLEABLE],
        isReturnable: json[ISRETURNABLE],
        dateAdded: json[DATE_ADDED],);
  }
}

class Attachment {
  String? id;
  String? attachment;
  String? bankTranStatus;
  Attachment({this.id, this.attachment, this.bankTranStatus});
  factory Attachment.fromJson(final Map<String, dynamic> json) {
    return Attachment(
        id: json[ID],
        attachment: json[ATTACHMENT],
        bankTranStatus: json[BANK_STATUS],);
  }
}

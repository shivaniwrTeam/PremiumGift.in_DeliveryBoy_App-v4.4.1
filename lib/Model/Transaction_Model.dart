import 'package:deliveryboy/Helper/Constant.dart';
import 'package:deliveryboy/Helper/String.dart';
import 'package:intl/intl.dart';

class TransactionModel {
  String? id;
  String? amt;
  String? status;
  String? msg;
  String? date;
  String? opnBal;
  String? clsBal;
  TransactionModel(
      {this.id,
      this.amt,
      this.status,
      this.msg,
      this.date,
      this.opnBal,
      this.clsBal,});
  factory TransactionModel.fromJson(final Map<String, dynamic> json) {
    String date = json[DATE];
    date = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
    return TransactionModel(
        id: json[ID] ?? "",
        amt: json[AMT] ?? "",
        status: json[STATUS] ?? "",
        msg: json[MESSAGE] ?? "",
        opnBal: json[OPNBAL] ?? "",
        clsBal: json[CLSBAL] ?? "",
        date: date,);
  }
  factory TransactionModel.fromReqJson(final Map<String, dynamic> json) {
    String date = json[DATE];
    date = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
    String? st = json[STATUS];
    if (st == "0") {
      st = PENDING;
    } else if (st == "1") {
      st = ACCEPTED;
    } else if (st == "2") {
      st = REJECTED;
    }
    return TransactionModel(
        id: json[ID] ?? "",
        amt: json["amount_requested"] ?? "",
        status: st ?? "",
        msg: json[REMARK] ?? "",
        date: date,);
  }
}



import 'package:decimal/decimal.dart';

class DurationName {
  const DurationName(this.name, this.duration);
  final String name;
  final Duration duration;
}

class UzCardSms {
  UzCardSms(this.id, this.msg, this.smsDateTimeFormatted, this.receiptDateTime,
      this.summa, this.balance, this.income, this.smsDateTime);

  final int id;
  final String msg;
  final String smsDateTimeFormatted;
  final String receiptDateTime;
  final Decimal summa;
  final Decimal balance;
  final bool income;
  final DateTime smsDateTime;
  late Decimal lostSumma;
}

class UzCardSmsView {
  const UzCardSmsView(this.body, this.smsDateTime, this.receiptDateTime,
      this.summa, this.balance, this.income, this.lostSumma);

  final String body;
  final String smsDateTime;
  final String receiptDateTime;
  final String summa;
  final String balance;
  final bool income;
  final String? lostSumma;
}



import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

class DurationName {
  const DurationName(this.name, this.duration);
  final String name;
  final Duration duration;
}

enum CardType {
  UZCARD,
  HUMO
}

class CardID {
  final CardType type;
  final String number;

  CardID(this.type, this.number);

  @override
  String toString() {
    return '$type-$number';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardID &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          number == other.number;

  @override
  int get hashCode => type.hashCode ^ number.hashCode;
}

class BankCardSms {
  BankCardSms(this.id, this.msg, this.smsDateTimeFormatted, this.receiptDateTime,
      this.summa, this.balance, this.income, this.smsDateTime, this.iconData);

  final int id;
  final String msg;
  final String smsDateTimeFormatted;
  final String receiptDateTime;
  final Decimal summa;
  final Decimal balance;
  final bool income;
  final DateTime smsDateTime;
  late Decimal lostSumma;
  final IconData iconData;
}

class BankCardSmsView {
  const BankCardSmsView(this.body, this.smsDateTime, this.receiptDateTime,
      this.summa, this.balance, this.income, this.lostSumma, this.iconData);

  final String body;
  final String smsDateTime;
  final String receiptDateTime;
  final String summa;
  final String balance;
  final bool income;
  final String? lostSumma;
  final IconData iconData;
}

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';

import 'dto.dart';

class HUMO {
  static final RegExp expParse = RegExp(
      r"HUMOCARD\s+\*([0-9]{4}):\s+([a-z ]+)\s+([0-9]+\.[0-9]{2})\s+UZS; (.+);\s+([0-9]{2}\-[0-9]{2}\-[0-9]{2} [0-9]{2}:[0-9]{2});\s+Dostupno:\s+([0-9]+\.[0-9]{2})\s+UZS");

  static final DateFormat formatter = DateFormat('dd.MM.yyyy HH:mm:ss');
  static final DateFormat receiptFormatter = DateFormat('yy-MM-dd HH:mm');

  static Future<void> read(SmsQuery query, DateTime limit,
      Map<CardID, List<BankCardSms>> map) async {
    bool dateLimitReached = false;
    var index = 0;
    const pageSize = 10;
    while (!dateLimitReached) {
      var messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        address: "11313",
        start: index,
        count: pageSize,
      );
      index += pageSize;
      for (var m in messages) {
        if (m.date?.isBefore(limit) == true) {
          dateLimitReached = true;
          break;
        }
        if (m.body == null) {
          continue;
        }
        Iterable<RegExpMatch> matches = expParse.allMatches(m.body!);
        if (matches.isEmpty) {
          continue;
        }
        var card = matches.first.group(1);
        var cardID = CardID(CardType.HUMO, card!);
        var list = map.putIfAbsent(cardID, () => []);
        var op = matches.first.group(2);
        var summa = Decimal.fromJson(matches.first.group(3)!);
        var dst = matches.first.group(4);
        var receiptDate = receiptFormatter.parse(matches.first.group(5)!);
        var balance = Decimal.fromJson(matches.first.group(6)!);

        bool income = true;
        income = op == "popolnenie";
        var msg = "$op: $dst";

        IconData iconData = Icons.warning;
        if (msg.startsWith("popolnenie")) {
          iconData = Icons.savings;
        } else if (msg.startsWith("snjatie nalichnih")) {
          iconData = Icons.payments;
          // } else if (msg.startsWith("Perevod na kartu:")) {
          //   iconData = Icons.add_card;
          // } else if (msg.startsWith("Debit online:")) {
          //   iconData = Icons.shopping_cart_checkout;
          // } else if (msg.startsWith("Spisanie c karty:")) {
          //   iconData = Icons.credit_card;
        } else if (msg.startsWith("oplata")) {
          iconData = Icons.shopping_cart;
          // } else if (msg.startsWith("Platezh:")) {
          //   iconData = Icons.account_balance;
        } else if (msg.startsWith("operacija")) {
          iconData = Icons.credit_card;
          // } else if (msg.startsWith("Platezh:")) {
          //   iconData = Icons.account_balance;
        }

        var sms = BankCardSms(
            m.id!,
            msg,
            formatter.format(m.date!),
            formatter.format(receiptDate!),
            summa,
            balance,
            income,
            m.date!,
            iconData);

        list.add(sms);
      }
    }
    return;
  }
}

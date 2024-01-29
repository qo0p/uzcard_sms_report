import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';

import 'dto.dart';

class UZCARD {
  static final RegExp expCard = RegExp(r"karta \*\*\*([0-9]{4})");
  static final RegExp expSumma = RegExp(r"summa:([0-9]+\.[0-9]{2}) UZS");
  static final RegExp expBalans = RegExp(r"balans:([0-9]+\.[0-9]{2}) UZS");
  static final RegExp expDate =
      RegExp(r"[0-9]{2}\.[0-9]{2}\.[0-9]{2} [0-9]{2}:[0-9]{2}");
  static final RegExp exTail = RegExp(
      r"(\s|,)[0-9]{2}\.[0-9]{2}\.[0-9]{2} [0-9]{2}:[0-9]{2}(\s|,)karta \*\*\*");

  static final DateFormat formatter = DateFormat('dd.MM.yyyy HH:mm:ss');

  static Future<void> read(SmsQuery query, DateTime limit,
      Map<CardID, List<BankCardSms>> map) async {
    bool dateLimitReached = false;
    var index = 0;
    const pageSize = 10;
    while (!dateLimitReached) {
      var messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        address: "UZCARD",
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
        Iterable<RegExpMatch> matches = expCard.allMatches(m.body!);
        if (matches.isEmpty) {
          continue;
        }
        var card = matches.first.group(1);
        var cardID = CardID(CardType.UZCARD, card!);
        var list = map.putIfAbsent(cardID, () => []);

        matches = expSumma.allMatches(m.body!);
        if (matches.isEmpty) {
          continue;
        }
        var summa = Decimal.fromJson(matches.first.group(1)!);

        matches = expBalans.allMatches(m.body!);
        if (matches.isEmpty) {
          continue;
        }
        var balance = Decimal.fromJson(matches.first.group(1)!);

        matches = expDate.allMatches(m.body!);
        if (matches.isEmpty) {
          continue;
        }
        var receiptDate = matches.first.group(0);

        bool income = true;
        income = m.body!.startsWith("Popolnenie scheta:") ||
            m.body!.startsWith("Perevod na kartu:");
        var msg = m.body!;
        matches = exTail.allMatches(msg);
        if (matches.isNotEmpty) {
          msg = msg.substring(0, matches.first.start);
        }

        IconData iconData = Icons.warning;
        if (msg.startsWith("Popolnenie scheta:")) {
          iconData = Icons.savings;
        } else if (msg.startsWith("Vidacha nalichnykh v bankomate:")) {
          iconData = Icons.payments;
        } else if (msg.startsWith("Perevod na kartu:")) {
          iconData = Icons.add_card;
        } else if (msg.startsWith("Debit online:")) {
          iconData = Icons.shopping_cart_checkout;
        } else if (msg.startsWith("Spisanie c karty:")) {
          iconData = Icons.credit_card;
        } else if (msg.startsWith("Pokupka:")) {
          iconData = Icons.shopping_cart;
        } else if (msg.startsWith("Platezh:")) {
          iconData = Icons.account_balance;
        } else if (msg.startsWith("E-Com oplata:")) {
          iconData = Icons.shopping_basket_rounded;
        }

        var sms = BankCardSms(
            m.id!,
            msg,
            formatter.format(m.date!),
            receiptDate!,
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

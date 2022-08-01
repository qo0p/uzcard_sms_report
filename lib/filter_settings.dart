import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'report.dart';

import 'dto.dart';

class FilterSettingsPage extends StatefulWidget {
  const FilterSettingsPage({super.key, required this.title});

  final String title;

  @override
  State<StatefulWidget> createState() => _FilterSettingsState();
}

class _FilterSettingsState extends State<FilterSettingsPage> {
  RegExp expCard = RegExp(r"karta \*\*\*([0-9]{4})");
  RegExp expSumma = RegExp(r"summa:([0-9]+\.[0-9]{2}) UZS");
  RegExp expBalans = RegExp(r"balans:([0-9]+\.[0-9]{2}) UZS");
  RegExp expDate = RegExp(r"[0-9]{2}\.[0-9]{2}\.[0-9]{2} [0-9]{2}:[0-9]{2}");
  RegExp exTail = RegExp(
      r"(\s|,)[0-9]{2}\.[0-9]{2}\.[0-9]{2} [0-9]{2}:[0-9]{2}(\s|,)karta \*\*\*");

  var formatter = DateFormat('dd.MM.yyyy HH:mm:ss');
  var numberFormat = NumberFormat(",###,###,###,###,###.00", "en_US");
  DurationName selectedDuration =
      const DurationName("За последний месяц", Duration(days: 30));
  List<DurationName> durationList = [
    const DurationName("За последний год", Duration(days: 365)),
    const DurationName("За последние 6 месяцев", Duration(days: 182)),
    const DurationName("За последние 3 месяца", Duration(days: 90)),
    const DurationName("За последний месяц", Duration(days: 30)),
    const DurationName("За последнюю неделю", Duration(days: 7)),
  ];

  final _durationFormKey = GlobalKey<FormState>();

  final SmsQuery _query = SmsQuery();

  Future<Map<String, List<UzCardSmsView>>> _readMessages() async {
    var now = DateTime.now();
    var limit = now.subtract(selectedDuration.duration);
    final Map<String, List<UzCardSms>> map = {};
    final Map<String, List<UzCardSmsView>> view = {};
    bool dateLimitReached = false;
    var index = 0;
    const pageSize = 10;
    while (!dateLimitReached) {
      var messages = await _query.querySms(
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

        var list = map.putIfAbsent(card!, () => []);

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

        var sms = UzCardSms(m.id!, m.body!, formatter.format(m.date!),
            receiptDate!, summa, balance, income, m.date!);

        list.add(sms);
      }
    }

    for (List<UzCardSms> list in map.values) {
      late Decimal prevSumma;
      Decimal? lastBalance;
      late UzCardSms prevSms;

      for (UzCardSms sms in list) {
        sms.lostSumma = Decimal.zero;
        if (lastBalance == null) {
          lastBalance = sms.balance;
          prevSumma = sms.summa;
          prevSms = sms;
          continue;
        }
        Decimal currBalance = sms.balance;
        Decimal currSumma = sms.summa;
        Decimal summa;
        if (sms.income) {
          summa = lastBalance - currBalance;
        } else {
          summa = currBalance - lastBalance;
        }
        Decimal lostSumma = prevSumma.abs() - summa.abs();
        prevSms.lostSumma = lostSumma;

        lastBalance = currBalance;
        prevSumma = currSumma;
        prevSms = sms;
      }
    }
    for (String key in map.keys) {
      List<UzCardSms> list = map[key]!;
      for (UzCardSms sms in list) {
        var vl = view.putIfAbsent(key, () => []);

        var msg = sms.msg;
        var matches = exTail.allMatches(sms.msg);
        if (!matches.isEmpty) {
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
        }

        vl.add(UzCardSmsView(
            msg,
            sms.smsDateTimeFormatted,
            sms.receiptDateTime,
            formatDecimal(sms.summa.toStringAsFixed(2)),
            formatDecimal(sms.balance.toStringAsFixed(2)),
            sms.income,
            (sms.lostSumma.compareTo(Decimal.zero) == 0
                ? null
                : formatDecimal(sms.lostSumma.toStringAsFixed(2))),
            iconData));
      }
    }
    return view;
  }

  String formatDecimal(String s) {
    List<String> sb = [];
    bool start = false;
    int tho = 0;
    for (int i = 0; i < s.length; i++) {
      String c = s[s.length - i - 1];
      if (start) {
        tho++;
        if (tho > 3) {
          sb.insert(0, " ");
          tho = 1;
        }
      }
      if (c == '.') {
        start = true;
      }
      sb.insert(0, c);
    }
    return sb.join("");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
          key: _durationFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(50.0),
                child: DropdownButtonFormField(
                    decoration: const InputDecoration(
                      labelText: "Считывать SMS",
                    ),
                    validator: (value) => value == null ? "Выберите" : null,
                    value: selectedDuration,
                    onChanged: (DurationName? newValue) {
                      setState(() {
                        selectedDuration = newValue!;
                      });
                    },
                    items: durationList.map((DurationName dn) {
                      return DropdownMenuItem<DurationName>(
                        value: dn,
                        child: Text(
                          dn.name,
                        ),
                      );
                    }).toList()),
              ),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          //valid flow
          if (_durationFormKey.currentState!.validate()) {
            var permission = await Permission.sms.status;
            if (permission.isGranted) {
              openReportPage(context);
            } else {
              var permission = await Permission.sms.request();
              if (permission.isGranted) {
                openReportPage(context);
              }
            }
          }
        },
        tooltip: "Поиск",
        child: const Icon(Icons.search),
      ),
    );
  }

  showAlertDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
              margin: const EdgeInsets.only(left: 5),
              child: const Text("Загрузка")),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void openReportPage(var context) async {
    showAlertDialog(context);
    final messages = await _readMessages();
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ReportPage(title: 'Отчет', messages: messages);
    }));
  }
}

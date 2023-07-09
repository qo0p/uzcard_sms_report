import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uzcard_sms_report/uzcard.dart';
import 'humo.dart';
import 'report.dart';

import 'dto.dart';

class FilterSettingsPage extends StatefulWidget {
  const FilterSettingsPage({super.key, required this.title});

  final String title;

  @override
  State<StatefulWidget> createState() => _FilterSettingsState();
}

class _FilterSettingsState extends State<FilterSettingsPage> {
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

  Future<Map<CardID, List<BankCardSmsView>>> _readMessages() async {
    final Map<CardID, List<BankCardSmsView>> view = {};
    var now = DateTime.now();
    var limit = now.subtract(selectedDuration.duration);

    Map<CardID, List<BankCardSms>> map = {};
    await UZCARD.read(_query, limit, map);
    await HUMO.read(_query, limit, map);

    for (List<BankCardSms> list in map.values) {
      late Decimal prevSumma;
      Decimal? lastBalance;
      late BankCardSms prevSms;

      for (BankCardSms sms in list) {
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
    for (CardID key in map.keys) {
      List<BankCardSms> list = map[key]!;
      for (BankCardSms sms in list) {
        var vl = view.putIfAbsent(key, () => []);

        var msg = sms.msg;

        vl.add(BankCardSmsView(
            msg,
            sms.smsDateTimeFormatted,
            sms.receiptDateTime,
            formatDecimal(sms.summa.toStringAsFixed(2)),
            formatDecimal(sms.balance.toStringAsFixed(2)),
            sms.income,
            (sms.lostSumma.compareTo(Decimal.zero) == 0
                ? null
                : formatDecimal(sms.lostSumma.toStringAsFixed(2))),
            sms.iconData));
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

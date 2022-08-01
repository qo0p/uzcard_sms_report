import 'dart:ui';

import 'package:flutter/material.dart';

import 'dto.dart';

class SMSItem extends StatelessWidget {
  const SMSItem({super.key, required this.itemData});
  final UzCardSmsView itemData;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: (itemData.income)
          ? Icon(
              itemData.iconData,
              color: Color.fromARGB(255, 0, 128, 0),
            )
          : Icon(itemData.iconData),
      title: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Дата чека: ${itemData.receiptDateTime}",
                style: TextStyle(fontSize: 12)),
            Text("Дата SMS: ${itemData.smsDateTime}",
                style: TextStyle(fontSize: 12)),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (itemData.income)
                Text(
                  "Сумма: ${itemData.summa}",
                  style: TextStyle(color: Color.fromARGB(255, 0, 128, 0)),
                )
              else
                Text("Сумма: ${itemData.summa}"),
              if (itemData.income)
                Text("Баланс: ${itemData.balance}",
                    style: TextStyle(color: Color.fromARGB(255, 0, 128, 0)))
              else
                Text("Баланс: ${itemData.balance}"),
            ],
          ),
        ],
      ),
      subtitle: Column(children: [
        Text(itemData.body, style: TextStyle(fontSize: 12)),
        Text(
          "Потерянная сумма: ${itemData.lostSumma}",
          style: TextStyle(
              color: (itemData.lostSumma != null)
                  ? Color.fromARGB(255, 255, 0, 0)
                  : Color.fromARGB(0, 255, 0, 0),
              fontSize: 12),
        )
      ]),
    );
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.title, required this.messages});

  final String title;
  final Map<String, List<UzCardSmsView>> messages;

  @override
  State<StatefulWidget> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int tabIndex = 0;

  @override
  void initState() {
    _tabController = TabController(
      initialIndex: 0,
      length: widget.messages.length,
      vsync: this,
    );
    _tabController!.addListener(() {
      // When the tab controller's value is updated, make sure to update the
      // tab index value, which is state restorable.
      setState(() {
        tabIndex = _tabController!.index;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: widget.messages.length > 6 ? true : false,
          tabs: [
            for (final tab in widget.messages.keys) Tab(text: tab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final tab in widget.messages.keys)
            Scrollbar(
              child: ListView(
                children: [
                  for (var it in widget.messages[tab]!)
                    SMSItem(
                      itemData: it,
                    )
                ],
              ),
            ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   tooltip: "",
      //   child: const Icon(Icons.search),
      // ),
    );
  }
}

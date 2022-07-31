

import 'dart:ui';

import 'package:flutter/material.dart';

import 'dto.dart';

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
                    ListTile(
                      // leading: const ExcludeSemantics(
                      //   child: Icon(Icons.warning),
                      // ),
                      title: Column(
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Дата чека: ${it.receiptDateTime}",
                                    style: TextStyle(fontSize: 12)),
                                Text("Дата SMS: ${it.smsDateTime}",
                                    style: TextStyle(fontSize: 12)),
                              ]),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (it.income)
                                Text(
                                  "Сумма: ${it.summa}",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 128, 0)),
                                )
                              else
                                Text("Сумма: ${it.summa}"),
                              if (it.income)
                                Text(
                                    "Баланс: ${it.balance}",
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 0, 128, 0)))
                              else
                                Text("Баланс: ${it.balance}"),
                            ],
                          ),
                        ],
                      ),
                      subtitle: Column(children: [
                        Text(it.body, style: TextStyle(fontSize: 12)),
                        if (it.lostSumma != null)
                          Text(
                            "Потерянная сумма: ${it.lostSumma}",
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 0, 0)),
                          )
                        else
                          Text("", style: TextStyle(fontSize: 1))
                      ]),
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

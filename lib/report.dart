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
              color: const Color.fromARGB(255, 0, 128, 0),
            )
          : Icon(itemData.iconData),
      title: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Дата чека: ${itemData.receiptDateTime}",
                style: const TextStyle(fontSize: 12)),
            Text("Дата SMS: ${itemData.smsDateTime}",
                style: const TextStyle(fontSize: 12)),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (itemData.income)
                Text(
                  "Сумма: ${itemData.summa}",
                  style: const TextStyle(color: Color.fromARGB(255, 0, 128, 0)),
                )
              else
                Text("Сумма: ${itemData.summa}"),
              if (itemData.income)
                Text("Баланс: ${itemData.balance}",
                    style: const TextStyle(color: Color.fromARGB(255, 0, 128, 0)))
              else
                Text("Баланс: ${itemData.balance}"),
            ],
          ),
        ],
      ),
      subtitle: Column(children: [
        Text(itemData.body, style: const TextStyle(fontSize: 12)),
        Text(
          "Потерянная сумма: ${itemData.lostSumma}",
          style: TextStyle(
              color: (itemData.lostSumma != null)
                  ? const Color.fromARGB(255, 255, 0, 0)
                  : const Color.fromARGB(0, 255, 0, 0),
              fontSize: 12),
        )
      ]),
    );
  }
}

class SMSList extends StatefulWidget {
  final List<UzCardSmsView> list;
  const SMSList({super.key, required this.list});

  @override
  State<StatefulWidget> createState() => _SMSList();
}

class _SMSList extends State<SMSList>
    with AutomaticKeepAliveClientMixin<SMSList> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scrollbar(
      child: ListView(
        children: [
          for (var it in widget.list)
            SMSItem(
              itemData: it,
            )
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
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
            SMSList(list: widget.messages[tab]!)
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

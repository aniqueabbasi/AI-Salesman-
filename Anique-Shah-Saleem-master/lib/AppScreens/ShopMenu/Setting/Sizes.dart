import 'package:flutter/material.dart';

class SizesScreen extends StatefulWidget {
  const SizesScreen({super.key});

  @override
  State<SizesScreen> createState() => _SizesScreenState();
}

class _SizesScreenState extends State<SizesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Size Chart"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(  // Make the content scrollable for smaller screens
          child: Column(
            children: [
              // Shirt Size Table
              const Text(
                "Shirt Size Chart",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Table(
                border: TableBorder.all(),
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FixedColumnWidth(60),
                  2: FixedColumnWidth(60),
                  3: FixedColumnWidth(60),
                  4: FixedColumnWidth(60),
                },
                children: const [
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Shirt Size",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "S",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "M",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "L",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "XL",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Chest (inches)"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("34-36"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("38-40"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("42-44"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("46-48"),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Waist (inches)"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("28-30"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("32-34"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("36-38"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("40-42"),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Jean Size Table
              const Text(
                "Jean Size Chart",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Table(
                border: TableBorder.all(),
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FixedColumnWidth(60),
                  2: FixedColumnWidth(60),
                  3: FixedColumnWidth(60),
                  4: FixedColumnWidth(60),
                  5: FixedColumnWidth(60),
                },
                children: const [
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Jean Size",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "30",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "32",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "34",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "38",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Waist (inches)"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("30"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("32"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("34"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("36"),
                      ),

                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Hip (inches)"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("36"),
                      ),

                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("40"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("42"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("44"),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

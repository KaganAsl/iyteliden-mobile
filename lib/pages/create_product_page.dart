import 'package:flutter/material.dart';

class CreateProductPage extends StatefulWidget {

  const CreateProductPage({super.key});

  @override
  State<StatefulWidget> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Product"),
      ),
      body: Text("Create Product"),
    );
  }
}
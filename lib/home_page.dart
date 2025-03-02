import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일본 장인 스타일 앱'),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          '앱의 메인 화면입니다.\n온보딩이 완료되었습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:habp/features/onboarding/presentation/widgets/page_content1_alert.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/underline_button.dart';
import '../widgets/wave_background.dart';

class PageContent1 extends StatelessWidget {
  const PageContent1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Stack(children: [
          const WaveBackground(
            primaryColor: AppColors.grey,
            secondaryColor: AppColors.primary, // 민트빛 블렌딩
          ),
          SafeArea(
            child: Column(
              children: [
                // 상단 텍스트 영역 (화면의 절반)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '고정소득의',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 60,
                            fontFamily: 'hakFont', // 실제 폰트 이름으로 변경 필요
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            UnderlineButton(
                              text: '종류와 액수',
                              width: 200,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const PageContent1Alert(),
                                );
                              },
                            ),
                            const Text(
                              '를',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 60,
                                fontFamily: 'hakFont',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '입력해주세요',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 60,
                            fontFamily: 'hakFont',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 300),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

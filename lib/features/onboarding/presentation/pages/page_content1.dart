import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:habp/features/onboarding/presentation/widgets/page_content1_alert.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/underline_button.dart';
import '../widgets/wave_background.dart';

class PageContent1 extends StatelessWidget {
  const PageContent1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0, bottom: 80.0), // Leave space for indicators and buttons
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // GIF 영역 (GIF area)
                  Flexible(
                    child: GifView.asset(
                      'assets/images/money-1156.gif',
                      height: size.height * 0.25, // Responsive height
                      width: size.width * 0.7, // Responsive width
                      fit: BoxFit.contain,
                    ),
                  ),
                  // 상단 텍스트 영역 (Text section)
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '고정소득의',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: size.width * 0.12, // Responsive font size
                              fontFamily: 'Noto Sans JP',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            UnderlineButton(
                              text: '종류와 액수',
                              width: size.width * 0.43, // Responsive width
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const PageContent1Alert(),
                                );
                              },
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '를',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: size.width * 0.12, // Responsive font size
                                  fontFamily: 'Noto Sans JP',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '입력해주세요',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: size.width * 0.12, // Responsive font size
                              fontFamily: 'Noto Sans JP',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
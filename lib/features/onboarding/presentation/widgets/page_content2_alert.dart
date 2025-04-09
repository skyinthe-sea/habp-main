import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/expense_entry.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/underline_button.dart';
import '../widgets/select_underline_button.dart';
import '../controllers/expense_controller.dart';
import '../../domain/services/onboarding_service.dart';

class PageContent2Alert extends StatefulWidget {
  const PageContent2Alert({Key? key}) : super(key: key);

  @override
  State<PageContent2Alert> createState() => _PageContent1AlertState();
}

class _PageContent1AlertState extends State<PageContent2Alert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final ExpenseController _expenseController = ExpenseController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final OnboardingService _onboardingService = OnboardingService();

  final controller = Get.find<OnboardingController>();

  bool _isEditing = false;
  bool _isUpdating = false;
  ExpenseEntry? _selectedEntry;
  bool _isSaving = false;

  // 선택한 값들 저장
  String _selectedIncomeType = '통신비';
  String _selectedFrequency = '매월';
  int _selectedDay = 5;

  // 드롭다운 옵션들
  final List<String> _incomeTypes = ['통신비', '보험', '월세', '기타'];
  final List<String> _frequencies = ['매월', '매주', '매일'];
  final List<int> _days = List.generate(31, (index) => index + 1);
  final List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final List<String> _customIncomeTypes = [];

  static const Color primaryColor = Color(0xFFE495C0);

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 설정 (지속 시간 0.5초)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 풍선 터지는 효과를 위한 커스텀 애니메이션 곡선
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // 저장된 사용자 정의 지출 유형 로드
    _loadCustomIncomeTypes();

    // 위젯이 빌드된 후 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  // 사용자 정의 지출 유형 로드
  void _loadCustomIncomeTypes() {
    final customTypes = _expenseController.getCustomIncomeTypes();
    if (customTypes.isNotEmpty) {
      setState(() {
        _customIncomeTypes.clear();
        _customIncomeTypes.addAll(customTypes);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();

    // 사용자 정의 유형 저장
    if (_customIncomeTypes.isNotEmpty) {
      _expenseController.saveCustomIncomeTypes(_customIncomeTypes);
    }

    super.dispose();
  }

  // 입력값 형식화 - 1000원 단위 콤마 추가
  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // 편집 모드로 전환
  void _startEditing([ExpenseEntry? entry]) {
    setState(() {
      _isEditing = true;
      _isUpdating = entry != null;
      _selectedEntry = entry;

      if (entry != null) {
        // 기존 항목 값으로 설정
        _selectedIncomeType = entry.incomeType;
        _selectedFrequency = entry.frequency;
        _selectedDay = entry.day;

        // 콤마 제거 후 설정
        _textController.text = entry.amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
        );
      } else {
        _textController.clear();
      }
    });

    // 포커스 및 키보드 표시 - 딜레이를 더 주고 직접 키보드 표시
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(_focusNode);
      // 강제로 키보드 표시
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  // 편집 모드 종료
  void _stopEditing() {
    setState(() {
      _isEditing = false;
      _isUpdating = false;
      _selectedEntry = null;
      _textController.clear();
    });
    _focusNode.unfocus();
  }

  // 금액 추가
  void _addExpense() async {
    if (_textController.text.isEmpty) return;

    final amountText = _textController.text.replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (amount != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final newEntry = ExpenseEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          incomeType: _selectedIncomeType,
          frequency: _selectedFrequency,
          day: _selectedDay,
          createdAt: DateTime.now(),
        );

        // 메모리에 저장
        _expenseController.addEntry(newEntry);

        // DB에 저장
        await _onboardingService.saveIncomeInfo(
          incomeType: _selectedIncomeType,
          frequency: _selectedFrequency,
          day: _selectedDay,
          amount: amount.toDouble() * -1, // 데이터베이스에는 double로 저장
          type: ExpenseCategoryType.EXPENSE,
        );

        _stopEditing();
        setState(() {});
      } catch (e) {
        debugPrint('지출 정보 저장 중 오류: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '저장에 실패했습니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // 금액 수정
  void _updateExpense() async {
    if (_selectedEntry == null || _textController.text.isEmpty) return;

    final amountText = _textController.text.replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (amount != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final updatedEntry = ExpenseEntry(
          id: _selectedEntry!.id,
          amount: amount,
          incomeType: _selectedIncomeType,
          frequency: _selectedFrequency,
          day: _selectedDay,
          createdAt: _selectedEntry!.createdAt,
          updatedAt: DateTime.now(),
        );

        // 메모리에 업데이트
        _expenseController.updateEntry(updatedEntry);

        // DB에는 현재 수정 기능을 구현하지 않음 (필요 시 구현)
        // Transaction 테이블의 항목을 수정하기 위한 서비스 메소드 추가 필요

        _stopEditing();
        setState(() {});
      } catch (e) {
        debugPrint('지출 정보 수정 중 오류: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '수정에 실패했습니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // 금액 삭제
  void _confirmDelete() {
    if (_selectedEntry == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _isSaving = true;
              });

              try {
                // 메모리에서 삭제
                _expenseController.deleteEntry(_selectedEntry!.id);

                // DB에는 현재 삭제 기능을 구현하지 않음 (필요 시 구현)
                // Transaction 테이블의 항목을 삭제하기 위한 서비스 메소드 추가 필요

                _stopEditing();
                setState(() {});
              } catch (e) {
                debugPrint('지출 정보 삭제 중 오류: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '삭제에 실패했습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() {
                  _isSaving = false;
                });
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 온보딩 완료 및 데이터베이스 정보 출력
  void _showDatabaseInfo() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _onboardingService.printOnboardingData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '데이터베이스 정보가 콘솔에 출력되었습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('데이터베이스 정보 출력 중 오류: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 셀렉트 메뉴 표시
  void _showSelectMenu<T>({
    required List<T> items,
    required String Function(T) itemText,
    required Function(T) onSelected,
    required BuildContext buttonContext,
  }) {
    // 버튼의 위치 정보 획득
    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;

    // 버튼 바로 아래에 메뉴 표시 위치 설정
    final menuPosition =
    Offset(position.dx, position.dy + buttonSize.height + 5);

    showCustomSelectMenu<T>(
      context: context,
      items: items,
      itemText: itemText,
      position: menuPosition,
      backgroundColor: primaryColor,
    ).then((value) {
      if (value != null) {
        onSelected(value);
      }
    });
  }

  // 사용자 정의 지출 유형 입력 다이얼로그
  void _showCustomIncomeTypeDialog() {
    final TextEditingController customTypeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '직접 입력',
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: customTypeController,
          decoration: const InputDecoration(
            hintText: '지출 유형 입력 (10자 이내)',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor, width: 2.0),
            ),
          ),
          maxLength: 10, // 최대 10자 제한
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final customType = customTypeController.text.trim();

              // 입력값 검증
              if (customType.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '값이 입력되어 있지 않습니다.',
                      style: TextStyle(
                        fontSize: 20, // 텍스트 크기 조정
                        fontWeight: FontWeight.bold, // 선택적으로 글꼴 두께 조정
                      ),
                    ),
                    backgroundColor: AppColors.grey,
                  ),
                );
                return;
              }

              // 이미 있는 옵션인지 확인
              if (_incomeTypes.contains(customType) ||
                  _customIncomeTypes.contains(customType)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '이미 존재하는 지출 유형입니다.',
                      style: TextStyle(
                        fontSize: 20, // 텍스트 크기 조정
                        fontWeight: FontWeight.bold, // 선택적으로 글꼴 두께 조정
                      ),
                    ),
                    backgroundColor: AppColors.grey,
                  ),
                );
                return;
              }

              // 사용자 정의 유형 추가 및 선택
              setState(() {
                _customIncomeTypes.add(customType);
                _selectedIncomeType = customType;
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 메인 알럿 다이얼로그
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                backgroundColor: Colors.white,
                elevation: 10,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 타이틀
                    const Text(
                      '지출 정보',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3개의 셀렉트 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildIncomeTypeButton(),
                        _buildFrequencyButton(),
                        _buildDayButton(),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 금액 입력 (편집 모드에 따라 버튼 또는 텍스트 필드 표시)
                    _isEditing ? _buildTextField() : _buildCustomButton(),

                    const SizedBox(height: 20),

                    // 하단 액션 버튼
                    _buildActionButtons(),
                  ],
                ),
              ),
            );
          },
        ),

        // 투명 알럿 (추가된 항목 목록)
        // 애니메이션 계단식 적용을 위해 AnimatedBuilder 이동
        if (_expenseController.getAllEntries().isNotEmpty)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // 메인 알럿보다 약간 늦게 나타나도록 애니메이션 조정
              final delayedAnimation = _animation.value > 0.2
                  ? (_animation.value - 0.2) *
                  1.25 // 0.2 이후부터 시작하고 1.25배 속도로 따라잡음
                  : 0.0;
              // 애니메이션 값이 1을 초과하지 않게 조정
              final adjustedValue =
              delayedAnimation > 1.0 ? 1.0 : delayedAnimation;

              return Positioned(
                top: 80, // 메인 알럿 위에 표시
                left: 0,
                right: 0,
                child: Transform.scale(
                  scale: adjustedValue,
                  child: _buildTransparentAlert(),
                ),
              );
            },
          ),

        // 로딩 인디케이터
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ),
      ],
    );
  }

  // 지출 유형 선택 버튼
  Widget _buildIncomeTypeButton() {
    return Builder(
      builder: (buttonContext) {
        return SelectUnderlineButton(
          text: _selectedIncomeType,
          width: 63,
          onTap: () {
            // 기본 유형 + 사용자 정의 유형을 합친 전체 목록
            final allTypes = [..._incomeTypes, ..._customIncomeTypes];

            _showSelectMenu<String>(
              items: allTypes,
              itemText: (item) => item,
              onSelected: (value) {
                if (value == '기타') {
                  // '기타' 선택 시 사용자 정의 입력 다이얼로그 표시
                  _showCustomIncomeTypeDialog();
                } else {
                  setState(() {
                    _selectedIncomeType = value;
                  });
                }
              },
              buttonContext: buttonContext,
            );
          },
        );
      },
    );
  }

  // 빈도 선택 버튼
  Widget _buildFrequencyButton() {
    return Builder(
      builder: (buttonContext) {
        return SelectUnderlineButton(
          text: _selectedFrequency,
          width: 63,
          onTap: () {
            _showSelectMenu<String>(
              items: _frequencies,
              itemText: (item) => item,
              onSelected: (value) {
                setState(() {
                  _selectedFrequency = value;

                  // 빈도가 변경되면 일자도 적절히 조정
                  if (value == '매주') {
                    // 매주로 변경 시 1-7 사이로 제한 (월-일)
                    if (_selectedDay > 7) {
                      _selectedDay = (_selectedDay - 1) % 7 + 1;
                    }
                  } else if (value == '매일') {
                    // 매일로 변경 시 일자는 의미가 없어짐
                    _selectedDay = 1;
                  }
                });
              },
              buttonContext: buttonContext,
            );
          },
        );
      },
    );
  }

  // 일자 선택 버튼
  Widget _buildDayButton() {
    // 매일이면 버튼 숨기기
    if (_selectedFrequency == '매일') {
      return const SizedBox(width: 80);
    }

    return Builder(
      builder: (buttonContext) {
        // 매주이면 요일로 표시
        if (_selectedFrequency == '매주') {
          final weekdayIndex = (_selectedDay - 1) % 7;
          final weekday = _weekdays[weekdayIndex];

          return SelectUnderlineButton(
            text: '$weekday요일',
            width: 80,
            onTap: () {
              _showSelectMenu<String>(
                items: _weekdays,
                itemText: (item) => '${item}요일',
                onSelected: (value) {
                  setState(() {
                    // 요일 인덱스 + 1로 저장 (1=월요일, 2=화요일, ...)
                    _selectedDay = _weekdays.indexOf(value) + 1;
                  });
                },
                buttonContext: buttonContext,
              );
            },
          );
        } else {
          // 매월이면 일자로 표시
          return SelectUnderlineButton(
            text: '${_selectedDay}일',
            width: 63,
            onTap: () {
              _showSelectMenu<int>(
                items: _days,
                itemText: (item) => '${item}일',
                onSelected: (value) {
                  setState(() {
                    _selectedDay = value;
                  });
                },
                buttonContext: buttonContext,
              );
            },
          );
        }
      },
    );
  }

  // 커스텀 버튼 (UnderlineButton)
  Widget _buildCustomButton() {
    return Theme(
      // 텍스트 색상을 앱 색상에 맞게 오버라이드
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: primaryColor,
          displayColor: primaryColor,
        ),
      ),
      child: UnderlineButton(
        text: '금액',
        width: 200,
        onTap: () => _startEditing(),
      ),
    );
  }

  // 텍스트 필드 (편집 모드)
  Widget _buildTextField() {
    // primaryColor 사용
    final Color textColor = primaryColor;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: textColor, width: 2)),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        style: TextStyle(
          color: textColor,
          fontSize: 32, // 글자 크기 축소
          fontFamily: 'Noto Sans JP',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: '숫자 입력',
          hintStyle: TextStyle(
            color: textColor.withOpacity(0.5),
            fontSize: 32, // 힌트 텍스트 크기도 축소
            fontFamily: 'Noto Sans JP',
          ),
        ),
        onChanged: (value) {
          // 1000원 단위 콤마 추가
          final formatted = _formatNumber(value.replaceAll(',', ''));
          if (formatted != value) {
            _textController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        },
      ),
    );
  }

  // 액션 버튼 (추가/수정/삭제)
  Widget _buildActionButtons() {
    if (_isEditing && _isUpdating) {
      // 수정 모드일 때 버튼
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _confirmDelete,
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _updateExpense,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(AppColors.primary),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              elevation: MaterialStateProperty.all(0),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              overlayColor: MaterialStateProperty.resolveWith(
                    (states) {
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.white.withOpacity(0.1);
                  }
                  return null;
                },
              ),
            ),
            child: const Text(
              '수정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          )
        ],
      );
    } else if (_isEditing) {
      // 새 항목 추가 모드일 때 버튼
      return Align(
        alignment: Alignment.bottomRight,
        child: ElevatedButton(
          onPressed: _addExpense,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(AppColors.primary),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            elevation: MaterialStateProperty.all(0),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            overlayColor: MaterialStateProperty.resolveWith(
                  (states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.white.withOpacity(0.1);
                }
                return null;
              },
            ),
          ),
          child: const Text(
            '추가',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    } else {
      // 기본 상태 버튼 (+ DB 정보 출력 버튼)
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('닫기'),
          ),
          if (_expenseController.getAllEntries().isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.nextPage();
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(AppColors.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                elevation: MaterialStateProperty.all(0),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                overlayColor: MaterialStateProperty.resolveWith(
                      (states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.white.withOpacity(0.1);
                    }
                    return null;
                  },
                ),
              ),
              child: const Text(
                '다음',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            )
        ],
      );
    }
  }

  // 투명 알럿 (추가된 항목 목록)
  Widget _buildTransparentAlert() {
    final entries = _expenseController.getAllEntries();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      constraints: const BoxConstraints(
        maxHeight: 180, // 약 3개 항목이 보이는 높이
      ),
      // Material 위젯 추가 - ListTile을 위한 Material 컨텍스트 제공
      child: Material(
        type: MaterialType.transparency, // 투명 배경 유지
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: entries.length,
          reverse: true, // 최신 항목이 상단에 표시
          itemBuilder: (context, index) {
            final entry = entries[index];

            return ListTile(
              title: Text(
                entry.getDisplayText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Noto Sans JP',
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              onTap: () => _startEditing(entry),
            );
          },
        ),
      ),
    );
  }
}

// 커스텀 셀렉트 메뉴 표시 함수
Future<T?> showCustomSelectMenu<T>({
  required BuildContext context,
  required List<T> items,
  required String Function(T) itemText,
  required Offset position,
  double maxHeight = 200,
  Color backgroundColor = Colors.pink,
  Color textColor = Colors.white,
}) async {
  final RenderBox overlay =
  Overlay.of(context).context.findRenderObject() as RenderBox;
  final size = overlay.size;

  // 메뉴가 화면 밖으로 나가지 않도록 위치 조정
  final double menuWidth = 150;
  final double menuX = position.dx;
  final double menuY = position.dy;

  // 오른쪽에 공간이 부족한 경우 왼쪽으로 이동
  final adjustedX =
  menuX + menuWidth > size.width ? size.width - menuWidth - 10 : menuX;

  // 실제 표시될 아이템 수에 따라 높이 계산
  final itemHeight = 48.0;
  final double calculatedHeight = items.length * itemHeight;
  final double menuHeight =
  calculatedHeight > maxHeight ? maxHeight : calculatedHeight;

  // 아래쪽에 공간이 부족한 경우 위쪽으로 이동
  final adjustedY =
  menuY + menuHeight > size.height ? menuY - menuHeight : menuY;

  return await showDialog<T>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned(
            left: adjustedX,
            top: adjustedY,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: backgroundColor,
              child: Container(
                width: menuWidth,
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop(item);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: index < items.length - 1
                              ? Border(
                            bottom: BorderSide(
                              color: textColor.withOpacity(0.2),
                              width: 1,
                            ),
                          )
                              : null,
                        ),
                        child: Text(
                          itemText(item),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

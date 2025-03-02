import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../models/expense_entry.dart';
import '../widgets/underline_button.dart';
import '../widgets/select_underline_button.dart';
import '../widgets/blinking_line.dart';
import '../controllers/expense_controller.dart';

class PageContent1Alert extends StatefulWidget {
  const PageContent1Alert({Key? key}) : super(key: key);

  @override
  State<PageContent1Alert> createState() => _PageContent1AlertState();
}

class _PageContent1AlertState extends State<PageContent1Alert> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final ExpenseController _expenseController = ExpenseController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isEditing = false;
  bool _isUpdating = false;
  ExpenseEntry? _selectedEntry;

  // 선택한 값들 저장
  String _selectedIncomeType = '월급';
  String _selectedFrequency = '매월';
  int _selectedDay = 5;

  // 드롭다운 옵션들
  final List<String> _incomeTypes = ['월급', '용돈', '이자'];
  final List<String> _frequencies = ['매월', '매주', '매일'];
  final List<int> _days = List.generate(31, (index) => index + 1);
  final List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

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

    // 위젯이 빌드된 후 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
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
  void _addExpense() {
    if (_textController.text.isEmpty) return;

    final amountText = _textController.text.replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (amount != null) {
      final newEntry = ExpenseEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        incomeType: _selectedIncomeType,
        frequency: _selectedFrequency,
        day: _selectedDay,
        createdAt: DateTime.now(),
      );

      _expenseController.addEntry(newEntry);
      _stopEditing();

      // 애니메이션 효과로 새 항목 표시
      setState(() {});
    }
  }

  // 금액 수정
  void _updateExpense() {
    if (_selectedEntry == null || _textController.text.isEmpty) return;

    final amountText = _textController.text.replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (amount != null) {
      final updatedEntry = ExpenseEntry(
        id: _selectedEntry!.id,
        amount: amount,
        incomeType: _selectedIncomeType,
        frequency: _selectedFrequency,
        day: _selectedDay,
        createdAt: _selectedEntry!.createdAt,
        updatedAt: DateTime.now(),
      );

      _expenseController.updateEntry(updatedEntry);
      _stopEditing();

      // 애니메이션 효과로 업데이트된 항목 표시
      setState(() {});
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
            onPressed: () {
              Navigator.pop(context);
              _expenseController.deleteEntry(_selectedEntry!.id);
              _stopEditing();
              setState(() {});
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
    final menuPosition = Offset(position.dx, position.dy + buttonSize.height + 5);

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
                      '소득 정보',
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
                    _isEditing
                        ? _buildTextField()
                        : _buildCustomButton(),

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
                  ? (_animation.value - 0.2) * 1.25 // 0.2 이후부터 시작하고 1.25배 속도로 따라잡음
                  : 0.0;
              // 애니메이션 값이 1을 초과하지 않게 조정
              final adjustedValue = delayedAnimation > 1.0 ? 1.0 : delayedAnimation;

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
      ],
    );
  }

  // 소득 유형 선택 버튼
  Widget _buildIncomeTypeButton() {
    return Builder(
      builder: (buttonContext) {
        return SelectUnderlineButton(
          text: _selectedIncomeType,
          width: 80,
          onTap: () {
            _showSelectMenu<String>(
              items: _incomeTypes,
              itemText: (item) => item,
              onSelected: (value) {
                setState(() {
                  _selectedIncomeType = value;
                });
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
          width: 80,
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
            width: 80,
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
          fontFamily: 'hakFont',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: '금액 입력',
          hintStyle: TextStyle(
            color: textColor.withOpacity(0.5),
            fontSize: 24, // 힌트 텍스트 크기도 축소
            fontFamily: 'hakFont',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('수정'),
          ),
        ],
      );
    } else if (_isEditing) {
      // 새 항목 추가 모드일 때 버튼
      return Align(
        alignment: Alignment.bottomRight,
        child: ElevatedButton(
          onPressed: _addExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('추가'),
        ),
      );
    } else {
      // 기본 상태 버튼
      return Align(
        alignment: Alignment.bottomRight,
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
          ),
          child: const Text('닫기'),
        ),
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
            final formattedAmount = _formatNumber(entry.amount.toString());

            return ListTile(
              title: Text(
                entry.getDisplayText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'hakFont',
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
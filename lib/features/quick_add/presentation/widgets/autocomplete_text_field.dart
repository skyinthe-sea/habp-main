import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/autocomplete_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';

/// 자동완성 기능이 있는 텍스트 필드 위젯
class AutocompleteTextField extends StatefulWidget {
  /// 텍스트 컨트롤러
  final TextEditingController controller;
  
  /// 힌트 텍스트
  final String hintText;
  
  /// 자동완성 서비스
  final AutocompleteService autocompleteService;
  
  /// 텍스트 입력 변경 콜백
  final ValueChanged<String>? onChanged;
  
  /// 텍스트 제출 콜백
  final ValueChanged<String>? onSubmitted;
  
  const AutocompleteTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.autocompleteService,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // 포커스 변경 리스너
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
    
    // 컨트롤러 리스너
    widget.controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(() {});
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }
  
  // 텍스트 변경 이벤트 처리
  void _onTextChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
    }
    
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
  }
  
  // 자동완성 추천 항목 업데이트
  Future<void> _updateSuggestions() async {
    final query = widget.controller.text;
    
    if (query.isEmpty) {
      if (_suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
        });
        _updateOverlay();
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final suggestions = await widget.autocompleteService.getSuggestions(query);
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
      
      _updateOverlay();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _suggestions = [];
      });
    }
  }
  
  // 추천 항목 선택 처리
  void _selectSuggestion(String suggestion) {
    widget.controller.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
    
    _hideOverlay();
    widget.autocompleteService.saveDescription(suggestion);
    
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(suggestion);
    }
  }
  
  // 오버레이 표시 (추천 항목 목록)
  void _showOverlay() {
    _hideOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildSuggestionsOverlay(),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    _updateSuggestions();
  }
  
  // 오버레이 업데이트
  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }
  
  // 오버레이 숨기기
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  // 추천 항목 오버레이 빌드
  Widget _buildSuggestionsOverlay() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Positioned(
      width: MediaQuery.of(context).size.width - 56,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 60),
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(12),
          child: Obx(() => Container(
            constraints: BoxConstraints(
              maxHeight: 200,
              maxWidth: MediaQuery.of(context).size.width - 56,
            ),
            decoration: BoxDecoration(
              color: themeController.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeController.isDarkMode
                    ? themeController.textSecondaryColor.withOpacity(0.2)
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeController.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          themeController.primaryColor,
                        ),
                      ),
                    ),
                  ),
                )
              : _suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      '추천 항목이 없습니다',
                      style: TextStyle(
                        color: themeController.textSecondaryColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectSuggestion(suggestion),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 16,
                                  color: themeController.textSecondaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeController.textPrimaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: themeController.textSecondaryColor.withOpacity(0.7),
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    await widget.autocompleteService.removeDescription(suggestion);
                                    _updateSuggestions();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          )),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: Obx(() => TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: TextStyle(
          color: themeController.textPrimaryColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: themeController.textSecondaryColor,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: themeController.isDarkMode
                  ? themeController.textSecondaryColor.withOpacity(0.3)
                  : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeController.primaryColor),
          ),
          fillColor: themeController.surfaceColor,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: themeController.textSecondaryColor,
                  size: 18,
                ),
                onPressed: () {
                  widget.controller.clear();
                  setState(() {
                    _suggestions = [];
                  });
                  _updateOverlay();
                },
              )
            : null,
        ),
        onSubmitted: widget.onSubmitted,
      )),
    );
  }
}
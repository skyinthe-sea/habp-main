import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설명 자동완성을 위한 서비스
/// 사용자가 입력한 설명을 저장하고 자동완성 추천을 제공합니다.
class AutocompleteService {
  static const String _keyRecentDescriptions = 'recent_descriptions';
  static const int _maxStoredItems = 100;  // 최대 저장 항목 수

  // 최근 설명 항목 가져오기
  Future<List<String>> getRecentDescriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_keyRecentDescriptions);
      
      if (jsonData == null) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(jsonData);
      return decoded.map((item) => item.toString()).toList();
    } catch (e) {
      debugPrint('Error loading recent descriptions: $e');
      return [];
    }
  }
  
  // 설명 저장하기
  Future<void> saveDescription(String description) async {
    if (description.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> descriptions = await getRecentDescriptions();
      
      // 중복 제거 (기존 항목이 있으면 삭제 후 다시 추가하여 최신 순서 유지)
      descriptions.removeWhere((item) => item == description);
      
      // 새 항목을 목록 앞쪽에 추가
      descriptions.insert(0, description);
      
      // 최대 저장 개수 제한
      if (descriptions.length > _maxStoredItems) {
        descriptions = descriptions.sublist(0, _maxStoredItems);
      }
      
      // JSON으로 인코딩하여 저장
      await prefs.setString(_keyRecentDescriptions, jsonEncode(descriptions));
    } catch (e) {
      debugPrint('Error saving description: $e');
    }
  }
  
  // 자동완성 제안 항목 얻기
  Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    final allDescriptions = await getRecentDescriptions();
    
    // 한글 초성 검색 지원
    final isHangul = RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]').hasMatch(query);
    
    if (isHangul) {
      // 한글 초성 매칭 (ㅅ -> 서울, 선릉, 사과 등)
      return allDescriptions.where((desc) {
        if (desc.isEmpty) return false;
        
        // 초성으로 시작하는지 체크
        for (int i = 0; i < query.length && i < desc.length; i++) {
          final ch = desc[i];
          if (!_matchesHangulInitial(ch, query[i])) {
            return false;
          }
        }
        return true;
      }).toList();
    } else {
      // 일반 텍스트 검색 (영문 등)
      final normalizedQuery = query.toLowerCase();
      return allDescriptions
          .where((desc) => desc.toLowerCase().contains(normalizedQuery))
          .toList();
    }
  }
  
  // 한글 초성 매칭 함수
  bool _matchesHangulInitial(String char, String initial) {
    // 한글 초성 매핑 (간단한 구현, 필요시 더 정교하게 개선 가능)
    Map<String, List<String>> initialMap = {
      'ㄱ': ['가', '각', '간', '갇', '갈', '감', '강', '같'],
      'ㄴ': ['나', '낙', '난', '날', '남', '낮', '낭', '내'],
      'ㄷ': ['다', '닥', '단', '달', '담', '당', '대', '더'],
      'ㄹ': ['라', '락', '란', '람', '랑', '래', '량', '러'],
      'ㅁ': ['마', '막', '만', '말', '맑', '맞', '맴', '망'],
      'ㅂ': ['바', '박', '반', '받', '발', '밤', '방', '배'],
      'ㅅ': ['사', '삭', '산', '살', '삼', '상', '새', '샤'],
      'ㅇ': ['아', '악', '안', '알', '암', '앙', '애', '야'],
      'ㅈ': ['자', '작', '잔', '잘', '잠', '장', '재', '저'],
      'ㅊ': ['차', '착', '찬', '찰', '참', '창', '채', '처'],
      'ㅋ': ['카', '칸', '칼', '캄', '캉', '캐', '컨', '커'],
      'ㅌ': ['타', '탁', '탄', '탈', '탐', '탑', '태', '터'],
      'ㅍ': ['파', '팍', '판', '팔', '팜', '팡', '패', '퍼'],
      'ㅎ': ['하', '학', '한', '할', '함', '합', '항', '해'],
    };
    
    // 정확한 초성을 찾을 수 없는 경우, 문자 자체가 일치하는지 확인
    if (char.toLowerCase() == initial.toLowerCase()) {
      return true;
    }
    
    // 한글 초성이 아닌 경우 (영문 등)
    if (!initialMap.containsKey(initial)) {
      return false;
    }
    
    // 초성으로 시작하는 문자 체크
    List<String> matchingChars = initialMap[initial] ?? [];
    return matchingChars.any((c) => char.startsWith(c));
  }
  
  // 설명 기록 지우기
  Future<void> clearDescriptionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRecentDescriptions);
    } catch (e) {
      debugPrint('Error clearing description history: $e');
    }
  }
  
  // 특정 설명 항목 삭제
  Future<void> removeDescription(String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> descriptions = await getRecentDescriptions();
      
      descriptions.removeWhere((item) => item == description);
      
      await prefs.setString(_keyRecentDescriptions, jsonEncode(descriptions));
    } catch (e) {
      debugPrint('Error removing description: $e');
    }
  }
}
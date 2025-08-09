import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class VersionCheckService extends GetxService {
  // 앱 버전 정보
  late PackageInfo _packageInfo;
  
  // 스토어 URL (실제 앱 출시 시 업데이트)
  final String _androidStoreUrl = 'market://details?id=ljs.salamander.habp';
  final String _iosStoreUrl = 'itms-apps://itunes.apple.com/app/id6745023427';
  
  // API 엔드포인트 (실제 서버 URL로 변경 필요)
  final String _apiUrl = 'https://example.com/api/version';
  
  // 로컬 테스트용 버전 정보 (서버 API 연동 전까지 사용)
  final Map<String, dynamic> _testVersionData = {
    'androidLatestVersion': '1.3.0',
    'iosLatestVersion': '1.3.0',
    'forceUpdate': false,
    'updateMessage': '새로운 기능과 버그 수정이 포함된 업데이트가 있습니다.'
  };

  Future<VersionCheckService> init() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      debugPrint('현재 앱 버전: ${_packageInfo.version}');
    } catch (e) {
      debugPrint('패키지 정보 가져오기 실패: $e');
    }
    return this;
  }

  // 버전 체크 메인 함수
  Future<Map<String, dynamic>> checkVersion() async {
    try {
      // 현재 버전 가져오기
      final currentVersion = _packageInfo.version;
      
      // 서버에서 최신 버전 정보 가져오기
      final versionData = await _getLatestVersionData();
      
      // 앱 플랫폼에 따라 적절한 최신 버전 가져오기
      final latestVersion = Platform.isAndroid 
          ? versionData['androidLatestVersion'] 
          : versionData['iosLatestVersion'];
      
      // 업데이트 필요 여부 확인
      final needsUpdate = _compareVersions(currentVersion, latestVersion);
      
      return {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'needsUpdate': needsUpdate,
        'forceUpdate': versionData['forceUpdate'],
        'updateMessage': versionData['updateMessage'],
      };
    } catch (e) {
      debugPrint('버전 체크 중 오류 발생: $e');
      return {
        'needsUpdate': false,
        'error': e.toString(),
      };
    }
  }

  // 서버에서 최신 버전 정보 가져오기
  Future<Map<String, dynamic>> _getLatestVersionData() async {
    try {
      if (kDebugMode) {
        // 디버그 모드에서는 테스트 데이터 사용
        return _testVersionData;
      }
      
      // 서버 API 호출
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('서버 오류: ${response.statusCode}');
        return _testVersionData;
      }
    } catch (e) {
      debugPrint('버전 정보 가져오기 실패: $e');
      // API 호출 실패 시 테스트 데이터로 폴백
      return _testVersionData;
    }
  }

  // 버전 비교 (semver 비교)
  bool _compareVersions(String currentVersion, String latestVersion) {
    try {
      final current = currentVersion.split('.')
          .map((e) => int.parse(e))
          .toList();
      
      final latest = latestVersion.split('.')
          .map((e) => int.parse(e))
          .toList();
      
      // 메이저 버전 비교
      if (latest[0] > current[0]) return true;
      if (latest[0] < current[0]) return false;
      
      // 마이너 버전 비교
      if (latest[1] > current[1]) return true;
      if (latest[1] < current[1]) return false;
      
      // 패치 버전 비교
      return latest[2] > current[2];
    } catch (e) {
      debugPrint('버전 비교 중 오류: $e');
      return false;
    }
  }

  // 스토어로 이동
  Future<bool> openStore() async {
    final url = Platform.isAndroid ? _androidStoreUrl : _iosStoreUrl;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // 스토어 열기 실패 시 대체 URL 시도
        final fallbackUrl = Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=ljs.salamander.habp'
            : 'https://apps.apple.com/kr/app/%EC%88%98%EA%B8%B0%EA%B0%80%EA%B3%84%EB%B6%80/id6745023427';
        
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('스토어 열기 실패: $e');
      return false;
    }
  }

  // 업데이트 다이얼로그 표시
  void showUpdateDialog({
    required BuildContext context,
    required String latestVersion,
    required String message,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 부분 (그라데이션)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE495C0).withOpacity(0.8),
                      const Color(0xFFE495C0).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      forceUpdate ? Icons.system_update_alt : Icons.system_update,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '업데이트 안내',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v$latestVersion',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 내용 부분
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: forceUpdate 
                            ? Colors.red.shade50 
                            : const Color(0xFFE495C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            forceUpdate ? Icons.warning : Icons.info_outline,
                            color: forceUpdate 
                                ? Colors.red.shade700 
                                : const Color(0xFFE495C0),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              forceUpdate 
                                  ? '앱 사용을 계속하려면 업데이트가 필요합니다.'
                                  : '지금 업데이트하시겠습니까?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: forceUpdate 
                                    ? Colors.red.shade700 
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 버튼 부분
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    if (!forceUpdate)
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          child: Text(
                            '나중에',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    if (!forceUpdate) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          openStore();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE495C0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          '업데이트',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
    );
  }
}
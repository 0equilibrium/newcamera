# 무음 카메라 앱 프로젝트 계획

## 프로젝트 개요
- **앱 이름**: Silent Camera
- **패키지명**: com.nativeinc.newcamera
- **Bundle ID**: com.nativeinc.newcamera
- **플랫폼**: Flutter (iOS/Android)

## 주요 기능
1. **카메라 뷰파인더**: 실시간 카메라 미리보기
2. **무음 촬영**: 사진 촬영 시 소리 없이 스크린샷 방식으로 촬영
3. **갤러리 저장**: 촬영한 사진을 기기 갤러리에 저장

## 기술 구현 방식
- **카메라 뷰파인더**: `camera` 패키지 사용
- **스크린샷 촬영**: `RepaintBoundary`와 `GlobalKey`를 사용하여 뷰파인더 영역만 캡처
- **이미지 저장**: `image_gallery_saver` 패키지 사용
- **권한 관리**: `permission_handler` 패키지 사용

## 프로젝트 구조
```
lib/
├── main.dart                 # 앱 진입점
├── screens/
│   └── camera_screen.dart    # 카메라 화면
├── widgets/
│   └── camera_viewfinder.dart # 카메라 뷰파인더 위젯
├── services/
│   ├── camera_service.dart   # 카메라 관련 서비스
│   └── image_service.dart    # 이미지 저장 서비스
└── utils/
    └── permissions.dart      # 권한 관리 유틸리티
```

## 필요한 패키지
- `camera: ^0.10.5+5` - 카메라 기능
- `permission_handler: ^11.0.1` - 권한 관리
- `image_gallery_saver: ^2.0.3` - 갤러리 저장
- `path_provider: ^2.1.1` - 파일 경로 관리
- `path: ^1.8.3` - 경로 조작

## 구현 단계
1. Flutter 프로젝트 생성 및 기본 설정
2. 필요한 패키지 추가
3. 권한 관리 구현
4. 카메라 뷰파인더 구현
5. 스크린샷 촬영 기능 구현
6. 이미지 저장 기능 구현
7. UI/UX 개선
8. 테스트 및 최적화

## 주의사항
- iOS/Android 카메라 권한 요청
- 갤러리 저장 권한 요청
- 카메라 초기화 실패 처리
- 메모리 관리 (이미지 처리 시)
- 배터리 최적화




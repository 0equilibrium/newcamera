import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false;
  double _currentZoom = 1.0;
  final List<double> _zoomLevels = [0.5, 1.0, 2.0, 3.0];
  bool _isFrontCamera = false; // false: 후면, true: 전면
  String _currentAspectRatio = '4:3'; // 4:3, 1:1, 16:9
  bool _isFlashOn = false;
  bool _isDualMode = false;

  // 카메라 관련 변수들
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // 카메라 권한 요청
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _isPermissionGranted = false;
      });
      return;
    }

    setState(() {
      _isPermissionGranted = true;
    });

    try {
      // 사용 가능한 카메라 목록 가져오기
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print('사용 가능한 카메라가 없습니다.');
        return;
      }

      // 후면 카메라를 기본으로 설정
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      // 카메라 컨트롤러 초기화
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('카메라 초기화 오류: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_isCameraInitialized || _cameraController == null)
      return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // 실제 카메라로 사진 촬영
      final XFile photo = await _cameraController!.takePicture();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진이 촬영되었습니다! 경로: ${photo.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 촬영 오류: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _openGallery() {
    // 갤러리 열기 더미 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('갤러리를 열었습니다!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _changeZoom(double zoom) {
    setState(() {
      _currentZoom = zoom;
    });
  }

  Future<void> _toggleCamera() async {
    if (!_isCameraInitialized || _cameras.length < 2) return;

    try {
      // 현재 카메라 방향에 따라 반대 카메라로 전환
      final newCamera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (_isFrontCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
      );

      // 기존 컨트롤러 해제
      await _cameraController?.dispose();

      // 새로운 카메라로 컨트롤러 생성
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
    } catch (e) {
      print('카메라 전환 오류: $e');
    }
  }

  void _changeAspectRatio() {
    setState(() {
      switch (_currentAspectRatio) {
        case '4:3':
          _currentAspectRatio = '1:1';
          break;
        case '1:1':
          _currentAspectRatio = '16:9';
          break;
        case '16:9':
          _currentAspectRatio = '4:3';
          break;
      }
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _toggleDualMode() {
    setState(() {
      _isDualMode = !_isDualMode;
    });
  }

  // removed unused _toggleSubViewPosition; snapping now handled onPanEnd

  Widget _buildSingleViewfinder() {
    // 카메라가 초기화되지 않았거나 권한이 없는 경우 로딩 화면 표시
    if (!_isPermissionGranted) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white54),
              SizedBox(height: 20),
              Text(
                '카메라 권한이 필요합니다',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '설정에서 카메라 권한을 허용해주세요',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 20),
              Text(
                '카메라를 초기화하는 중...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // 실제 카메라 프리뷰 표시
    return CameraPreview(_cameraController!);
  }

  Widget _buildDualViewfinder() {
    // 듀얼 모드는 현재 단순화하여 메인 뷰파인더만 표시
    return _buildSingleViewfinder();
  }

  @override
  Widget build(BuildContext context) {
    // 전체화면 모드 설정
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        child: Stack(
          children: [
            // 카메라 뷰파인더
            Positioned.fill(
              child: _isDualMode
                  ? _buildDualViewfinder()
                  : _buildSingleViewfinder(),
            ),

            // 상단 컨트롤 (오른쪽 위) - SafeArea 적용으로 클릭 문제 해결
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // 비율 전환 버튼 - 터치 영역 확장
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _changeAspectRatio,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                _currentAspectRatio,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 플래시 버튼 - 터치 영역 확장
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleFlash,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isFlashOn
                                  ? Colors.yellow
                                  : Colors.black54,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              _isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: _isFlashOn ? Colors.black : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 듀얼 모드 버튼 - 터치 영역 확장
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleDualMode,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isDualMode
                                  ? Colors.white
                                  : Colors.black54,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_front,
                              color: _isDualMode ? Colors.black : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 줌 컨트롤 - 듀얼 모드가 아닐 때만 항상 표시
            if (!_isDualMode)
              Positioned(
                bottom: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _zoomLevels.map((zoom) {
                        final isSelected = _currentZoom == zoom;
                        final displayText = zoom == 0.5
                            ? '0.5'
                            : '${zoom.toInt()}';

                        return GestureDetector(
                          onTap: () => _changeZoom(zoom),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                displayText,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            // 하단 버튼들 - 항상 표시
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 갤러리 버튼
                  GestureDetector(
                    onTap: _openGallery,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),

                  // 셔터 버튼
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing ? Colors.grey : Colors.white,
                        border: Border.all(
                          color: _isCapturing ? Colors.grey : Colors.white,
                          width: 4,
                        ),
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 40,
                            ),
                    ),
                  ),

                  // 카메라 전환 버튼
                  GestureDetector(
                    onTap: _toggleCamera,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'qrcode_reader_controller.dart';
import 'package:flutter/scheduler.dart';

/// 使用前需已经获取相关权限
/// Relevant privileges must be obtained before use
class QrcodeReaderView extends StatefulWidget {
  final Widget headerWidget;
  final Future Function(String) onScan;
  final double scanBoxRatio;
  final Color boxLineColor;
  final Widget helpWidget;
  final Color cornerColor;
  final Widget scanWidget;

  final String noCameraPermissionMessage;
  final String ratioSuggestErrorMessage;
  final String scanInfoMessage;

  QrcodeReaderView({
    Key key,
    @required this.onScan,
    this.headerWidget,
    this.boxLineColor = Colors.cyanAccent,
    this.helpWidget,
    this.scanBoxRatio = 0.85,
    this.cornerColor,
    this.scanWidget,
    this.noCameraPermissionMessage,
    this.ratioSuggestErrorMessage,
    this.scanInfoMessage
  }) : super(key: key);

  @override
  QrcodeReaderViewState createState() => new QrcodeReaderViewState();
}

/// 扫码后的后续操作
/// ```dart
/// GlobalKey<QrcodeReaderViewState> qrViewKey = GlobalKey();
/// qrViewKey.currentState.startScan();
/// ```
class QrcodeReaderViewState extends State<QrcodeReaderView> {
  QrReaderViewController _controller;
  bool openFlashlight;
  bool hasCameraPermission = false;
  @override
  void initState() {
    super.initState();
    openFlashlight = false;

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      bool isOk = await getPermissionOfCamera();
      if (isOk) {
        setState(() {
          hasCameraPermission = true;
        });
      } else {
        Navigator.of(context).pop(widget.noCameraPermissionMessage);
      }
    });
  }

  Future<bool> getPermissionOfCamera() async {
    PermissionStatus status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  void _onCreateController(QrReaderViewController controller) async {
    _controller = controller;
    _controller.startCamera(_onQrBack);
  }

  bool isScan = false;
  Future _onQrBack(data, _) async {
    if (isScan == true) return;
    isScan = true;
    stopScan();
    await widget.onScan(data);
  }

  void startScan() {
    isScan = false;
    _controller.startCamera(_onQrBack);
  }

  void stopScan() {
    _controller.stopCamera();
  }

  Future<bool> setFlashlight() async {
    openFlashlight = await _controller.setFlashlight();
    setState(() {});
    return openFlashlight;
  }

  Future _scanImage() async {
    stopScan();
    PermissionStatus status = await Permission.camera.request();
    if (status == PermissionStatus.granted) {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        startScan();
        return;
      }
      final rest = await FlutterQrReader.imgScan(image);
      await widget.onScan(rest);
    } else {
      startScan();
    }
  }

  final flashOpen = Image.asset(
    "assets/tool_flashlight_open.png",
    package: "super_qr_reader",
    width: 35,
    height: 35,
    color: Colors.white,
  );
  final flashClose = Image.asset(
    "assets/tool_flashlight_close.png",
    package: "super_qr_reader",
    width: 35,
    height: 35,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return !hasCameraPermission
        ? Material(
            color: Colors.black,
            child: Container(
              color: Colors.black,
            ),
          )
        : Material(
            color: Colors.black,
            child: LayoutBuilder(builder: (context, constraints) {
              final qrScanSize = constraints.maxWidth * widget.scanBoxRatio;
              final mediaQuery = MediaQuery.of(context);
              if (constraints.maxHeight < qrScanSize * 1.5) {
                print(widget.ratioSuggestErrorMessage);
              }
              return Stack(
                children: <Widget>[
                  Center(
                    child: SizedBox(
                      width: constraints.maxWidth * 0.84,
                      height: constraints.maxWidth * 0.84,
                      child: QrReaderView(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        callback: _onCreateController,
                      ),
                    ),
                  ),
                  if (widget.headerWidget != null)
                    widget.headerWidget,
                  widget.scanWidget == null
                      ? Positioned(
                          left: (constraints.maxWidth - qrScanSize) / 2,
                          top: (constraints.maxHeight - qrScanSize) / 2,
                          child: CustomPaint(
                            painter: QrScanBoxPainter(
                              boxLineColor: widget.boxLineColor,
                              cornerColor: widget.cornerColor,
                            ),
                            child: SizedBox(
                              width: qrScanSize,
                              height: qrScanSize,
                            ),
                          ),
                        )
                      : widget.scanWidget,
                  Positioned(
                    top: (constraints.maxHeight - qrScanSize) * (1 / 2) +
                        qrScanSize +
                        24,
                    width: constraints.maxWidth,
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: <Widget>[
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: setFlashlight,
                            child: openFlashlight ? flashOpen : flashClose,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.05),
                          DefaultTextStyle(
                            style: TextStyle(color: Colors.white),
                            child: widget.helpWidget ??
                                Text(
                                  widget.scanInfoMessage,
                                  textAlign: TextAlign.center,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Positioned(
                  //   top: (constraints.maxHeight - qrScanSize) * (1 / 2) +
                  //       qrScanSize -
                  //       12 -
                  //       35,
                  //   width: constraints.maxWidth,
                  //   child: Align(
                  //     alignment: Alignment.center,
                  //     child: GestureDetector(
                  //       behavior: HitTestBehavior.translucent,
                  //       onTap: setFlashlight,
                  //       child: openFlashlight ? flashOpen : flashClose,
                  //     ),
                  //   ),
                  // ),
                  // Positioned(
                  //   width: constraints.maxWidth,
                  //   bottom: constraints.maxHeight == mediaQuery.size.height
                  //       ? 12 + mediaQuery.padding.top
                  //       : 12,
                  //   child: Row(
                  //     crossAxisAlignment: CrossAxisAlignment.center,
                  //     mainAxisAlignment: MainAxisAlignment.end,
                  //     children: <Widget>[
                  //       Padding(
                  //         padding: const EdgeInsets.only(right: 32),
                  //         child: GestureDetector(
                  //           behavior: HitTestBehavior.translucent,
                  //           onTap: _scanImage,
                  //           child: Container(
                  //             width: 45,
                  //             height: 45,
                  //             alignment: Alignment.center,
                  //             child: Image.asset(
                  //               "assets/tool_img.png",
                  //               package: "super_qr_reader",
                  //               width: 25,
                  //               height: 25,
                  //               color: Colors.white54,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // )
                ],
              );
            }),
          );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class QrScanBoxPainter extends CustomPainter {
  final double animationValue;
  final bool isForward;
  final Color boxLineColor;
  final Color cornerColor;

  QrScanBoxPainter({
    this.cornerColor,
    this.animationValue = 0,
    this.isForward = false,
    this.boxLineColor,
  })  : assert(animationValue != null),
        assert(isForward != null);

  @override
  void paint(Canvas canvas, Size size) {
    final borderRadius = BorderRadius.all(Radius.circular(12)).toRRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRRect(
      borderRadius,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    final borderPaint = Paint()
      ..color = cornerColor ?? Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final path = new Path();
    // leftTop
    path.moveTo(0, 50);
    path.lineTo(0, 12);
    path.quadraticBezierTo(0, 0, 12, 0);
    path.lineTo(50, 0);
    // rightTop
    path.moveTo(size.width - 50, 0);
    path.lineTo(size.width - 12, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 12);
    path.lineTo(size.width, 50);
    // rightBottom
    path.moveTo(size.width, size.height - 50);
    path.lineTo(size.width, size.height - 12);
    path.quadraticBezierTo(
        size.width, size.height, size.width - 12, size.height);
    path.lineTo(size.width - 50, size.height);
    // leftBottom
    path.moveTo(50, size.height);
    path.lineTo(12, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 12);
    path.lineTo(0, size.height - 50);

    canvas.drawPath(path, borderPaint);

    canvas.clipRRect(
        BorderRadius.all(Radius.circular(12)).toRRect(Offset.zero & size));

    // 绘制横向网格
    // final linePaint = Paint();
    // final lineSize = size.height * 0.45;
    // final leftPress = (size.height + lineSize) * animationValue - lineSize;
    // linePaint.style = PaintingStyle.stroke;
    // linePaint.shader = LinearGradient(
    //   colors: [Colors.transparent, boxLineColor],
    //   begin: isForward ? Alignment.topCenter : Alignment(0.0, 2.0),
    //   end: isForward ? Alignment(0.0, 0.5) : Alignment.topCenter,
    // ).createShader(Rect.fromLTWH(0, leftPress, size.width, lineSize));
    // for (int i = 0; i < size.height / 5; i++) {
    //   canvas.drawLine(
    //     Offset(
    //       i * 5.0,
    //       leftPress,
    //     ),
    //     Offset(i * 5.0, leftPress + lineSize),
    //     linePaint,
    //   );
    // }
    // for (int i = 0; i < lineSize / 5; i++) {
    //   canvas.drawLine(
    //     Offset(0, leftPress + i * 5.0),
    //     Offset(
    //       size.width,
    //       leftPress + i * 5.0,
    //     ),
    //     linePaint,
    //   );
    // }
  }

  @override
  bool shouldRepaint(QrScanBoxPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;

  @override
  bool shouldRebuildSemantics(QrScanBoxPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/constantes.dart';

class QrCarnet extends StatelessWidget {
  final String url;
  final double size;

  const QrCarnet({
    super.key,
    required this.url,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: url,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: kPrimary),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: kPrimary),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      errorStateBuilder: (context, error) {
        return Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.error_outline, color: kError, size: 40),
          ),
        );
      },
    );
  }
}

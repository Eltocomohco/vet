import 'package:flutter/material.dart';
import '../utils/constantes.dart';

class SelectorHora extends StatelessWidget {
  final TimeOfDay hora;
  final ValueChanged<TimeOfDay> onChanged;

  const SelectorHora({
    super.key,
    required this.hora,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final nuevaHora = await showTimePicker(
          context: context,
          initialTime: hora,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: const TimePickerThemeData(
                  backgroundColor: kSurface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (nuevaHora != null) {
          onChanged(nuevaHora);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: kPrimary),
            const SizedBox(width: 12),
            Text(
              hora.format(context),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: kTextSecondary),
          ],
        ),
      ),
    );
  }
}

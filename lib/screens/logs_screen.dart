import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/logger_service.dart';
import '../widgets/custom_app_bar.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  LogLevel _filtro = LogLevel.debug;
  final ScrollController _scrollController = ScrollController();

  List<LogEntry> get _logsFiltrados {
    return LoggerService.logs.where((l) {
      return l.level.index >= _filtro.index;
    }).toList().reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final logs = _logsFiltrados;
    final errorCount = LoggerService.errorCount;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Logs de Debug',
        actions: [
          if (errorCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$errorCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copiarTodo,
            tooltip: 'Copiar todos los logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              LoggerService.clear();
              setState(() {});
            },
            tooltip: 'Limpiar logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<LogLevel>(
                segments: const [
                  ButtonSegment(value: LogLevel.debug, label: Text('DEBUG')),
                  ButtonSegment(value: LogLevel.info, label: Text('INFO')),
                  ButtonSegment(value: LogLevel.warn, label: Text('WARN')),
                  ButtonSegment(value: LogLevel.error, label: Text('ERROR')),
                ],
                selected: {_filtro},
                onSelectionChanged: (Set<LogLevel> newSelection) {
                  setState(() {
                    _filtro = newSelection.first;
                  });
                },
              ),
            ),
          ),
          // Lista de logs
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('No hay logs', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _LogTile(log: log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _copiarTodo() {
    final buffer = StringBuffer();
    for (final log in LoggerService.logs) {
      buffer.writeln('[${log.timeFormatted}] [${log.levelName}] ${log.tag}: ${log.message}');
      if (log.exception != null) buffer.writeln('  EXCEPTION: ${log.exception}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copiados al portapapeles')),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (log.level) {
      case LogLevel.debug:
        color = Colors.grey;
      case LogLevel.info:
        color = Colors.blue;
      case LogLevel.warn:
        color = Colors.orange;
      case LogLevel.error:
        color = Colors.red;
    }

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: color.withAlpha(51),
        child: Text(
          log.levelName.substring(0, 1),
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(log.message, style: const TextStyle(fontSize: 13)),
      subtitle: Text('${log.timeFormatted} · ${log.tag}', style: const TextStyle(fontSize: 11)),
      trailing: log.exception != null
          ? const Icon(Icons.error_outline, color: Colors.red, size: 18)
          : null,
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('${log.levelName} · ${log.tag}'),
            content: SingleChildScrollView(
              child: SelectableText(
                'Hora: ${log.timeFormatted}\n'
                'Tag: ${log.tag}\n'
                'Mensaje: ${log.message}\n'
                '${log.exception != null ? '\nEXCEPTION:\n${log.exception}' : ''}'
                '${log.stackTrace != null ? '\nSTACK TRACE:\n${log.stackTrace}' : ''}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Clipboard.setData(ClipboardData(
                  text: '[${log.timeFormatted}] [${log.levelName}] ${log.tag}: ${log.message}\n${log.exception ?? ''}',
                )),
                child: const Text('Copiar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

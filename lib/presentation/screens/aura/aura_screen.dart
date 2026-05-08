import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/aura_speech_service.dart';
import '../../../data/services/aura_voice_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/aura_provider.dart';
import '../../widgets/app_background_scaffold.dart';
import '../../widgets/aura/aura_avatar.dart';
import '../../widgets/aura/aura_chat_bubble.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/glass_panel.dart';

class AuraScreen extends StatefulWidget {
  const AuraScreen({super.key});

  @override
  State<AuraScreen> createState() => _AuraScreenState();
}

class _AuraScreenState extends State<AuraScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final voice = AuraVoiceService();
  final speech = AuraSpeechService();
  bool listening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.idUsuario;
      context.read<AuraProvider>().cargarHistorial(userId);
      voice.init();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    voice.stop();
    speech.stopListening();
    super.dispose();
  }

  Future<void> _send([String? value]) async {
    final text = (value ?? controller.text).trim();
    if (text.isEmpty) return;
    controller.clear();
    await context.read<AuraProvider>().enviarMensaje(text);
    _scrollToBottom();
  }

  Future<void> _listen() async {
    if (listening) {
      await speech.stopListening();
      setState(() => listening = false);
      return;
    }
    final ok = await speech.init();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(speech.error ?? 'No pude activar el microfono.')),
      );
      return;
    }
    setState(() => listening = true);
    await speech.startListening((text) {
      controller.text = text;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuraProvider>();
    _scrollToBottom();
    return AppBackgroundScaffold(
      appBarActions: [
        IconButton(
          tooltip: 'Escuchar ultima respuesta',
          onPressed: aura.lastAuraResponse == null
              ? null
              : () => voice.speak(aura.lastAuraResponse!),
          icon: const Icon(Icons.volume_up, color: Colors.white),
        ),
        IconButton(
          tooltip: 'Detener voz',
          onPressed: voice.stop,
          icon: const Icon(Icons.stop_circle, color: Colors.white),
        ),
        IconButton(
          tooltip: 'Limpiar historial',
          onPressed: aura.limpiarHistorial,
          icon: const Icon(Icons.delete_sweep, color: Colors.white),
        ),
      ],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Escribe o dicta una consulta para AURA',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  onSubmitted: _send,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Dictar',
                onPressed: _listen,
                icon: Icon(listening ? Icons.mic_off : Icons.mic,
                    color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Enviar',
                onPressed: aura.loading ? null : _send,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final chat = _AuraChat(
            controller: scrollController,
            aura: aura,
            onSpeak: voice.speak,
          );
          final side = _AuraPanel(
            listening: listening,
            onQuick: _send,
          );
          return Padding(
            padding: const EdgeInsets.all(16),
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: 320, child: side),
                      const SizedBox(width: 16),
                      Expanded(child: chat),
                    ],
                  )
                : SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Column(
                        children: [
                          side,
                          const SizedBox(height: 12),
                          SizedBox(
                            height: (constraints.maxHeight - 220)
                                .clamp(260.0, 620.0)
                                .toDouble(),
                            child: chat,
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        }),
      ),
    );
  }
}

class _AuraPanel extends StatelessWidget {
  const _AuraPanel({
    required this.listening,
    required this.onQuick,
  });

  final bool listening;
  final ValueChanged<String> onQuick;

  @override
  Widget build(BuildContext context) {
    const quicks = [
      'buscar caballo Paipa',
      'herrajes de hoy',
      'reporte del mes',
      'caballos sin herraje hace 30 dias',
      'herradores bloqueados',
      'mensualidades pendientes',
    ];
    return GlassPanel(
      tintColor: AppColors.auraTint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuraAvatar(),
          const SizedBox(height: 12),
          Text(
            listening ? 'AURA escuchando...' : 'AURA nivel operativo',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quicks
                .map((q) => ActionChip(
                      label: Text(q, style: const TextStyle(color: Colors.white)),
                      backgroundColor: AppColors.auraTint,
                      onPressed: () => onQuick(q),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AuraChat extends StatelessWidget {
  const _AuraChat({
    required this.controller,
    required this.aura,
    required this.onSpeak,
  });

  final ScrollController controller;
  final AuraProvider aura;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      tintColor: AppColors.auraTint,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: aura.messages.length,
              itemBuilder: (context, index) {
                final message = aura.messages[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AuraChatBubble(
                        role: message.role,
                        text: message.text,
                      ),
                    ),
                    if (message.role == 'aura')
                      IconButton(
                        tooltip: 'Escuchar',
                        onPressed: () => onSpeak(message.text),
                        icon: const Icon(Icons.volume_up,
                            size: 20, color: Colors.white),
                      ),
                  ],
                );
              },
            ),
          ),
          if (aura.loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('AURA pensando...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          if (aura.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                aura.error!,
                style: const TextStyle(color: AppColors.red),
              ),
            ),
        ],
      ),
    );
  }
}

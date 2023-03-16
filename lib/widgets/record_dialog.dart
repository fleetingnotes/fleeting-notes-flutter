import 'dart:async';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/Note.dart';

class RecordDialog extends ConsumerStatefulWidget {
  final void Function(String)? onFinish;
  const RecordDialog({super.key, this.onFinish});

  @override
  ConsumerState<RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends ConsumerState<RecordDialog> {
  SiriWaveController waveController =
      SiriWaveController(amplitude: 0.2, speed: 0.1);
  SpeechToText speech = SpeechToText();
  String listenedText = '';
  String errMsg = '';
  bool isListening = true;
  Timer? amplitudeTimer;

  @override
  void initState() {
    initSpeechToText();
    super.initState();
  }

  @override
  void dispose() {
    onCancel();
    super.dispose();
  }

  void onCancel() {
    waveController.setAmplitude(0);
    amplitudeTimer?.cancel();
    speech.cancel();
    isListening = false;
  }

  void onStatus(String status) {
    setState(() {
      if (status == 'notListening') {
        onCancel();
      } else if (status == 'listening') {
        slowlySetAmplitude(0.2);
        isListening = true;
      }
    });
  }

  void finishRecording(String resultText) async {
    if (resultText.isNotEmpty) {
      final onFinish = widget.onFinish;
      if (onFinish != null) {
        onFinish(resultText);
      } else {
        var note = Note.empty(content: resultText);
        final noteUtils = ref.read(noteUtilsProvider);
        await noteUtils.handleSaveNote(context, note);
        Navigator.pop(context);
      }
    }
  }

  void onError(SpeechRecognitionError? e) {
    onCancel();
    setState(() {
      if (e != null) {
        errMsg = 'Failed with error message: $e';
      }
      errMsg = 'User has denied the use of speech recognition';
    });
  }

  void slowlySetAmplitude(double amplitude,
      {Duration duration = const Duration(milliseconds: 25),
      double increment = 0.05}) {
    amplitudeTimer?.cancel();
    amplitudeTimer = Timer.periodic(duration, (timer) {
      double currAmplitude = waveController.amplitude;
      if ((amplitude - currAmplitude).abs() < increment) {
        timer.cancel();
        waveController.setAmplitude(amplitude);
        if (amplitude == 1) {
          slowlySetAmplitude(0.2);
        }
      } else if (currAmplitude < amplitude) {
        waveController.setAmplitude(currAmplitude + increment);
      } else if (waveController.amplitude > amplitude) {
        waveController.setAmplitude(currAmplitude - increment);
      } else {
        timer.cancel();
      }
    });
  }

  void initSpeechToText() async {
    bool isReady =
        await speech.initialize(onStatus: onStatus, onError: onError);
    slowlySetAmplitude(0);
    if (isReady) {
      initListen();
    } else {
      onError(null);
    }
  }

  Future<void> initListen() async {
    await speech.listen(
      cancelOnError: true,
      pauseFor: const Duration(seconds: 5),
      onResult: (result) {
        setState(() {
          listenedText = result.recognizedWords;
        });
        if (result.finalResult) {
          slowlySetAmplitude(0);
          finishRecording(listenedText);
        } else {
          slowlySetAmplitude(1);
        }
      },
    );
  }

  List<Widget> getActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: (isListening) ? null : initListen,
        child: const Text('Record Again'),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    waveController.setColor(Theme.of(context).colorScheme.onSurface);
    var textStyle = Theme.of(context).textTheme.bodyMedium;
    // update wave
    return AlertDialog(
      title: const Text('Record New Note'),
      icon: const Icon(Icons.mic),
      actions: getActions(),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: (errMsg.isEmpty)
                    ? Text(
                        listenedText,
                        style: textStyle,
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        errMsg,
                        style: textStyle?.copyWith(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      )),
            SiriWave(
              controller: waveController,
              style: SiriWaveStyle.ios_7,
            ),
          ],
        ),
      ),
    );
  }
}

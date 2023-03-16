import 'dart:async';

import 'package:flutter/material.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class RecordDialog extends StatefulWidget {
  final bool listenOnInit;
  final Function(String)? onFinish;
  const RecordDialog({super.key, this.onFinish, this.listenOnInit = true});

  @override
  State<RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<RecordDialog> {
  SiriWaveController waveController =
      SiriWaveController(amplitude: 0.2, speed: 0.1);
  SpeechToText speech = SpeechToText();
  String listenedText = '';
  String errMsg = '';
  bool isListening = false;
  Timer? amplitudeTimer;

  @override
  void initState() {
    initSpeechToText();
    super.initState();
  }

  @override
  void dispose() {
    speech.cancel();
    amplitudeTimer?.cancel();
    super.dispose();
  }

  void onStatus(String status) {
    setState(() {
      if (status == 'notListening') {
        slowlySetAmplitude(0);
        speech.cancel();
        isListening = false;
        if (listenedText.isNotEmpty) {
          widget.onFinish?.call(listenedText);
        }
      } else if (status == 'listening') {
        slowlySetAmplitude(0.2);
        isListening = true;
      }
    });
  }

  void onError(SpeechRecognitionError? e) {
    slowlySetAmplitude(0);
    speech.cancel();
    amplitudeTimer?.cancel();
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
    if (isReady && widget.listenOnInit) {
      initListen();
    } else {
      onError(null);
    }
  }

  Future<void> initListen() async {
    await speech.listen(
      cancelOnError: true,
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        setState(() {
          listenedText = result.recognizedWords;
        });
        if (result.finalResult) {
          slowlySetAmplitude(0);
        } else {
          slowlySetAmplitude(1);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    waveController.setColor(Theme.of(context).colorScheme.onSurface);
    var textStyle = Theme.of(context).textTheme.bodyMedium;
    // update wave
    return AlertDialog(
      title: const Text('Record New Note'),
      icon: const Icon(Icons.mic),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (isListening) ? null : initListen,
          child: const Text('Record'),
        )
      ],
      content: Column(
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
    );
  }
}

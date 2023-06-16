import 'dart:async';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/foundation.dart';
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
  List<LocaleName> locales = [];
  String? currLocaleId;
  String listenedText = '';
  String errMsg = '';
  bool isListening = true;
  Timer? amplitudeTimer;

  @override
  void initState() {
    final settings = ref.read(settingsProvider);
    currLocaleId = settings.get('speech-to-text-locale');

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
    if (!mounted) return;
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
      }
    }
    if (mounted) Navigator.pop(context);
  }

  void onError(SpeechRecognitionError? e) {
    onCancel();
    if (!mounted) return;
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
    speech.locales().then((tempLocales) {
      if (!mounted) return;
      setState(() {
        locales = tempLocales;
      });
    });
    slowlySetAmplitude(0);
    if (isReady) {
      if (TargetPlatform.iOS == defaultTargetPlatform) {
        await Future.delayed(const Duration(seconds: 1));
      }
      initListen();
    } else {
      onError(null);
    }
  }

  Future<void> initListen() async {
    await speech.listen(
      localeId: currLocaleId,
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
        onPressed:
            (isListening) ? () => finishRecording(listenedText) : initListen,
        child:
            (isListening) ? const Text('Finish') : const Text('Record Again'),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    waveController.setColor(Theme.of(context).colorScheme.onSurface);
    var textStyle = Theme.of(context).textTheme.bodyMedium;
    // update wave
    return WillPopScope(
      onWillPop: () async {
        onCancel();
        return true;
      },
      child: AlertDialog(
        title: const Text('Record New Note'),
        icon: const Icon(Icons.mic),
        actions: getActions(),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding:
                        const EdgeInsets.only(top: 16, left: 16, right: 16),
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
                if (locales.isEmpty)
                  const DropdownMenu(
                    width: 200,
                    label: Text('Language'),
                    enabled: false,
                    dropdownMenuEntries: [],
                  )
                else
                  DropdownMenu<String?>(
                    width: 200,
                    initialSelection: currLocaleId,
                    label: const Text('Language'),
                    dropdownMenuEntries: [
                      const DropdownMenuEntry(value: null, label: '(Default)'),
                      ...locales.map((l) =>
                          DropdownMenuEntry(value: l.localeId, label: l.name))
                    ],
                    onSelected: (value) {
                      final settings = ref.read(settingsProvider);
                      currLocaleId = value;
                      settings.set('speech-to-text-locale', value);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ClickButtonWithDelay extends StatefulWidget {
  final VoidCallback onPressed;
  final String buttonText;

  const ClickButtonWithDelay({
    super.key,
    required this.onPressed,
    required this.buttonText,
  });

  @override
  _ClickButtonWithDelayState createState() => _ClickButtonWithDelayState();
}

class _ClickButtonWithDelayState extends State<ClickButtonWithDelay> {
  bool isButtonEnabled = true;

  void handleClick() {
    if (isButtonEnabled) {
      setState(() {
        isButtonEnabled = false;
      });

      widget.onPressed();

      Future.delayed(const Duration(seconds: 5), () {
        setState(() {
          isButtonEnabled = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isButtonEnabled ? handleClick : null,
      child: Text(widget.buttonText),
    );
  }
}

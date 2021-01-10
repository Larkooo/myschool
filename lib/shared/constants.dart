import 'package:flutter/material.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

// Not used anymore (for now)
final BoxDecoration mainBlueBtnDec =
    BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.blue);

TextButton textButton(BuildContext context, String text, Function onPressed) {
  return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
          overlayColor:
              MaterialStateColor.resolveWith((states) => Colors.transparent)),
      child:
          Text(text, style: TextStyle(color: Colors.blue[400], fontSize: 13)));
}

RoundedLoadingButton mainBlueLoadingBtn(
    BuildContext context,
    RoundedLoadingButtonController controller,
    String text,
    Function onPressed) {
  return RoundedLoadingButton(
      width: MediaQuery.of(context).size.width / 2.2,
      height: 50,
      animateOnTap: false,
      controller: controller,
      borderRadius: 15,
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
      onPressed: onPressed);
}

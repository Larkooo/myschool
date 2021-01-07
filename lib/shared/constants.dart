import 'package:flutter/material.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

// Not used anymore (for now)
final BoxDecoration mainBlueBtnDec =
    BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.blue);

RoundedLoadingButton mainBlueLoadingBtn(
    BuildContext context,
    RoundedLoadingButtonController controller,
    Widget child,
    Function onPressed) {
  return RoundedLoadingButton(
      width: MediaQuery.of(context).size.width / 2.2,
      height: 50,
      animateOnTap: false,
      controller: controller,
      borderRadius: 15,
      child: child,
      onPressed: onPressed);
}

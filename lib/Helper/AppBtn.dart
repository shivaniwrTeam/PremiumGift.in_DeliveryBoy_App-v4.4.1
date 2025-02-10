import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Color.dart';

class AppBtn extends StatelessWidget {
  final String? title;
  final AnimationController? btnCntrl;
  final Animation? btnAnim;
  final VoidCallback? onBtnSelected;
  const AppBtn({
    super.key,
    this.title,
    this.btnCntrl,
    this.btnAnim,
    this.onBtnSelected,
  });
  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      builder: _buildBtnAnimation,
      animation: btnCntrl!,
    );
  }

  Widget _buildBtnAnimation(
    final BuildContext context,
    final Widget? child,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 25,
      ),
      child: CupertinoButton(
        child: Container(
          width: btnAnim!.value,
          height: 45,
          alignment: FractionalOffset.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primarytheme,
            borderRadius: const BorderRadius.all(
              Radius.circular(
                10.0,
              ),
            ),
          ),
          child: btnAnim!.value > 75.0
              ? Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.white,
                        fontWeight: FontWeight.normal,
                      ),
                )
              : CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.white,
                  ),
                ),
        ),
        onPressed: () {
          onBtnSelected!();
        },
      ),
    );
  }
}

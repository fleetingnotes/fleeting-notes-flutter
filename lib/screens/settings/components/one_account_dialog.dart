import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:in_app_purchase/in_app_purchase.dart';

class OneAccountDialog extends StatelessWidget {
  const OneAccountDialog({
    Key? key,
    required this.onContinue,
    required this.onSeePricing,
    required this.userId,
    this.title = 'Logout of all other sessions',
  }) : super(key: key);

  final VoidCallback onContinue;
  final VoidCallback onSeePricing;
  final String userId;
  final String title;

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    // ignore: avoid_function_literals_in_foreach_calls
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {}
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    });
  }

  void oniOSSubscribe() async {
    var _kIds = {'fn_basic_plan'};
    var _iap = InAppPurchase.instance;
    final res = await _iap.queryProductDetails(_kIds);
    if (res.notFoundIDs.isEmpty) {
      var purchaseParam = PurchaseParam(
        productDetails: res.productDetails.first,
        applicationUserName: userId,
      );
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

      // listen for subscription to be complete
      var _subscription = _iap.purchaseStream.listen((purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      });
      _subscription.onDone(_subscription.cancel);
      _subscription.onError((_) => _subscription.cancel());
    }
  }

  List<Widget> getActionButtons() {
    if (!kIsWeb && Platform.isIOS) {
      return [
        TextButton(
          child: const Text('Continue'),
          onPressed: onContinue,
        ),
        ElevatedButton(
          child: const Text('Subscribe'),
          onPressed: oniOSSubscribe,
        ),
      ];
    } else if (!kIsWeb) {
      return [
        ElevatedButton(
          child: const Text('Continue'),
          onPressed: onContinue,
        ),
      ];
    } else {
      return [
        TextButton(
          child: const Text('Continue'),
          onPressed: onContinue,
        ),
        ElevatedButton(
          child: const Text('See Pricing'),
          onPressed: onSeePricing,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'As a free user, you can only log in with one account at a time.'),
          if (!kIsWeb && Platform.isIOS)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                  'Subscribe to the Basic Plan (\$3 / month):\n - Unlimited Logged in Devices\n - 25MB Attachment Limit'),
            )
        ],
      ),
      actions: getActionButtons(),
    );
  }
}

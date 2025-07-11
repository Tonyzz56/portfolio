import 'package:flutter/foundation.dart'; // For kDebugMode or custom logging
import 'package:cloud_functions/cloud_functions.dart'; // Import for HttpsCallable

class EmailService {
  // In a real application, these methods would interact with a backend service
  // or a Firebase Extension like "Trigger Email" to actually send emails.
  // For now, they will just print to the console for demonstration purposes.

  Future<void> sendSubscriptionWarningEmail({
    required String toEmail,
    required String institutionName,
    required String adminName,
    required DateTime expiryDate,
    required String renewalLink,
    required String supportEmail,
    required String platformName,
  }) async {
    final subject = "Your Subscription for $institutionName is Expiring Soon!";
    final body = """
Hi $adminName,

This is a friendly reminder that your subscription for $institutionName to our $platformName is due to expire on ${expiryDate.toIso8601String().substring(0, 10)}.

To ensure uninterrupted access to all features and services, please renew your subscription at your earliest convenience.
$renewalLink

If you have already renewed or have any questions, please feel free to contact our support team at $supportEmail.

Thank you for being a valued member of our community!

Sincerely,
The $platformName Team
""";

    if (kDebugMode) {
      print("--- EmailService: Sending Subscription Warning ---");
      print("To: $toEmail");
      print("Subject: $subject");
      print("Body:\n$body");
      print("-------------------------------------------------");
    }
    // TODO: Implement actual email sending logic here
    // e.g., via HTTPS call to a Cloud Function, or writing to a Firestore collection for Trigger Email extension.

    /*
    // Example for calling a Firebase Callable Function:
    // This would require setting up Firebase Functions and a callable function named 'sendTransactionalEmail'.
    try {
      // Ensure you have 'cloud_functions' package added to pubspec.yaml
      // final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'your-region').httpsCallable('sendTransactionalEmail');
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendTransactionalEmail');
      final response = await callable.call(<String, dynamic>{
        'to': toEmail,
        'templateName': 'subscriptionWarning', // Or pass subject/body directly
        'templateData': {
          'institutionName': institutionName,
          'adminName': adminName,
          'expiryDate': expiryDate.toIso8601String(),
          'renewalLink': renewalLink,
          'supportEmail': supportEmail,
          'platformName': platformName,
        },
        // You might also pass subject and text/html body directly if not using backend templates
        // 'subject': subject,
        // 'textBody': body,
      });
      if (kDebugMode) {
        print("Callable function 'sendTransactionalEmail' response: ${response.data}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error calling 'sendTransactionalEmail' (subscriptionWarning) function: $e");
      }
      // Optionally, rethrow or handle error for the calling service
    }
    */
  }

  Future<void> sendSubscriptionExpiredGracePeriodEmail({
    required String toEmail,
    required String institutionName,
    required String adminName,
    required DateTime expiryDate,
    required int gracePeriodDays,
    required DateTime gracePeriodEndDate,
    required String renewalLink,
    required String supportEmail,
    required String platformName,
    required String consequenceOfNonRenewal,
  }) async {
    final subject = "Action Required: Your Subscription for $institutionName Has Expired";
    final body = """
Hi $adminName,

Your subscription for $institutionName to our $platformName expired on ${expiryDate.toIso8601String().substring(0, 10)}.

We understand things can get busy, so we've placed your account into a grace period of $gracePeriodDays days, ending on ${gracePeriodEndDate.toIso8601String().substring(0, 10)}. During this time, you will continue to have full access to your services.

To avoid service interruption, please renew your subscription before ${gracePeriodEndDate.toIso8601String().substring(0, 10)}.
$renewalLink

If your subscription is not renewed by the end of the grace period, your account will be $consequenceOfNonRenewal.

If you need assistance or have any questions, please contact us at $supportEmail.

Sincerely,
The $platformName Team
""";
    if (kDebugMode) {
      print("--- EmailService: Sending Subscription Expired - Grace Period ---");
      print("To: $toEmail");
      print("Subject: $subject");
      print("Body:\n$body");
      print("-------------------------------------------------------------");
    }
    // TODO: Implement actual email sending logic
    /*
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendTransactionalEmail');
      final response = await callable.call(<String, dynamic>{
        'to': toEmail,
        'templateName': 'subscriptionExpiredGracePeriod',
        'templateData': {
          'institutionName': institutionName,
          'adminName': adminName,
          'expiryDate': expiryDate.toIso8601String(),
          'gracePeriodDays': gracePeriodDays,
          'gracePeriodEndDate': gracePeriodEndDate.toIso8601String(),
          'renewalLink': renewalLink,
          'supportEmail': supportEmail,
          'platformName': platformName,
          'consequenceOfNonRenewal': consequenceOfNonRenewal,
        },
      });
      if (kDebugMode) {
        print("Callable function 'sendTransactionalEmail' (gracePeriod) response: ${response.data}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error calling 'sendTransactionalEmail' (gracePeriod) function: $e");
      }
    }
    */
  }

  Future<void> sendSubscriptionSuspendedEmail({
    required String toEmail,
    required String institutionName,
    required String adminName,
    required DateTime suspensionDate,
    required String whatThisMeans, // Detailed explanation of consequences
    required String dataRetentionPeriod,
    required String renewalLink,
    required String supportEmail,
    required String platformName,
  }) async {
    final subject = "Important: Your $institutionName Account Has Been Suspended";
    final body = """
Hi $adminName,

This email is to inform you that your subscription for $institutionName to our $platformName has expired, and the grace period (if applicable) has ended. As a result, your account has been suspended, effective ${suspensionDate.toIso8601String().substring(0, 10)}.

What this means:
$whatThisMeans

Your data is safe and will be retained for $dataRetentionPeriod. You can reactivate your subscription and restore full access at any time by renewing.
$renewalLink

We'd love to have you back. If there's anything we can do to help, or if you have questions about your account status, please reach out to $supportEmail.

Sincerely,
The $platformName Team
""";
    if (kDebugMode) {
      print("--- EmailService: Sending Subscription Suspended ---");
      print("To: $toEmail");
      print("Subject: $subject");
      print("Body:\n$body");
      print("---------------------------------------------------");
    }
    // TODO: Implement actual email sending logic
    /*
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendTransactionalEmail');
      final response = await callable.call(<String, dynamic>{
        'to': toEmail,
        'templateName': 'subscriptionSuspended',
        'templateData': {
          'institutionName': institutionName,
          'adminName': adminName,
          'suspensionDate': suspensionDate.toIso8601String(),
          'whatThisMeans': whatThisMeans,
          'dataRetentionPeriod': dataRetentionPeriod,
          'renewalLink': renewalLink,
          'supportEmail': supportEmail,
          'platformName': platformName,
        },
      });
      if (kDebugMode) {
        print("Callable function 'sendTransactionalEmail' (suspended) response: ${response.data}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error calling 'sendTransactionalEmail' (suspended) function: $e");
      }
    }
    */
  }

  Future<void> sendSubscriptionReactivatedEmail({
    required String toEmail,
    required String institutionName,
    required String adminName,
    required DateTime newExpiryDate,
    required String packageName,
    required String accountDashboardLink,
    String? invoiceLink, // Optional
    required String platformName,
  }) async {
    final subject = "Your Subscription for $institutionName is Now Active!";
    final body = """
Hi $adminName,

Thank you for your payment! Your subscription for $institutionName to our $platformName has been successfully reactivated/renewed and is now active until ${newExpiryDate.toIso8601String().substring(0, 10)}.

You have full access to all features included in your $packageName package.

${invoiceLink != null ? "Invoice/Receipt: $invoiceLink" : ""}
Your Account: $accountDashboardLink

If you have any questions, please don't hesitate to contact us.

Welcome back!

Sincerely,
The $platformName Team
""";
    if (kDebugMode) {
      print("--- EmailService: Sending Subscription Reactivated ---");
      print("To: $toEmail");
      print("Subject: $subject");
      print("Body:\n$body");
      print("-----------------------------------------------------");
    }
    // TODO: Implement actual email sending logic
    /*
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendTransactionalEmail');
      final response = await callable.call(<String, dynamic>{
        'to': toEmail,
        'templateName': 'subscriptionReactivated',
        'templateData': {
          'institutionName': institutionName,
          'adminName': adminName,
          'newExpiryDate': newExpiryDate.toIso8601String(),
          'packageName': packageName,
          'accountDashboardLink': accountDashboardLink,
          'invoiceLink': invoiceLink,
          'platformName': platformName,
        },
      });
      if (kDebugMode) {
        print("Callable function 'sendTransactionalEmail' (reactivated) response: ${response.data}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error calling 'sendTransactionalEmail' (reactivated) function: $e");
      }
    }
    */
  }

  Future<void> sendPaymentFailedEmail({
    required String toEmail,
    required String institutionName,
    required String adminName,
    required DateTime expiryDate,
    required String updatePaymentLink,
    required String consequence, // e.g., "suspended" or "limited"
    required String supportEmail,
    required String platformName,
  }) async {
    final subject = "Action Required: Payment Failed for Your $institutionName Subscription Renewal";
    final body = """
Hi $adminName,

We encountered an issue processing the payment for the renewal of your subscription for $institutionName.
Your current subscription is set to expire on ${expiryDate.toIso8601String().substring(0,10)} (or has already expired).

Please update your payment information to ensure continued access:
$updatePaymentLink

If your payment information is not updated and payment is unsuccessful, your account may be $consequence.

If you believe this is an error or need assistance, please contact our support team immediately at $supportEmail.

Sincerely,
The $platformName Team
""";
     if (kDebugMode) {
      print("--- EmailService: Sending Payment Failed ---");
      print("To: $toEmail");
      print("Subject: $subject");
      print("Body:\n$body");
      print("-------------------------------------------");
    }
    // TODO: Implement actual email sending logic
    /*
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendTransactionalEmail');
      final response = await callable.call(<String, dynamic>{
        'to': toEmail,
        'templateName': 'paymentFailed',
        'templateData': {
          'institutionName': institutionName,
          'adminName': adminName,
          'expiryDate': expiryDate.toIso8601String(),
          'updatePaymentLink': updatePaymentLink,
          'consequence': consequence,
          'supportEmail': supportEmail,
          'platformName': platformName,
        },
      });
      if (kDebugMode) {
        print("Callable function 'sendTransactionalEmail' (paymentFailed) response: ${response.data}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error calling 'sendTransactionalEmail' (paymentFailed) function: $e");
      }
    }
    */
  }
}

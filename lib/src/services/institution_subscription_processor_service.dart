import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:school_management_system/src/models/institution_model.dart';
import 'package:school_management_system/src/models/user_model.dart'; // For User.contactEmail if needed (though institution should have it)
import 'package:school_management_system/src/models/batch_process_result_model.dart';
import 'package:school_management_system/src/services/email_service.dart'; // Placeholder email service
import 'package:school_management_system/src/services/auth_service.dart'; // To get admin user details for contact

// Configuration for subscription statuses - should match cloud function if both are used
const int GRACE_PERIOD_DAYS_CLIENT = 7;
const String PLATFORM_NAME = "EduVerse School Management"; // Example platform name for emails
const String SUPPORT_EMAIL = "support@eduverse.com";
const String RENEWAL_LINK = "https://eduverse.com/billing"; // Example link
const String DATA_RETENTION_POLICY = "90 days";


class InstitutionSubscriptionProcessorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final EmailService _emailService = EmailService(); // Using placeholder
  final AuthService _authService = AuthService(); // To fetch admin user details

  Future<BatchProcessResult> processAllInstitutions({Function(String message)? onProgress}) async {
    int totalProcessed = 0;
    int successfullyUpdated = 0;
    int emailsTriggered = 0;
    List<String> errors = [];

    onProgress?.call("Starting subscription processing...");

    try {
      final institutionsSnapshot = await _db.collection('institutions').get();
      if (institutionsSnapshot.docs.isEmpty) {
        onProgress?.call("No institutions found to process.");
        return BatchProcessResult(totalProcessed: 0, successfullyUpdated: 0, emailsTriggered: 0);
      }

      onProgress?.call("Fetched ${institutionsSnapshot.docs.length} institutions. Processing now...");

      WriteBatch batch = _db.batch();

      for (var doc in institutionsSnapshot.docs) {
        totalProcessed++;
        Institution institution;
        try {
          institution = Institution.fromMap(doc.data(), doc.id);
        } catch (e) {
          final errorMsg = "Error parsing institution data for ID ${doc.id}: $e";
          errors.add(errorMsg);
          onProgress?.call("Error: $errorMsg");
          continue;
        }

        onProgress?.call("Processing: ${institution.name} (ID: ${institution.id}), Current Status: ${institution.subscriptionStatus}");

        final String currentStatus = institution.subscriptionStatus;
        final DateTime? endDate = institution.subscriptionEndDate;
        String? newStatus;
        bool emailToSend = false;
        String emailType = ""; // To track which email to send

        if (endDate == null) {
          // If no end date, and not 'trial' or 'lapsed', perhaps mark as 'lapsed' or log warning.
          // This depends on business logic for institutions without explicit end dates.
          // For now, we skip if not in a state that expects an end date for expiry.
          if (currentStatus != 'trial' && currentStatus != 'lapsed' && currentStatus != 'suspended') {
             final String warningMsg = "Institution ${institution.name} (ID: ${institution.id}) has no subscriptionEndDate. Current status: $currentStatus. Skipping expiry checks.";
             onProgress?.call("Warning: $warningMsg");
             // errors.add(warningMsg); // Optionally treat as an error or just a log
          }
          continue;
        }

        final DateTime now = DateTime.now();
        final DateTime gracePeriodEndDate = endDate.add(const Duration(days: GRACE_PERIOD_DAYS_CLIENT));

        // --- Main Status Transition Logic (mirroring conceptual cloud function) ---
        if (currentStatus == "active" && now.isAfter(endDate)) {
          if (GRACE_PERIOD_DAYS_CLIENT > 0 && now.isBefore(gracePeriodEndDate)) {
            newStatus = "grace_period";
            emailType = "grace_period_started";
          } else {
            newStatus = "suspended";
            emailType = "suspended_direct";
          }
        } else if (currentStatus == "grace_period" && now.isAfter(gracePeriodEndDate)) {
          newStatus = "suspended";
          emailType = "suspended_after_grace";
        } else if (currentStatus == "trial" && now.isAfter(endDate)) {
          // Trial expired. Could go to 'lapsed', or a default free tier if you have one.
          // Or prompt for package selection. For now, 'lapsed'.
          newStatus = "lapsed";
          emailType = "trial_expired_lapsed";
        }
        // TODO: Add logic for X days before expiry warning emails if needed (would require checking dates in the future)
        // For example, if (endDate.difference(now).inDays <= 7 && endDate.difference(now).inDays > 0 && currentStatus == 'active') { ... send warning ... }

        if (newStatus != null && newStatus != currentStatus) {
          onProgress?.call("Updating ${institution.name} from '$currentStatus' to '$newStatus'.");
          batch.update(doc.reference, {
            'subscriptionStatus': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
            // 'lastStatusChecked': FieldValue.serverTimestamp(), // Optional field
          });
          successfullyUpdated++;
          emailToSend = true;
        }

        if (emailToSend) {
          // Fetch admin user for contact email
          UserModel? adminUser;
          String? contactEmail = institution.contactEmail; // Prefer institution's direct contact email

          if ((contactEmail == null || contactEmail.isEmpty) && institution.adminUserId.isNotEmpty) {
            try {
                adminUser = await _authService.getUserProfile(institution.adminUserId);
                contactEmail = adminUser?.email; // Fallback to admin user's email
            } catch(e) {
                final errorMsg = "Error fetching admin user ${institution.adminUserId} for ${institution.name}: $e";
                errors.add(errorMsg);
                onProgress?.call("Error: $errorMsg");
            }
          }

          if (contactEmail != null && contactEmail.isNotEmpty) {
            try {
              switch (emailType) {
                case "grace_period_started":
                  await _emailService.sendSubscriptionExpiredGracePeriodEmail(
                    toEmail: contactEmail,
                    institutionName: institution.name,
                    adminName: adminUser?.displayName ?? institution.name,
                    expiryDate: endDate,
                    gracePeriodDays: GRACE_PERIOD_DAYS_CLIENT,
                    gracePeriodEndDate: gracePeriodEndDate,
                    renewalLink: RENEWAL_LINK,
                    supportEmail: SUPPORT_EMAIL,
                    platformName: PLATFORM_NAME,
                    consequenceOfNonRenewal: "account suspension",
                  );
                  emailsTriggered++;
                  onProgress?.call("Grace period email triggered for ${institution.name}.");
                  break;
                case "suspended_direct":
                case "suspended_after_grace":
                  await _emailService.sendSubscriptionSuspendedEmail(
                    toEmail: contactEmail,
                    institutionName: institution.name,
                    adminName: adminUser?.displayName ?? institution.name,
                    suspensionDate: now,
                    whatThisMeans: "Access to premium features will be restricted. Core data might become read-only.",
                    dataRetentionPeriod: DATA_RETENTION_POLICY,
                    renewalLink: RENEWAL_LINK,
                    supportEmail: SUPPORT_EMAIL,
                    platformName: PLATFORM_NAME,
                  );
                  emailsTriggered++;
                  onProgress?.call("Suspension email triggered for ${institution.name}.");
                  break;
                case "trial_expired_lapsed":
                  // For trial expiry, you might send a different email or a variation of suspension
                  // This example reuses suspension for simplicity.
                   await _emailService.sendSubscriptionSuspendedEmail( // Or a specific "Trial Expired" email
                    toEmail: contactEmail,
                    institutionName: institution.name,
                    adminName: adminUser?.displayName ?? institution.name,
                    suspensionDate: now,
                    whatThisMeans: "Your trial period has ended. Access to features may be limited or disabled.",
                    dataRetentionPeriod: DATA_RETENTION_POLICY,
                    renewalLink: RENEWAL_LINK, // Link to choose a plan
                    supportEmail: SUPPORT_EMAIL,
                    platformName: PLATFORM_NAME,
                  );
                  emailsTriggered++;
                  onProgress?.call("Trial expired email triggered for ${institution.name}.");
                  break;
                // TODO: Add cases for warning emails
              }
            } catch (e) {
              final errorMsg = "Error triggering email for ${institution.name} (type: $emailType): $e";
              errors.add(errorMsg);
              onProgress?.call("Error: $errorMsg");
            }
          } else {
             final errorMsg = "No contact email found for ${institution.name} (ID: ${institution.id}). Cannot send $emailType email.";
             errors.add(errorMsg);
             onProgress?.call("Warning: $errorMsg");
          }
        }
      }

      if (successfullyUpdated > 0 || errors.isNotEmpty) { // Commit if there are updates or errors to log (even if updates fail, errors are important)
        await batch.commit();
        onProgress?.call("Batch commit successful. $successfullyUpdated institutions updated in Firestore.");
      } else {
        onProgress?.call("No institutions required status updates in Firestore.");
      }

    } catch (e, s) {
      final errorMsg = "Fatal error during subscription processing: $e\nStackTrace: $s";
      errors.add(errorMsg);
      onProgress?.call("FATAL ERROR: $errorMsg");
      if (kDebugMode) {
        print(errorMsg);
      }
    }

    onProgress?.call("Processing finished.");
    return BatchProcessResult(
      totalProcessed: totalProcessed,
      successfullyUpdated: successfullyUpdated,
      emailsTriggered: emailsTriggered,
      errors: errors,
    );
  }
}

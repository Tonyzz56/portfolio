import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

// Configuration for subscription statuses
const GRACE_PERIOD_DAYS = 7; // How many days after expiry before suspension
// const TRIAL_PERIOD_DAYS = 14; // If you have a trial period that auto-converts or expires

interface InstitutionData {
    id: string;
    name?: string;
    activeSubscriptionPackageId?: string;
    subscriptionStartDate?: admin.firestore.Timestamp;
    subscriptionEndDate?: admin.firestore.Timestamp;
    subscriptionStatus?: string;
    // Add other fields if needed for logging or decision making
}

export const checkInstitutionSubscriptions = functions.pubsub
  .schedule("every 24 hours") // Runs once a day. Adjust as needed: "every 1 hours", "every 5 minutes"
  .onRun(async (context) => {
    functions.logger.info("Starting scheduled subscription check for institutions.", {structuredData: true});

    const now = new Date();
    const institutionsRef = db.collection("institutions");

    try {
      const snapshot = await institutionsRef.get();
      if (snapshot.empty) {
        functions.logger.info("No institutions found to check.");
        return null;
      }

      const batch = db.batch();
      let institutionsProcessed = 0;
      let institutionsUpdated = 0;

      snapshot.forEach((doc) => {
        institutionsProcessed++;
        const institution = {id: doc.id, ...doc.data()} as InstitutionData;
        const institutionDocRef = institutionsRef.doc(doc.id);

        functions.logger.info(`Processing institution: ${institution.name || institution.id}`, {id: institution.id, currentStatus: institution.subscriptionStatus});

        const currentStatus = institution.subscriptionStatus;
        const endDate = institution.subscriptionEndDate?.toDate();

        if (!endDate) {
          functions.logger.warn(`Institution ${institution.id} has no subscriptionEndDate. Skipping.`, {id: institution.id});
          // Optionally, set to a default lapsed/trial status if this is unexpected
          // if (currentStatus !== 'trial' && currentStatus !== 'lapsed') {
          //   batch.update(institutionDocRef, { subscriptionStatus: 'lapsed', subscriptionNotes: 'Missing end date.' });
          //   institutionsUpdated++;
          // }
          return; // Skip this institution
        }

        const endDatePlusGrace = new Date(endDate);
        endDatePlusGrace.setDate(endDatePlusGrace.getDate() + GRACE_PERIOD_DAYS);

        let newStatus: string | null = null;

        // --- Main Status Transition Logic ---
        if (currentStatus === "active" && now > endDate) {
          // Subscription has just expired
          if (GRACE_PERIOD_DAYS > 0 && now <= endDatePlusGrace) {
            newStatus = "grace_period";
            functions.logger.info(`Institution ${institution.id} status changing from 'active' to 'grace_period'. End date: ${endDate.toISOString()}`, {id: institution.id});
          } else {
            newStatus = "suspended";
            functions.logger.info(`Institution ${institution.id} status changing from 'active' to 'suspended' (grace period skipped or passed). End date: ${endDate.toISOString()}`, {id: institution.id});
          }
        } else if (currentStatus === "grace_period" && now > endDatePlusGrace) {
          // Grace period has ended
          newStatus = "suspended";
          functions.logger.info(`Institution ${institution.id} status changing from 'grace_period' to 'suspended'. Grace end date: ${endDatePlusGrace.toISOString()}`, {id: institution.id});
        } else if (currentStatus === "trial") {
          // Handle trial expiry if applicable.
          // Example: if a trial is set by subscriptionEndDate and it expires.
          if (now > endDate) {
             // Decide if trial goes to 'lapsed', 'suspended', or requires package selection.
             // For now, let's assume it goes to 'lapsed' if no active package was set.
            newStatus = "lapsed";
            functions.logger.info(`Institution ${institution.id} trial expired, status changing to 'lapsed'. End date: ${endDate.toISOString()}`, {id: institution.id});
          }
        }
        // Add more transitions as needed, e.g., from 'suspended' to 'lapsed' after a longer period.

        // --- Payment Status Integration (Placeholder) ---
        // TODO: Implement payment check logic here.
        // If newStatus is 'active' (e.g. during renewal attempt) but payment failed,
        // it might revert to 'suspended' or 'grace_period'.
        // This function primarily handles expiry; payment processing might be a separate trigger or integrated here.
        // Example:
        // if (newStatus === 'active' && !(await hasPaidForNextTerm(institution.id))) {
        //   newStatus = 'suspended'; // Or 'payment_due'
        //   functions.logger.info(`Institution ${institution.id} payment failed/missing for renewal, moving to ${newStatus}.`, {id: institution.id});
        // }


        if (newStatus && newStatus !== currentStatus) {
          batch.update(institutionDocRef, {
            subscriptionStatus: newStatus,
            // Optionally, add a field like 'lastStatusUpdateReason' or 'subscriptionNotes'
            lastStatusChecked: admin.firestore.FieldValue.serverTimestamp(),
          });
          institutionsUpdated++;
          // --- Email Notification Trigger (Placeholder) ---
          // TODO: Trigger email notifications for status changes.
          // Example:
          // await sendSubscriptionStatusEmail(institution.id, newStatus, institution.contactEmail);
          // functions.logger.info(`Placeholder: Email notification for ${newStatus} to ${institution.id}.`);
        }
      });

      if (institutionsUpdated > 0) {
        await batch.commit();
        functions.logger.info(`Successfully processed ${institutionsProcessed} institutions. Updated ${institutionsUpdated} institutions.`);
      } else {
        functions.logger.info(`Successfully processed ${institutionsProcessed} institutions. No status updates were needed.`);
      }
    } catch (error) {
      functions.logger.error("Error checking institution subscriptions:", error);
      // Optionally, rethrow error or handle specific errors for retry logic if Pub/Sub supports it.
      // throw error;
    }
    return null; // Indicate successful completion to Pub/Sub
  });

// --- Placeholder for dependent functions (e.g., email or payment check) ---
// async function hasPaidForNextTerm(institutionId: string): Promise<boolean> {
//   // This would involve checking your payments collection or a payment gateway status
//   functions.logger.info(`Placeholder: Checking payment for institution ${institutionId}`);
//   return true; // Assume paid for now
// }

// async function sendSubscriptionStatusEmail(institutionId: string, newStatus: string, email?: string) {
//   // This would use an email service (e.g., SendGrid, Firebase Trigger Email extension)
//   if (!email) {
//     functions.logger.warn(`No contact email for institution ${institutionId} to send ${newStatus} notification.`);
//     return;
//   }
//   functions.logger.info(`Placeholder: Sending email to ${email} for institution ${institutionId} about new status: ${newStatus}.`);
//   // Actual email sending logic here
// }

// TODO:
// 1. Deploy this function to Firebase: `firebase deploy --only functions`
// 2. Set up necessary Firestore indexes if queries become complex or scale significantly.
//    For now, querying the 'institutions' collection without filters should be fine for moderate numbers.
// 3. Configure IAM permissions for the function's service account if it needs to access other Google Cloud services.
// 4. Monitor function logs in Google Cloud Console for errors and successful runs.
// 5. Flesh out payment checks and email notifications.
// 6. Consider edge cases: What if an institution is manually set to 'suspended' and its end date is in the future?
//    The current logic might try to "activate" it or move it to grace period if not handled.
//    The current logic primarily handles expiry-driven transitions from 'active' or 'trial'.
//    Manual overrides or other statuses might need explicit exclusion or handling in the conditions.
// 7. Ensure `subscriptionEndDate` is consistently stored as a Firestore Timestamp.
// 8. Add more robust error handling and retries if necessary for external API calls (payments, email).
// 9. For institutions with `subscriptionStatus: 'lapsed'` or `suspended`, this function currently doesn't change them further unless
//    their `subscriptionEndDate` is updated and they become `active` again through manual intervention/payment.
//    You might want a policy to move long-term `suspended` accounts to `lapsed`.
// 10. Make sure the `institutions` collection name is correct.
// 11. Test thoroughly with various institution states and dates.
// 12. The default `trial` status in `InstitutionModel` should have a `subscriptionEndDate` set for the trial period
//     for this function to correctly transition it to `lapsed` or another status.
//     If `subscriptionEndDate` is null for trials, they won't be processed by the current date check.
//     Alternatively, add specific logic for trials without end dates (e.g., based on `createdAt` + TRIAL_PERIOD_DAYS).
//
// Security Note: Ensure that this function is triggered by Pub/Sub and not publicly callable if it performs sensitive operations.
// The `onRun` trigger is appropriate for scheduled tasks.
// Firestore rules should still protect direct client access to institution statuses if clients are not supposed to modify them.
// This function runs with admin privileges to Firestore.

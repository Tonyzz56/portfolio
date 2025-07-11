// Conceptual Email Templates for Subscription Management

/*
Email sending in a Flutter app typically requires a backend service.
This can be:
1. Firebase Extensions like "Trigger Email" (uses Firestore to trigger emails).
2. A custom backend (e.g., Cloud Function written in JS/TS, or a Dart server using Alfred, Shelf, etc.)
   that integrates with an email provider like SendGrid, Mailgun, AWS SES.

These templates outline the content for emails. The actual sending mechanism
would be implemented in a service that calls an email provider's API or
writes to a Firestore collection monitored by the "Trigger Email" extension.
*/

// === 1. Subscription Expiry Warning ===
// Triggered: X days before subscriptionEndDate (e.g., 7 days, 3 days, 1 day)
// To: Institution Admin contact email

/*
Subject: Your Subscription for [InstitutionName] is Expiring Soon!

Hi [AdminName],

This is a friendly reminder that your subscription for [InstitutionName] to our School Management System is due to expire on [ExpiryDate].

To ensure uninterrupted access to all features and services, please renew your subscription at your earliest convenience.

[Link to Subscription Renewal Page / Billing Portal]

If you have already renewed or have any questions, please feel free to contact our support team at [SupportEmail] or visit our help center at [HelpCenterLink].

Thank you for being a valued member of our community!

Sincerely,
The [YourPlatformName] Team
*/

// === 2. Subscription Expired - Grace Period Started ===
// Triggered: On subscriptionEndDate if grace period is applicable
// To: Institution Admin contact email

/*
Subject: Action Required: Your Subscription for [InstitutionName] Has Expired

Hi [AdminName],

Your subscription for [InstitutionName] to our School Management System expired on [ExpiryDate].

We understand things can get busy, so we've placed your account into a grace period of [GracePeriodDays] days, ending on [GracePeriodEndDate]. During this time, you will continue to have full access to your services.

To avoid service interruption, please renew your subscription before [GracePeriodEndDate].

[Link to Subscription Renewal Page / Billing Portal]

If your subscription is not renewed by the end of the grace period, your account will be [Suspended/LimitedFeatureAccess - specify consequence].

If you need assistance or have any questions, please contact us at [SupportEmail].

Sincerely,
The [YourPlatformName] Team
*/

// === 3. Subscription Suspended / Lapsed (After Grace Period or Direct Expiry without Grace) ===
// Triggered: After grace period ends without renewal, or on expiry if no grace period.
// To: Institution Admin contact email

/*
Subject: Important: Your [InstitutionName] Account Has Been Suspended

Hi [AdminName],

This email is to inform you that your subscription for [InstitutionName] to our School Management System has expired, and the grace period (if applicable) has ended. As a result, your account has been suspended, effective [SuspensionDate].

What this means:
- Access to [Specify limited features, e.g., core data may be read-only, new entries disabled]
- Or [Full access has been restricted]
- [Other consequences]

Your data is safe and will be retained for [DataRetentionPeriod, e.g., 90 days]. You can reactivate your subscription and restore full access at any time by renewing.

[Link to Subscription Renewal Page / Billing Portal]

We'd love to have you back. If there's anything we can do to help, or if you have questions about your account status, please reach out to [SupportEmail].

Sincerely,
The [YourPlatformName] Team
*/


// === 4. Payment Successful / Subscription Renewed/Activated ===
// Triggered: After a successful payment and subscription (re)activation.
// To: Institution Admin contact email

/*
Subject: Your Subscription for [InstitutionName] is Now Active!

Hi [AdminName],

Thank you for your payment! Your subscription for [InstitutionName] to our School Management System has been successfully [Renewed/Activated] and is now active until [NewExpiryDate].

You have full access to all features included in your [PackageName] package.

Invoice/Receipt: [Link to Invoice/Receipt if applicable, or attached]
Your Account: [Link to Account Dashboard]

If you have any questions, please don't hesitate to contact us.

Welcome aboard / Welcome back!

Sincerely,
The [YourPlatformName] Team
*/

// === 5. Payment Failed for Renewal ===
// Triggered: If an automated renewal payment fails.
// To: Institution Admin contact email

/*
Subject: Action Required: Payment Failed for Your [InstitutionName] Subscription Renewal

Hi [AdminName],

We encountered an issue processing the payment for the renewal of your subscription for [InstitutionName].
Your current subscription is set to expire on [ExpiryDate] (or has expired on [ExpiryDate]).

Please update your payment information to ensure continued access:
[Link to Update Payment Method Page / Billing Portal]

If your payment information is not updated and payment is unsuccessful by [Date, e.g., end of grace period or expiry date], your account may be [Suspended/Limited].

If you believe this is an error or need assistance, please contact our support team immediately at [SupportEmail].

Sincerely,
The [YourPlatformName] Team
*/

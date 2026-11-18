1. Subscription Model Changes
Pricing Adjustments
Monthly Plan: Adjusted from $9.99 to $19.99.
Yearly Plan: Adjusted from $29.99 to $239.
Free Trial: 7 days for the yearly plan.
User Entitlements
Owner Account (developer@jobtrigger.app):
Role: Permanent Pro entitlement.
Billing: Never billed monthly or yearly.
Grant Type: Explicit grant tied to this email.
Tester Account (journey1@example.com):
Plan: Starts with Free plan.
Capabilities: Can upgrade/downgrade plans using real sandbox purchases (Apple/Google Play for mobile, Paddle for web).
All Other Accounts:
Default Plan: Free plan.
Capabilities: Can upgrade/downgrade plans using their respective payment channels.
2. User Stories
User Story 1: Permanent Pro Entitlement for the Owner Account
Description: The owner account (developer@jobtrigger.app) should always have a Pro subscription without being billed.
Acceptance Criteria:
The account is automatically granted Pro entitlement.
No billing occurs for this account.
The account retains all Pro features indefinitely.
User Story 2: Free Plan by Default for New Users
Description: All new accounts, except the owner and tester accounts, start with a Free plan.
Acceptance Criteria:
New users are assigned the Free plan upon account creation.
Users can upgrade to Pro using their preferred payment method.
User Story 3: Upgrade/Downgrade Functionality
Description: Users can upgrade from Free to Pro and downgrade from Pro to Free at any time.
Acceptance Criteria:
Users can seamlessly upgrade/downgrade through the app's billing interface.
Pro features remain active until the paid period expires for downgraded accounts.
User Story 4: Cross-Platform Payment Integration
Description: Users can pay using their preferred payment methods across platforms.
Acceptance Criteria:
Mobile users can pay via Apple Pay (iOS) or Google Play (Android).
Web users can pay via cards through Paddle.js.
No separate Apple Pay checkout is implemented for the app.
User Story 5: Web Checkout Restrictions for iOS Users
Description: iOS users cannot use web checkout links within the app.
Acceptance Criteria:
Web checkout is restricted to non-iOS users.
Compliance with App Review guidelines is ensured.
3. Technical Changes
Backend Adjustments
Pricing Tier Update:
Modify the backend to reflect the new pricing tiers.
Ensure the free trial logic is correctly applied to the yearly plan.
User Entitlement Logic:
Implement explicit grants for the owner account.
Ensure the tester account starts with a Free plan but can upgrade/downgrade using real sandbox payments.
Billing Integration:
Update the billing system to support the new pricing and payment methods.
Ensure secure handling of payment data.
Frontend Adjustments
User Interface Updates:
Update the subscription and billing screens to reflect the new pricing.
Ensure clear communication of the value proposition and benefits of each plan.
Cross-Platform Compliance:
Restrict web checkout links for iOS users in the app.
Ensure a seamless user experience for Android and web users.
4. Additional Considerations
Account Deletion:
Block account deletion while a paid subscription is active.
Provide clear instructions for users to cancel their subscription through the respective platform.
Admin Page:
Create an admin-facing page to grant, revoke, or inspect test subscriptions.
Ensure this remains an operational database/script-only action unless explicitly required.
Billing Support Screen:
Add a billing support screen showing:
Current plan.
Billing source.
Renewal date.
Cancellation state.
Invoice link (where available).
"Restore purchases" action.
Webhooks and Entitlements:
Implement webhooks for subscription events (renewal, cancellation, failed payments).
Ensure the backend remains the single source of truth for entitlements.
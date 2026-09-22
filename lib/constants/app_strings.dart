/// Central copy. The UI never hard-codes user-facing text.
abstract final class AppStrings {
  // App
  static const appName = 'Wallet';
  static const appTagline = 'DIGITAL WALLET RECHARGE';

  // Auth
  static const signIn = 'Sign in';
  static const signInSubtitle = 'Access your wallet panel';
  static const createAccount = 'Create account';
  static const createAccountSubtitle = 'Set up your wallet panel';
  static const email = 'Email';
  static const password = 'Password';
  static const fullName = 'Full name';
  static const confirmPassword = 'Confirm password';
  static const signInButton = 'Sign in';
  static const createButton = 'Create account';
  static const noAccount = 'New to Wallet?';
  static const haveAccount = 'Already have an account?';
  static const useDemo = 'Use demo account';
  static const demoHint = 'DEMO  ali@demo.com / demo1234';
  static const forgotPassword = 'Forgot password?';

  // Validation
  static const errEmailRequired = 'Enter your email address';
  static const errEmailInvalid = 'Enter a valid email address';
  static const errPasswordRequired = 'Enter your password';
  static const errPasswordShort = 'Use at least 6 characters';
  static const errNameRequired = 'Enter your full name';
  static const errConfirmMismatch = 'Passwords do not match';
  static const errAmountInvalid = 'Enter a whole amount from PKR 1 to 1,000,000';

  // Dashboard
  static const goodMorning = 'Good morning';
  static const goodAfternoon = 'Good afternoon';
  static const goodEvening = 'Good evening';
  static const walletBalance = 'WALLET BALANCE';
  static const live = 'LIVE';
  static const totalRecharged = 'TOTAL RECHARGED';
  static const transactions = 'TRANSACTIONS';
  static const recharge = 'RECHARGE';
  static const rechargeButton = 'Recharge wallet';
  static const recentActivity = 'Recent activity';
  static const viewAll = 'VIEW ALL';
  static const refreshed = 'Wallet synchronised';
  static const refreshFailed = 'Could not synchronise. Pull down to retry.';

  // Recharge
  static const rechargeTitle = 'Recharge wallet';
  static const currentBalance = 'CURRENT BALANCE';
  static const selectAmount = 'SELECT AMOUNT';
  static const custom = 'CUSTOM';
  static const customAmount = 'Enter amount (PKR)';
  static const continuePayment = 'Continue to payment';
  static const paymentSimulated = 'PAYFAST · SIMULATED';
  static const processingTitle = 'Processing payment';
  static const stepCreate = 'CREATING PAYMENT';
  static const stepConfirm = 'CONFIRMING WITH PAYFAST';
  static const stepVerify = 'VERIFYING PAYMENT';
  static const paymentSuccessTitle = 'Payment successful';
  static const paymentSuccessBody = 'Funds are being added to your wallet.';
  static const paymentDeclinedTitle = 'Payment declined';
  static const paymentDeclinedBody =
      'The payment was declined by the simulated gateway. Try a different amount or card.';
  static const paymentTimeoutTitle = 'Payment timed out';
  static const paymentTimeoutBody =
      'The gateway did not respond in time. Your balance was not changed.';
  static const retry = 'RETRY';
  static const cancel = 'CANCEL';
  static const done = 'DONE';
  static const transactionId = 'TRANSACTION ID';
  static const amount = 'AMOUNT';
  static const method = 'METHOD';
  static const walletCredited = 'Wallet credited';
  static const simHint =
      'DEMO RULES  500 / 1000 / 5000 / custom succeed · 9999 declines · 8888 times out';
  static const customRecharge = 'CUSTOM RECHARGE';

  // Transactions
  static const historyTitle = 'Transaction history';
  static const all = 'ALL';
  static const rechargeFilter = 'RECHARGE';
  static const chargeFilter = 'CHARGES';
  static const sortNewest = 'NEWEST';
  static const sortOldest = 'OLDEST';
  static const emptyTitle = 'No transactions';
  static const emptyBody =
      'Nothing matches this filter yet. Recharge your wallet to see entries here.';
  static const creditLabel = 'RECHARGE';
  static const debitLabel = 'SERVICE CHARGE';
  static const methodPayfast = 'PayFast';
  static const methodWallet = 'Wallet';

  // Profile
  static const profileTitle = 'Profile';
  static const memberSince = 'MEMBER SINCE';
  static const logout = 'Log out';
  static const logoutConfirmTitle = 'Log out of Wallet?';
  static const logoutConfirmBody = 'You will need to sign in again to access your panel.';
  static const logoutYes = 'LOG OUT';
  static const logoutNo = 'STAY';
  static const menuHistory = 'Transaction history';
  static const menuRecharge = 'Recharge wallet';
  static const menuSettings = 'Settings';
  static const menuAbout = 'About Wallet';

  // Settings
  static const settingsTitle = 'Settings';
  static const settingsNotifications = 'Notifications';
  static const settingsNotificationsBody = 'Payment and balance alerts';
  static const settingsBiometric = 'Biometric lock';
  static const settingsBiometricBody = 'Sign in with fingerprint or face';
  static const settingsDark = 'Night panel';
  static const settingsDarkBody = 'Fixed in this build';
  static const settingsDataSaver = 'Low-data mode';
  static const settingsDataSaverBody = 'Skip balance animations on metered networks';
  static const version = 'VERSION';
  static const aboutBody = 'Wallet — digital wallet recharge system.\n'
      'Internship prototype: Phase 1–2 (UI + simulated payments).\n'
      'Firebase, backend and PayFast sandbox land in later phases.';

  // Phone verification
  static const verifyPhoneTitle = 'VERIFY PHONE';
  static const verifyPhoneSubtitle =
      'Enter your mobile number to receive a verification code';
  static const phoneNumber = 'PHONE NUMBER';
  static const phoneHint = '0300 123 4567';
  static const sendCode = 'SEND CODE';
  static const otpTitle = 'ENTER CODE';
  static const otpSentTo = 'CODE SENT TO';
  static const verifyOtp = 'VERIFY';
  static const resendCode = 'Resend code in';
  static const resendNow = 'RESEND CODE';
  static const phoneVerified = 'Phone verified';
  static const phoneVerifiedBody = 'Redirecting to your panel...';
  static const phoneDemoHint = 'Demo: any 11-digit number works';
  static const errPhoneRequired = 'Enter your phone number';
  static const errPhoneInvalid = 'Enter a valid Pakistani mobile number';
  static const errOtpRequired = 'Enter the 6-digit code';
  static const errOtpInvalid = 'Enter a valid 6-digit code';
  static const errOtpFailed = 'Verification failed. Try again.';
  static const errTooManyRequests = 'Too many attempts. Wait a moment.';
  static const errQuotaExceeded = 'SMS quota exceeded. Try again later.';
  static const errInvalidPhone = 'Invalid phone number.';
  static const errSessionExpired = 'Code expired. Request a new one.';

  // Errors
  static const genericError = 'Something went wrong. Try again.';
}

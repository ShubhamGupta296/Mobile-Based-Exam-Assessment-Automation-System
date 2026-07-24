/// Shared validation for auth forms.
class AuthValidators {
  AuthValidators._();

  static String? validateGmailEmail(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    if (email.isEmpty) return 'Enter email';
    if (!email.endsWith('@gmail.com')) {
      return 'Only @gmail.com email addresses are allowed';
    }

    final regex = RegExp(r'^[a-z0-9._%+-]+@gmail\.com$');
    if (!regex.hasMatch(email)) {
      return 'Enter a valid Gmail address';
    }
    return null;
  }
}

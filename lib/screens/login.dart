import 'package:flutter/material.dart';
import 'user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================
  // LOGIN
  // =========================
  void login() {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final success = UserSession.login(
        userEmail: email,
        userPassword: password,
      );

      setState(() {
        isLoading = false;
      });

      if (success) {
        Navigator.pushReplacementNamed(context, '/main_shell');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password.')),
        );
      }
    });
  }

  // =========================
  // INPUT DECORATION
  // =========================
  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1E4D3B)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E4D3B), width: 1.5),
      ),
    );
  }

  // =========================
  // FORGOT PASSWORD
  // =========================
  void showForgotPassword() {
    final forgotEmailController = TextEditingController();
    final newPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F5F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4D3B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email and we will send you a password reset link.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: forgotEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: inputDecoration(
                      label: 'New Password',
                      icon: Icons.lock_outline,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final email = forgotEmailController.text.trim();
                        final newPassword = newPasswordController.text;

                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid email.'),
                            ),
                          );
                          return;
                        }

                        if (newPassword.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password must be at least 6 characters',
                              ),
                            ),
                          );
                          return;
                        }

                        final updated = UserSession.resetPassword(
                          userEmail: email,
                          newPassword: newPassword,
                        );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              updated
                                  ? 'Password reset link sent to $email'
                                  : 'No account found for this email.',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4D3B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // =========================
  // CREATE ACCOUNT
  // =========================
  void showCreateAccount() {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool passwordVisible = false;
    bool confirmPasswordVisible = false;
    bool acceptedTerms = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F5F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E4D3B),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Create your bookstore account.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: inputDecoration(
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name';
                          }

                          if (value.trim().length < 2) {
                            return 'Name is too short';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: inputDecoration(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          }

                          if (!RegExp(
                            r'^[^@]+@[^@]+\.[^@]+',
                          ).hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: inputDecoration(
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your phone number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: passwordController,
                        obscureText: !passwordVisible,
                        decoration: inputDecoration(
                          label: 'Password',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setModalState(() {
                                passwordVisible = !passwordVisible;
                              });
                            },
                            icon: Icon(
                              passwordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a password';
                          }

                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !confirmPasswordVisible,
                        decoration: inputDecoration(
                          label: 'Confirm Password',
                          icon: Icons.lock_reset_outlined,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setModalState(() {
                                confirmPasswordVisible =
                                    !confirmPasswordVisible;
                              });
                            },
                            icon: Icon(
                              confirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }

                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: acceptedTerms,
                        activeColor: const Color(0xFF1E4D3B),
                        title: const Text('I agree to the Terms & Conditions'),
                        onChanged: (value) {
                          setModalState(() {
                            acceptedTerms = value ?? false;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            if (!acceptedTerms) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please accept the Terms & Conditions.',
                                  ),
                                ),
                              );
                              return;
                            }

                            UserSession.register(
                              userName: nameController.text.trim(),
                              userEmail: emailController.text.trim(),
                              userPhone: phoneController.text.trim(),
                              userPassword: passwordController.text,
                            );

                            Navigator.pop(context);

                            Navigator.pushReplacementNamed(
                              this.context,
                              '/main_shell',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E4D3B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================
  // DEMO SOCIAL LOGIN
  // =========================
  void showDemoMessage(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider login is currently a demo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1E4D3B);
    const cream = Color(0xFFF5F5F0);

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _loginFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Center(
                      child: Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        'Sign in to continue to your bookstore',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: inputDecoration(
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email';
                        }

                        if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+',
                        ).hasMatch(value.trim())) {
                          return 'Enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: inputDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: showForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'Optional',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDemoMessage('Google');
                            },
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDemoMessage('Facebook');
                            },
                            icon: const Icon(Icons.facebook),
                            label: const Text('Facebook'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          GestureDetector(
                            onTap: showCreateAccount,
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                color: green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin_login');
                        },
                        child: const Text(
                          'Admin Portal',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

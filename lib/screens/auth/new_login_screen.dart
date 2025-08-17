import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/simple_auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  final String userType;

  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),

                // Back Button
                IconButton(
                  onPressed: () => context.go('/user-type'),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),

                SizedBox(height: 20.h),

                // Title Section
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Sign in as ${widget.userType == 'rider' ? 'Rider' : 'Driver'}',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                ),

                SizedBox(height: 40.h),

                // Login Form
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _usernameController,
                          label: 'Username',
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 24.h),

                        Consumer<SimpleAuthProvider>(
                          builder: (context, authProvider, child) {
                            return CustomButton(
                              text: 'Sign In',
                              onPressed: authProvider.isLoading ? null : _handleLogin,
                              isLoading: authProvider.isLoading,
                            );
                          },
                        ),

                        SizedBox(height: 16.h),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: TextStyle(
                                fontSize: 14.sp,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.go(
                                  '/signup?userType=${widget.userType}',
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    
    final success = await authProvider.signIn(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        final user = authProvider.currentUser!;
        
        // Navigate based on user type
        if (user.userType == 'rider') {
          context.go('/rider-home');
        } else {
          context.go('/driver-home');
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${user.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

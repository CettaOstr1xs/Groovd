import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/auth_service.dart';
import '../../../state/auth_providers.dart';
import '../../../state/dossier_top_picks_provider.dart';
import '../../../state/review_providers.dart';
import '../../../state/user_lists_provider.dart';
import '../../../state/user_profile_provider.dart';
import '../../../state/wishlist_provider.dart';
import '../../widgets/brutalist_button.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static Route<bool> route() {
    return MaterialPageRoute<bool>(
      builder: (_) => const LoginScreen(),
    );
  }

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _syncUserState(dynamic user) async {
    if (user == null) return;
    try {
      await ref.read(userProfileProvider.notifier).syncWithFirebaseUser(user);
      await ref.read(wishlistProvider.notifier).syncForUser(user.uid);
      await ref.read(dossierTopPicksProvider.notifier).syncForUser(user.uid);
      await ref.read(userListsProvider.notifier).syncForUser(user.uid);
      ref.invalidate(userReviewsProvider);
      ref.read(reviewRefreshProvider.notifier).notifyChanged();
    } catch (_) {}
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _syncUserState(credential.user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.acidLime,
            content: Text(
              'AUTHENTICATION SUCCESSFUL // WELCOME BACK',
              style: AppTypography.monoBadge(color: AppColors.pureBlack),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getHumanReadableError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithGoogle();

      if (credential != null && mounted) {
        await _syncUserState(credential.user);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.acidLime,
            content: Text(
              'GOOGLE AUTHENTICATION VERIFIED // DOSSIER SYNCED',
              style: AppTypography.monoBadge(color: AppColors.pureBlack),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getHumanReadableError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: AppColors.pureBlack, width: 2),
          ),
          title: Text(
            'RESET PASSWORD',
            style: AppTypography.displaySmall(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your critic account email to receive a password reset briefing link.',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.headline(color: AppColors.textPrimary, fontSize: 14),
                cursorColor: AppColors.acidLime,
                decoration: const InputDecoration(
                  labelText: 'EMAIL ADDRESS',
                  prefixIcon: Icon(Icons.alternate_email, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'CANCEL',
                style: AppTypography.monoBadge(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.acidLime,
                foregroundColor: AppColors.pureBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              onPressed: isResetting
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        return;
                      }
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      setDialogState(() => isResetting = true);
                      try {
                        await ref.read(authServiceProvider).sendPasswordResetEmail(email);
                        if (ctx.mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.acidLime,
                              content: Text(
                                'PASSWORD RESET EMAIL SENT // CHECK INBOX',
                                style: AppTypography.monoBadge(color: AppColors.pureBlack),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() => isResetting = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.vermillion,
                              content: Text(
                                AuthService.getHumanReadableError(e),
                                style: AppTypography.monoBadge(color: AppColors.pureWhite),
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: isResetting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pureBlack),
                    )
                  : Text(
                      'SEND RESET LINK',
                      style: AppTypography.monoBadge(color: AppColors.pureBlack),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('SYSTEM // ACCESS', style: AppTypography.displaySmall()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Neo-Brutalist Badge Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.acidLime,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.pureBlack, width: 1.5),
                  ),
                  child: Text(
                    'CRITIC PORTAL // AUTHENTICATION',
                    style: AppTypography.monoBadge(
                      color: AppColors.pureBlack,
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title & Subtitle
                Text(
                  'LOG IN TO GROOVD',
                  style: AppTypography.displayMassive().copyWith(fontSize: 28, height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Retain and synchronize your album ratings, reviews, wantlist, and critic profile across devices.',
                  style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.vermillion.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.vermillion, width: 2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.vermillion),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.monoBadge(
                              color: AppColors.vermillion,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Email Input
                Text(
                  'CRITIC EMAIL',
                  style: AppTypography.monoLabel(color: AppColors.textPrimary, fontSize: 11),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.headline(color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.acidLime,
                  decoration: const InputDecoration(
                    hintText: 'critic@groovd.fm',
                    prefixIcon: Icon(Icons.alternate_email, color: AppColors.textSecondary, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'ENTER YOUR EMAIL ADDRESS';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'ENTER A VALID EMAIL ADDRESS';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PASSWORD',
                      style: AppTypography.monoLabel(color: AppColors.textPrimary, fontSize: 11),
                    ),
                    GestureDetector(
                      onTap: _showForgotPasswordDialog,
                      child: Text(
                        'FORGOT PASSWORD?',
                        style: AppTypography.monoBadge(color: AppColors.cyberCyan, fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTypography.headline(color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.acidLime,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'ENTER YOUR PASSWORD';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Log In Button
                BrutalistButton(
                  label: _isLoading ? 'AUTHENTICATING...' : 'LOG IN // AUTHENTICATE',
                  icon: _isLoading ? null : Icons.login,
                  isFullWidth: true,
                  backgroundColor: AppColors.acidLime,
                  textColor: AppColors.pureBlack,
                  borderColor: AppColors.pureBlack,
                  onPressed: (_isLoading || _isGoogleLoading) ? null : _handleEmailLogin,
                ),
                const SizedBox(height: 20),

                // Neo-Brutalist Divider: // OR //
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '// OR //',
                        style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Sign In Button
                InkWell(
                  onTap: (_isLoading || _isGoogleLoading) ? null : _handleGoogleLogin,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.pureBlack, width: 2),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.pureBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: _isGoogleLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.pureWhite,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'G',
                                  style: AppTypography.monoBadge(
                                    color: AppColors.pureBlack,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'CONTINUE WITH GOOGLE',
                                style: AppTypography.monoBadge(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // Switch to Register Screen
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTypography.bodyMedium(),
                          children: [
                            const TextSpan(
                              text: 'NEW TO GROOVD? ',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextSpan(
                              text: 'CREATE CRITIC ACCOUNT →',
                              style: TextStyle(
                                color: AppColors.acidLime,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Continue as guest
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'CONTINUE AS GUEST // OFFLINE MODE',
                      style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

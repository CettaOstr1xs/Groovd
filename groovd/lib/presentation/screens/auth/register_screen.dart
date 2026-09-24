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
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static Route<bool> route() {
    return MaterialPageRoute<bool>(
      builder: (_) => const RegisterScreen(),
    );
  }

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Prefill with current critic identity if available
    final profile = ref.read(userProfileProvider);
    if (profile.userName != 'CRITIC // YOU' && profile.userName.isNotEmpty) {
      _nameController.text = profile.userName;
    }
    if (profile.userHandle != '@groovd_me' && profile.userHandle.isNotEmpty) {
      _handleController.text = profile.userHandle;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _syncUserState(dynamic user, {String? customName, String? customHandle}) async {
    if (user == null) return;
    try {
      await ref.read(userProfileProvider.notifier).syncWithFirebaseUser(user);
      if (customName != null || customHandle != null) {
        final current = ref.read(userProfileProvider);
        await ref.read(userProfileProvider.notifier).updateCriticIdentity(
          name: customName ?? current.userName,
          handle: customHandle ?? current.userHandle,
        );
      }
      await ref.read(wishlistProvider.notifier).syncForUser(user.uid);
      await ref.read(dossierTopPicksProvider.notifier).syncForUser(user.uid);
      await ref.read(userListsProvider.notifier).syncForUser(user.uid);
      ref.invalidate(userReviewsProvider);
      ref.read(reviewRefreshProvider.notifier).notifyChanged();
    } catch (_) {}
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'PASSWORDS DO NOT MATCH';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        criticName: _nameController.text.trim(),
        criticHandle: _handleController.text.trim(),
      );

      await _syncUserState(
        credential.user,
        customName: _nameController.text.trim().toUpperCase(),
        customHandle: _handleController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.acidLime,
            content: Text(
              'CRITIC DOSSIER ENROLLED // CLOUD SYNC ACTIVE',
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

  Future<void> _handleGoogleSignIn() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.pureWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CRITIC ENROLLMENT',
          style: AppTypography.monoBadge(fontSize: 12),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Dossier Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.acidLime,
                        border: Border.all(color: AppColors.pureBlack, width: 1.5),
                      ),
                      child: Text(
                        'DOSSIER // GRV-ENROLL',
                        style: AppTypography.monoBadge(
                          color: AppColors.pureBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: AppColors.pureWhite.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Headline
                Text(
                  'CREATE YOUR\nCRITIC DOSSIER',
                  style: AppTypography.displayHero(
                    color: AppColors.pureWhite,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Establish your identity. Sync reviews, ratings, wantlist, and custom lists across devices with Cloud Firestore.',
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pureBlack,
                      border: Border.all(color: Colors.redAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.redAccent,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.monoLabel(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Critic Display Name Input
                Text(
                  'CRITIC DISPLAY NAME',
                  style: AppTypography.monoLabel(
                    color: AppColors.acidLime,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: AppTypography.bodyMedium(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: 'Your Display Name',
                    hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.acidLime, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ENTER YOUR CRITIC DISPLAY NAME';
                    }
                    if (value.trim().length < 2) {
                      return 'NAME MUST BE AT LEAST 2 CHARACTERS';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Critic Handle Input
                Text(
                  'CRITIC HANDLE (OPTIONAL)',
                  style: AppTypography.monoLabel(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _handleController,
                  style: AppTypography.bodyMedium(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: '@Your_Handle',
                    hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    prefixIcon: const Icon(Icons.alternate_email, color: AppColors.textSecondary, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.acidLime, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Address Input
                Text(
                  'EMAIL ADDRESS',
                  style: AppTypography.monoLabel(
                    color: AppColors.acidLime,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyMedium(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: 'critic@groovd.fm',
                    hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textSecondary, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.acidLime, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ENTER YOUR EMAIL ADDRESS';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'ENTER A VALID EMAIL ADDRESS';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Input
                Text(
                  'PASSWORD (MIN 6 CHARS)',
                  style: AppTypography.monoLabel(
                    color: AppColors.acidLime,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTypography.bodyMedium(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.acidLime, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ENTER A PASSWORD';
                    }
                    if (value.length < 6) {
                      return 'PASSWORD MUST BE AT LEAST 6 CHARACTERS';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Input
                Text(
                  'CONFIRM PASSWORD',
                  style: AppTypography.monoLabel(
                    color: AppColors.acidLime,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: AppTypography.bodyMedium(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.pureWhite.withValues(alpha: 0.2), width: 1.5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.acidLime, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'CONFIRM YOUR PASSWORD';
                    }
                    if (value != _passwordController.text) {
                      return 'PASSWORDS DO NOT MATCH';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Register Submit Button
                BrutalistButton(
                  label: _isLoading ? 'ENROLLING DOSSIER...' : 'REGISTER // ENROLL DOSSIER',
                  onPressed: (_isLoading || _isGoogleLoading) ? null : _handleRegister,
                  icon: _isLoading ? null : Icons.how_to_reg_outlined,
                  backgroundColor: AppColors.acidLime,
                  textColor: AppColors.pureBlack,
                  borderColor: AppColors.pureBlack,
                  isFullWidth: true,
                ),
                const SizedBox(height: 24),

                // Divider: OR
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.pureWhite.withValues(alpha: 0.15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '// OR ENROLL WITH //',
                        style: AppTypography.monoLabel(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.pureWhite.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Sign In Button
                InkWell(
                  onTap: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.pureWhite, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.pureWhite,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pureWhite,
                              ),
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
                                  color: AppColors.pureWhite,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // Switch to Login Screen
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                              text: 'ALREADY HAVE A DOSSIER? ',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextSpan(
                              text: 'LOG IN →',
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

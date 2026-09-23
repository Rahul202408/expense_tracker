import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/security_service.dart';
import '../../providers/pro_provider.dart';
import '../../widgets/three_d_tilt_card.dart';
import '../auth/app_lock_screen.dart';
import '../pro/pro_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService();
  bool _isAppLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricSupported = false;
  String? _currentPin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final lockEnabled = await _securityService.isAppLockEnabled();
    final bioEnabled = await _securityService.isBiometricEnabled();
    final bioSupported = await _securityService.isBiometricAvailable();
    final pin = await _securityService.getPin();

    if (mounted) {
      setState(() {
        _isAppLockEnabled = lockEnabled;
        _isBiometricEnabled = bioEnabled;
        _isBiometricSupported = bioSupported;
        _currentPin = pin;
        _isLoading = false;
      });
    }
  }

  void _showProPaywall() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff0F172A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xffF59E0B), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffF59E0B).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xffF59E0B), size: 24),
              ),
              const SizedBox(width: 10),
              Text(
                "PRO Feature",
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xff1E293B),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            "App Lock & Biometric security is exclusive to Expense Tracker PRO members.\n\nUpgrade to PRO to lock your financial records with Fingerprint, Face ID & PIN, enjoy 100% ad-free experience, and export unlimited PDF reports!",
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xff475569),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Maybe Later",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProScreen()),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 18, color: Colors.black),
                  SizedBox(width: 6),
                  Text(
                    "Unlock PRO 👑",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleAppLock(bool value) async {
    final proProvider = Provider.of<ProProvider>(context, listen: false);
    if (!proProvider.isPro) {
      _showProPaywall();
      return;
    }

    if (value && (_currentPin == null || _currentPin!.length != 4)) {
      // Must set PIN first
      _showSetPinDialog(onSuccess: () async {
        await _securityService.setAppLockEnabled(true);
        setState(() {
          _isAppLockEnabled = true;
        });
      });
    } else {
      await _securityService.setAppLockEnabled(value);
      setState(() {
        _isAppLockEnabled = value;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final proProvider = Provider.of<ProProvider>(context, listen: false);
    if (!proProvider.isPro) {
      _showProPaywall();
      return;
    }
    if (value) {
      // Test biometric authentication before enabling
      final success = await _securityService.authenticateWithBiometrics(
        reason: "Authenticate to enable Fingerprint / Face Unlock",
      );

      if (success) {
        await _securityService.setBiometricEnabled(true);
        setState(() {
          _isBiometricEnabled = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fingerprint / Face Unlock Enabled!"),
              backgroundColor: Colors.teal,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometric Authentication Failed."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      await _securityService.setBiometricEnabled(false);
      setState(() {
        _isBiometricEnabled = false;
      });
    }
  }

  void _showSetPinDialog({VoidCallback? onSuccess}) {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff11998E).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pin_rounded, color: Color(0xff11998E)),
              ),
              const SizedBox(width: 10),
              Text(
                _currentPin == null ? "Set Security PIN" : "Change Security PIN",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: "Enter 4-Digit PIN",
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.length != 4 || int.tryParse(val) == null) {
                      return "Please enter a valid 4-digit PIN";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: "Confirm 4-Digit PIN",
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                  validator: (val) {
                    if (val != pinController.text) {
                      return "PINs do not match";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff11998E),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _securityService.setPin(pinController.text);
                  setState(() {
                    _currentPin = pinController.text;
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Security PIN Saved Successfully!"),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }

                  if (onSuccess != null) onSuccess();
                }
              },
              child: const Text("Save PIN"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final proProvider = Provider.of<ProProvider>(context);
    final isPro = proProvider.isPro;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xff1A202C);
    final cardBgColor = isDark ? const Color(0xff1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Security & App Lock",
          style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // VIP PRO Upgrade Banner (if free)
                  if (!isPro)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff1E293B), Color(0xff0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xffF59E0B).withValues(alpha: 0.6),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffF59E0B).withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xffF59E0B).withValues(alpha: 0.2),
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Color(0xffF59E0B),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "PRO Exclusive Feature",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "App Lock and Biometric security are available exclusively for PRO members. Upgrade now to secure your personal finances with Fingerprint, Face ID & 4-Digit PIN.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffF59E0B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProScreen()),
                                );
                              },
                              icon: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.black,
                                size: 18,
                              ),
                              label: const Text(
                                "Unlock PRO to Enable Lock 👑",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Super 3D Security Shield Header Card
                  ThreeDTiltCard(
                    maxTiltAngle: 0.06,
                    elevation: isDark ? 6 : 10,
                    margin: const EdgeInsets.only(bottom: 24),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xff0F2027),
                                  const Color(0xff203A43),
                                  const Color(0xff2C5364),
                                ]
                              : [
                                  const Color(0xff11998E),
                                  const Color(0xff38EF7D),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "App Protection",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  !isPro
                                      ? "🔒 PRO Member Only"
                                      : (_isAppLockEnabled
                                          ? "🔒 Security Protection Active"
                                          : "🔓 Protection Disabled"),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Setting Tiles Container
                  Container(
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // App Lock Switch
                        SwitchListTile(
                          value: isPro && _isAppLockEnabled,
                          onChanged: _toggleAppLock,
                          activeColor: const Color(0xff11998E),
                          title: const Text(
                            "Enable App Lock",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isPro
                                ? "Require PIN or Biometrics to open app"
                                : "Exclusive to PRO members",
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xff11998E),
                          ),
                        ),

                        const Divider(height: 1),

                        // PIN Lock Tile
                        ListTile(
                          onTap: () {
                            if (!isPro) {
                              _showProPaywall();
                            } else {
                              _showSetPinDialog();
                            }
                          },
                          leading: const Icon(
                            Icons.password_rounded,
                            color: Color(0xff00B4DB),
                          ),
                          title: Text(
                            _currentPin == null ? "Set Security PIN" : "Change Security PIN",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            !isPro
                                ? "PRO Required"
                                : (_currentPin == null ? "Not configured" : "4-Digit PIN Configured"),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ),

                        const Divider(height: 1),

                        // Fingerprint & Face Unlock Switch
                        SwitchListTile(
                          value: isPro && _isBiometricEnabled,
                          onChanged: isPro && _isBiometricSupported ? _toggleBiometrics : (_) => _showProPaywall(),
                          activeColor: const Color(0xff38EF7D),
                          title: const Text(
                            "Fingerprint / Face Unlock",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            !isPro
                                ? "PRO Required"
                                : (_isBiometricSupported
                                    ? "Use biometrics for fast login"
                                    : "Not supported on this device"),
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: Icon(
                            Icons.fingerprint_rounded,
                            color: isPro && _isBiometricSupported
                                ? const Color(0xff38EF7D)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Test App Lock Button
                  if (isPro && _isAppLockEnabled)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff11998E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.vibration_rounded),
                      label: const Text(
                        "Test App Lock Screen",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppLockScreen(
                              onSuccess: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("App Lock Verification Passed!"),
                                    backgroundColor: Colors.teal,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

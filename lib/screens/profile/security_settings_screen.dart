import 'package:flutter/material.dart';
import '../../services/security_service.dart';
import '../../widgets/three_d_tilt_card.dart';
import '../auth/app_lock_screen.dart';

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

  Future<void> _toggleAppLock(bool value) async {
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
                                  _isAppLockEnabled
                                      ? "🔒 Security Protection Active"
                                      : "🔓 Protection Disabled",
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
                          value: _isAppLockEnabled,
                          onChanged: _toggleAppLock,
                          activeColor: const Color(0xff11998E),
                          title: const Text(
                            "Enable App Lock",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            "Require PIN or Biometrics to open app",
                            style: TextStyle(fontSize: 12),
                          ),
                          secondary: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xff11998E),
                          ),
                        ),

                        const Divider(height: 1),

                        // PIN Lock Tile
                        ListTile(
                          onTap: () => _showSetPinDialog(),
                          leading: const Icon(
                            Icons.password_rounded,
                            color: Color(0xff00B4DB),
                          ),
                          title: Text(
                            _currentPin == null ? "Set Security PIN" : "Change Security PIN",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _currentPin == null ? "Not configured" : "4-Digit PIN Configured",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ),

                        const Divider(height: 1),

                        // Fingerprint & Face Unlock Switch
                        SwitchListTile(
                          value: _isBiometricEnabled,
                          onChanged: _isBiometricSupported ? _toggleBiometrics : null,
                          activeColor: const Color(0xff38EF7D),
                          title: const Text(
                            "Fingerprint / Face Unlock",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _isBiometricSupported
                                ? "Use biometrics for fast login"
                                : "Not supported on this device",
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: Icon(
                            Icons.fingerprint_rounded,
                            color: _isBiometricSupported
                                ? const Color(0xff38EF7D)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Test App Lock Button
                  if (_isAppLockEnabled)
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

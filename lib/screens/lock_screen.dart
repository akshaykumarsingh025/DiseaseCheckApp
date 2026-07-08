import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

class LockScreen extends StatefulWidget {
  final Widget child;

  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialLock() async {
    final shouldLock = await AppLockService.shouldShowLock();
    final lockType = await AppLockService.getLockType();
    if (lockType != null && shouldLock) {
      setState(() => _isLocked = true);
      _authenticate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AppLockService.recordBackgroundTime();
    } else if (state == AppLifecycleState.resumed) {
      _checkAndShowLock();
    }
  }

  Future<void> _checkAndShowLock() async {
    final shouldLock = await AppLockService.shouldShowLock();
    if (shouldLock && !_isLocked && !_isAuthenticating) {
      setState(() => _isLocked = true);
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final lockType = await AppLockService.getLockType();
    if (lockType == 'biometric') {
      final success = await AppLockService.authenticate();
      if (success && mounted) {
        await AppLockService.clearBackgroundTime();
        setState(() {
          _isLocked = false;
          _isAuthenticating = false;
        });
      } else {
        setState(() => _isAuthenticating = false);
      }
    } else if (lockType == 'pin') {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) return widget.child;

    final lockType = FutureBuilder<String?>(
      future: AppLockService.getLockType(),
      builder: (context, snapshot) {
        final type = snapshot.data;
        if (type == 'pin') return _buildPinPad();
        return _buildBiometricPrompt();
      },
    );

    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          Container(
            color: Colors.black.withValues(alpha: 0.95),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 64, color: Colors.indigo.shade300),
                      const SizedBox(height: 24),
                      const Text(
                        'Health Check is Locked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Authenticate to access your health data',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      lockType,
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBiometricPrompt() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isAuthenticating ? null : _authenticate,
          icon: const Icon(Icons.fingerprint),
          label: const Text('Authenticate'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
        ),
      ],
    );
  }

  final _pinInput = StringBuffer();
  String _pinError = '';

  Widget _buildPinPad() {
    return StatefulBuilder(
      builder: (context, setPadState) {
        final dots = List.generate(4, (i) {
          return Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pinInput.length
                  ? Colors.indigo
                  : Colors.white24,
            ),
          );
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: dots),
            if (_pinError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_pinError,
                  style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            ..._buildPinRows(setPadState),
          ],
        );
      },
    );
  }

  List<Widget> _buildPinRows(StateSetter setPadState) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return keys.map((row) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 72, height: 72);
            }
            if (key == '⌫') {
              return IconButton(
                onPressed: () {
                  setPadState(() {
                    if (_pinInput.isNotEmpty) _pinInput.clear();
                    _pinError = '';
                  });
                },
                icon: const Icon(Icons.backspace_outlined, color: Colors.white54),
                iconSize: 28,
                style: IconButton.styleFrom(
                  minimumSize: const Size(72, 72),
                ),
              );
            }
            return IconButton(
              onPressed: () async {
                setPadState(() {
                  _pinInput.write(key);
                  _pinError = '';
                });

                if (_pinInput.length >= 4) {
                  final pin = _pinInput.toString();
                  final correct = await AppLockService.verifyPin(pin);
                  if (correct && mounted) {
                    await AppLockService.clearBackgroundTime();
                    setState(() {
                      _isLocked = false;
                    });
                    _pinInput.clear();
                  } else {
                    setPadState(() {
                      _pinError = 'Incorrect PIN';
                      _pinInput.clear();
                    });
                  }
                }
              },
              icon: Text(key,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
              style: IconButton.styleFrom(
                minimumSize: const Size(72, 72),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36),
                    side: const BorderSide(color: Colors.white24)),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }
}

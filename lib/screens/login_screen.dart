import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'root_router_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = AuthService();
  bool _linkSent = false;
  bool _loading = false;

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.sendMagicLink(_emailController.text.trim());
      setState(() => _linkSent = true);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Keeps the form from stretching edge-to-edge on wide desktop
          // windows, while staying full-width on phones.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.favorite, size: 56, color: AppTheme.coral, semanticLabel: 'Pair'),
                    const SizedBox(height: 12),
                    Text('Pair', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    const Text('A private space for the two of you.', textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    if (!_linkSent) ...[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        // Form validation, per pre-launch checklist —
                        // catches obvious typos before hitting the network.
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Enter your email.';
                          if (!AuthService.isValidEmail(value)) return "That doesn't look like a valid email.";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _sendLink,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Send me a login link'),
                      ),
                    ] else ...[
                      const Icon(Icons.mark_email_read_outlined, size: 40),
                      const SizedBox(height: 12),
                      const Text('Check your inbox — tap the link we sent you to finish signing in.', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        maxLength: 40,
                        decoration: const InputDecoration(labelText: "Your name (shown to your partner)"),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          await _auth.ensureProfile(_nameController.text.trim().isEmpty ? 'Someone' : _nameController.text.trim());
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RootRouterScreen()));
                          }
                        },
                        child: const Text("I've clicked the link — continue"),
                      ),
                    ],
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

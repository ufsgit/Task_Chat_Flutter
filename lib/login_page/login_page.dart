import 'package:flutter/material.dart';
import '../bottom_navigator/bottom_navigator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter both username and password',
            style: TextStyle(color: Colors.red),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BottomNavigator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      body: GestureDetector(
        // Dismiss mobile keyboard on tap outside
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo with Badge
                        const _TaskChatLogo(),
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'TaskChat',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B192C),
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'Seamless team messaging & task flow',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Login Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 26.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24.0),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username Label
                              const Text(
                                'Username',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Username Input Field
                              TextField(
                                controller: _usernameController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                decoration: InputDecoration(
                                  hintText: 'Enter username',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Color(0xFF64748B),
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFEDF4FC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF036838),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Password Label
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Password Input Field
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  hintText: 'Enter password',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFF64748B),
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFEDF4FC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF036838),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Log In Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF036838),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: const Color(
                                      0xFF036838,
                                    ).withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 19,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Logo Widget reproducing the TaskChat icon from the reference image.
class _TaskChatLogo extends StatelessWidget {
  const _TaskChatLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: const Color(0xFFD3F9E0),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF036838).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Dark green rounded container with chat bubble
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF036838),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(28, 26),
                    painter: _ChatBubblePainter(),
                  ),
                ),
              ),

              // Small check badge in bottom-right corner
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD3F9E0),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the white speech bubble with horizontal lines inside.
class _ChatBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bubblePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const double cornerRadius = 5.0;
    const double tailHeight = 4.0;
    final bubbleHeight = size.height - tailHeight;

    final path = Path();
    // Rounded bubble body
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, bubbleHeight),
        const Radius.circular(cornerRadius),
      ),
    );

    // Bottom-left speech bubble tail
    final tailPath = Path()
      ..moveTo(size.width * 0.16, bubbleHeight)
      ..lineTo(size.width * 0.04, size.height)
      ..lineTo(size.width * 0.32, bubbleHeight)
      ..close();
    path.addPath(tailPath, Offset.zero);

    canvas.drawPath(path, bubblePaint);

    // Two rounded horizontal lines inside representing text lines
    final linePaint = Paint()
      ..color = const Color(0xFF036838)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    // Top text line
    canvas.drawLine(
      Offset(size.width * 0.24, bubbleHeight * 0.38),
      Offset(size.width * 0.76, bubbleHeight * 0.38),
      linePaint,
    );

    // Bottom text line (shorter)
    canvas.drawLine(
      Offset(size.width * 0.24, bubbleHeight * 0.64),
      Offset(size.width * 0.58, bubbleHeight * 0.64),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// widgets/token_input_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TokenInputDialog extends StatefulWidget {
  final VoidCallback? onTokenSubmitted;
  final String? initialToken;
  final String title;
  final String subtitle;

  const TokenInputDialog({
    Key? key,
    this.onTokenSubmitted,
    this.initialToken,
    this.title = 'API-Token erforderlich',
    this.subtitle = 'Gib deinen API-Token ein, um fortzufahren',
  }) : super(key: key);

  @override
  _TokenInputDialogState createState() => _TokenInputDialogState();
}

class _TokenInputDialogState extends State<TokenInputDialog>
    with TickerProviderStateMixin {
  final TextEditingController _tokenController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool _isTokenVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Set initial token if provided
    if (widget.initialToken != null) {
      _tokenController.text = widget.initialToken!;
    }

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Auto-focus the text field after animation
    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final token = _tokenController.text.trim();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Basic validation
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Token erforderlich';
        _isLoading = false;
      });
      return;
    }

    if (token.length < 10) {
      setState(() {
        _errorMessage = 'Token zu kurz';
        _isLoading = false;
      });
      return;
    }

    // Call the callback if provided
    if (widget.onTokenSubmitted != null) {
      widget.onTokenSubmitted!();
    }

    // Simulate validation
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop(token);
      }
    });
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _tokenController.text = clipboardData!.text!;
        setState(() {
          _errorMessage = null;
        });

        // Brief feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Eingefügt'),
            backgroundColor: Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Einfügen'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              minWidth: 300,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          // Icon
          ScaleTransition(
            scale: _isLoading ? _pulseAnimation : _scaleAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.key,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: 24),

          // Title
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8),

          // Subtitle
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Token input section
          Text(
            'TOKEN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: 1.5,
            ),
          ),

          SizedBox(height: 12),

          // Input container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorMessage != null
                    ? Color(0xFFDC2626)
                    : _tokenController.text.isNotEmpty
                        ? Color(0xFF111827)
                        : Color(0xFFE5E7EB),
                width: _tokenController.text.isNotEmpty ? 2 : 1,
              ),
              color: Color(0xFFFAFAFA),
            ),
            child: Column(
              children: [
                // Input field
                TextField(
                  controller: _tokenController,
                  focusNode: _focusNode,
                  obscureText: !_isTokenVisible,
                  onSubmitted: (_) => _validateAndSubmit(),
                  onChanged: (_) => setState(() => _errorMessage = null),
                  decoration: InputDecoration(
                    hintText: 'eyJhbG...',
                    hintStyle: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontFamily: 'monospace',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: Color(0xFF111827),
                    height: 1.4,
                  ),
                ),

                // Action bar
                Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'API-Token',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      // Paste button
                      GestureDetector(
                        onTap: _pasteFromClipboard,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF111827),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.content_paste,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Einfügen',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Visibility toggle
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isTokenVisible = !_isTokenVisible),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _isTokenVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFDC2626).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Color(0xFFDC2626),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 24),

          // Help section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Token-Hilfe',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Der Token befindet sich im Authorization-Header als "Bearer <token>"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: Container(
                  height: 48,
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Abbrechen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Submit button
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF111827),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Überprüfe...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Bestätigen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

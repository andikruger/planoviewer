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
    this.subtitle = 'Geben Sie Ihren API-Token ein, um fortzufahren',
  }) : super(key: key);

  @override
  _TokenInputDialogState createState() => _TokenInputDialogState();
}

class _TokenInputDialogState extends State<TokenInputDialog>
    with TickerProviderStateMixin {
  final TextEditingController _tokenController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
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
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();

    // Auto-focus the text field after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
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
        _errorMessage = 'Bitte geben Sie einen API-Token ein';
        _isLoading = false;
      });
      return;
    }

    if (token.length < 10) {
      setState(() {
        _errorMessage = 'Der API-Token scheint zu kurz zu sein';
        _isLoading = false;
      });
      return;
    }

    // Call the callback if provided
    if (widget.onTokenSubmitted != null) {
      widget.onTokenSubmitted!();
    }

    // Simulate API validation (you can replace this with actual API call)
    Future.delayed(Duration(seconds: 1), () {
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Einfügen aus der Zwischenablage'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE30613),
                Colors.white,
              ],
              stops: [0.0, 0.3],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTokenDialogHeader(),
              _buildTokenDialogContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenDialogHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.key,
              size: 40,
              color: Color(0xFFE30613),
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDialogContent() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'API-Token',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),

          // Token input field
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorMessage != null
                    ? Colors.red[400]!
                    : Colors.grey[300]!,
                width: 2,
              ),
              color: Colors.grey[50],
            ),
            child: TextField(
              controller: _tokenController,
              focusNode: _focusNode,
              obscureText: !_isTokenVisible,
              onSubmitted: (_) => _validateAndSubmit(),
              decoration: InputDecoration(
                hintText: 'sk-xxxxxxxxxxxxxxxxxxxxxxxx',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _pasteFromClipboard,
                      icon: Icon(Icons.paste, color: Colors.grey[600]),
                      tooltip: 'Aus Zwischenablage einfügen',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isTokenVisible = !_isTokenVisible;
                        });
                      },
                      icon: Icon(
                        _isTokenVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      tooltip: _isTokenVisible
                          ? 'Token verbergen'
                          : 'Token anzeigen',
                    ),
                  ],
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 24),

          // Help text
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wo finde ich meinen API-Token?',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ihr API-Token finden Sie in den Einstellungen Ihres Kontos oder wurde Ihnen per E-Mail zugesandt.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: _isLoading ? null : _validateAndSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE30613),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Überprüfung...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Token bestätigen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          SizedBox(height: 12),

          // Cancel button
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

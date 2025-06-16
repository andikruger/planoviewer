// widgets/api_token_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ApiTokenDialog extends StatefulWidget {
  final VoidCallback onTokenSet;

  const ApiTokenDialog({Key? key, required this.onTokenSet}) : super(key: key);

  @override
  _ApiTokenDialogState createState() => _ApiTokenDialogState();
}

class _ApiTokenDialogState extends State<ApiTokenDialog>
    with TickerProviderStateMixin {
  final TextEditingController _tokenController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isValidating = false;
  bool _obscureText = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSetToken() async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte geben Sie einen API Token ein';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final isValid = await ApiService.validateToken(token);

      if (isValid) {
        ApiService.setToken(token);
        widget.onTokenSet();
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage =
              'Ungültiger API Token. Bitte überprüfen Sie den Token.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler bei der Validierung: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _tokenController.text = clipboardData!.text!;
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing without token
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildContent(),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE30613), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.vpn_key,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'API Token erforderlich',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Bitte geben Sie Ihren API Token ein, um fortzufahren',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Token',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorMessage != null ? Colors.red : Colors.grey[300]!,
                width: _errorMessage != null ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: _tokenController,
              focusNode: _focusNode,
              obscureText: _obscureText,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'z.B. sk-1234567890abcdef...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.paste, color: Colors.grey[600]),
                      onPressed: _pasteFromClipboard,
                      tooltip: 'Aus Zwischenablage einfügen',
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _validateAndSetToken(),
            ),
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ihr API Token wird nur für diese Sitzung gespeichert und nicht dauerhaft auf dem Gerät hinterlegt.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isValidating ? null : _validateAndSetToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE30613),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isValidating
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
                        Text('Validierung läuft...'),
                      ],
                    )
                  : Text(
                      'Token validieren',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _buildHelpDialog(),
              );
            },
            child: Text(
              'Wo finde ich meinen API Token?',
              style: TextStyle(
                color: Color(0xFFE30613),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.help_outline, color: Color(0xFFE30613)),
          SizedBox(width: 8),
          Text('API Token Hilfe'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'So finden Sie Ihren API Token:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          _buildHelpStep('1.', 'Öffnen Sie Ihr Account-Dashboard'),
          _buildHelpStep('2.', 'Navigieren Sie zu "API Einstellungen"'),
          _buildHelpStep('3.', 'Klicken Sie auf "Token generieren"'),
          _buildHelpStep('4.', 'Kopieren Sie den generierten Token'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[700], size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bewahren Sie Ihren Token sicher auf!',
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Verstanden'),
        ),
      ],
    );
  }

  Widget _buildHelpStep(String step, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFFE30613).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: Color(0xFFE30613),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

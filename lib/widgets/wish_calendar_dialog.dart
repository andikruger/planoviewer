// screens/shift_calendar/shift_calendar_dialogs.dart

import 'package:flutter/material.dart';
import 'package:planoviewer/models/calendar_model.dart';
import '../../utils/calendar_utils.dart';

class ShiftCalendarDialogs {
  // Main dialog methods
  static void showDayOptionsDialog({
    required BuildContext context,
    required DateTime selectedDate,
    required SelectedShift? currentShift,
    required DayOff? currentDayOff,
    required VoidCallback onShiftSelected,
    required VoidCallback onFullDayOff,
    required VoidCallback onPartialDayOff,
    required VoidCallback onRemoveEntry,
  }) {
    showDialog(
      context: context,
      builder: (context) => _AnimatedDialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            minWidth: 320,
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
              // Header
              _buildHeader(
                icon: Icons.event,
                title: 'Tag planen',
                subtitle: CalendarUtils.formatDisplayDate(selectedDate),
                color: Color(0xFFE30613),
                onClose: () => Navigator.of(context).pop(),
              ),

              // Content
              Container(
                padding: EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current status
                    if (currentShift != null || currentDayOff != null) ...[
                      _buildStatusCard(
                        currentShift: currentShift,
                        currentDayOff: currentDayOff,
                      ),
                      SizedBox(height: 24),
                    ],

                    // Options section header
                    Text(
                      'OPTIONEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Options
                    _buildModernOptionCard(
                      icon: Icons.work,
                      iconColor: Color(0xFFE30613),
                      title: 'Schicht planen',
                      subtitle: 'Arbeitszeit für diesen Tag festlegen',
                      onTap: () {
                        Navigator.of(context).pop();
                        onShiftSelected();
                      },
                    ),
                    SizedBox(height: 12),
                    _buildModernOptionCard(
                      icon: Icons.event_busy,
                      iconColor: Color(0xFF059669),
                      title: 'Ganzer Tag frei',
                      subtitle: 'Tag als komplett frei markieren',
                      onTap: () {
                        Navigator.of(context).pop();
                        onFullDayOff();
                      },
                    ),
                    SizedBox(height: 12),
                    _buildModernOptionCard(
                      icon: Icons.schedule,
                      iconColor: Color(0xFF6366F1),
                      title: 'Teilweise frei',
                      subtitle: 'Bestimmte Stunden als frei markieren',
                      onTap: () {
                        Navigator.of(context).pop();
                        onPartialDayOff();
                      },
                    ),

                    // Remove option
                    if (currentShift != null || currentDayOff != null) ...[
                      SizedBox(height: 24),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFE5E7EB),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildModernOptionCard(
                        icon: Icons.clear,
                        iconColor: Color(0xFF6B7280),
                        title: 'Planung entfernen',
                        subtitle: 'Alle Einstellungen für diesen Tag löschen',
                        onTap: () {
                          Navigator.of(context).pop();
                          onRemoveEntry();
                        },
                        isDanger: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showShiftSelectionDialog({
    required BuildContext context,
    required DateTime selectedDate,
    required List<AvailableShift> availableShifts,
    required SelectedShift? currentSelection,
    required Function(AvailableShift) onShiftSelected,
    required VoidCallback onClearShift,
  }) {
    showDialog(
      context: context,
      builder: (context) => _AnimatedDialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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
              // Header
              _buildHeader(
                icon: Icons.schedule,
                title: 'Schicht auswählen',
                subtitle: CalendarUtils.formatDisplayDate(selectedDate),
                color: Color(0xFFE30613),
                onClose: () => Navigator.of(context).pop(),
              ),

              // Content
              Flexible(
                child: Container(
                  padding: EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Clear option
                      _buildClearShiftOption(
                        currentSelection: currentSelection,
                        onClearShift: () {
                          Navigator.of(context).pop();
                          onClearShift();
                        },
                      ),

                      SizedBox(height: 24),

                      // Section header
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(0xFFE30613),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'VERFÜGBARE SCHICHTEN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Shifts list
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableShifts.length,
                          itemBuilder: (context, index) {
                            final shift = availableShifts[index];
                            final isSelected = currentSelection?.id == shift.id;
                            final shiftType =
                                CalendarUtils.getShiftType(shift.timeRange);

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              child: _buildShiftCard(
                                shift: shift,
                                shiftType: shiftType,
                                isSelected: isSelected,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onShiftSelected(shift);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showPartialDayOffDialog({
    required BuildContext context,
    required DateTime selectedDate,
    required Function(TimeOfDay, TimeOfDay) onSave,
  }) {
    TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => _AnimatedDialog(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              minWidth: 320,
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
                // Header
                _buildHeader(
                  icon: Icons.schedule,
                  title: 'Teilweise frei',
                  subtitle: CalendarUtils.formatDisplayDate(selectedDate),
                  color: Color(0xFF6366F1),
                  onClose: () => Navigator.of(context).pop(),
                ),

                // Content
                Container(
                  padding: EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Instructions
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Wähle die Zeit in der du frei haben willst:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Time selection header
                      Text(
                        'ZEITRAUM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: 1.5,
                        ),
                      ),

                      SizedBox(height: 16),

                      // Start time
                      _buildTimeSelector(
                        label: 'Von',
                        time: startTime,
                        icon: Icons.play_arrow,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (time != null) {
                            setState(() => startTime = time);
                          }
                        },
                      ),

                      SizedBox(height: 16),

                      // End time
                      _buildTimeSelector(
                        label: 'Bis',
                        time: endTime,
                        icon: Icons.stop,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (time != null) {
                            setState(() => endTime = time);
                          }
                        },
                      ),

                      SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
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
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onSave(startTime, endTime);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Speichern',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widgets
  static Widget _buildHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onClose,
  }) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24),
          // Title
          Text(
            title,
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
            subtitle,
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

  static Widget _buildStatusCard({
    required SelectedShift? currentShift,
    required DayOff? currentDayOff,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AKTUELLER STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  currentShift != null
                      ? 'Schicht ${currentShift.timeRange}'
                      : currentDayOff!.isFullDay
                          ? 'Ganzer Tag frei'
                          : 'Teilweise frei ${currentDayOff.timeRange}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildModernOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDanger ? Color(0xFFFEF2F2) : Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger
                ? Color(0xFFDC2626).withOpacity(0.2)
                : Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9CA3AF),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildClearShiftOption({
    required SelectedShift? currentSelection,
    required VoidCallback onClearShift,
  }) {
    final hasSelection = currentSelection != null;

    return GestureDetector(
      onTap: onClearShift,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasSelection ? Color(0xFFFEF2F2) : Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSelection
                ? Color(0xFFDC2626).withOpacity(0.2)
                : Color(0xFFE5E7EB),
            width: hasSelection ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasSelection
                    ? Color(0xFFDC2626).withOpacity(0.1)
                    : Color(0xFF6B7280).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.clear,
                color: hasSelection ? Color(0xFFDC2626) : Color(0xFF6B7280),
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keine Schicht',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color:
                          hasSelection ? Color(0xFFDC2626) : Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    hasSelection
                        ? 'Aktuelle Auswahl entfernen'
                        : 'Kein Dienst an diesem Tag',
                    style: TextStyle(
                      color: hasSelection
                          ? Color(0xFFDC2626).withOpacity(0.7)
                          : Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (hasSelection)
              Icon(
                Icons.remove_circle,
                color: Color(0xFFDC2626),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildShiftCard({
    required AvailableShift shift,
    required shiftType,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? CalendarUtils.getShiftTypeColor(shiftType).withOpacity(0.05)
              : Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? CalendarUtils.getShiftTypeColor(shiftType).withOpacity(0.3)
                : Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? CalendarUtils.getShiftTypeColor(shiftType)
                    : CalendarUtils.getShiftTypeColor(shiftType)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CalendarUtils.getShiftTypeIcon(shiftType),
                color: isSelected
                    ? Colors.white
                    : CalendarUtils.getShiftTypeColor(shiftType),
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.timeRange,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isSelected
                          ? CalendarUtils.getShiftTypeColor(shiftType)
                          : Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${CalendarUtils.getShiftTypeName(shiftType)} • ${CalendarUtils.calculateDuration(shift.timeRange)}',
                    style: TextStyle(
                      color: isSelected
                          ? CalendarUtils.getShiftTypeColor(shiftType)
                              .withOpacity(0.7)
                          : Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: CalendarUtils.getShiftTypeColor(shiftType),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Color(0xFF6366F1), size: 18),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated dialog wrapper
class _AnimatedDialog extends StatefulWidget {
  final Widget child;

  const _AnimatedDialog({required this.child});

  @override
  _AnimatedDialogState createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<_AnimatedDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

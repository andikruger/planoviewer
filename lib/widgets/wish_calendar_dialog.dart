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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFE30613),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.event, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tag planen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            CalendarUtils.formatDisplayDate(selectedDate),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Current status
                    if (currentShift != null || currentDayOff != null) ...[
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Color(0xFF6366F1).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                currentShift != null
                                    ? Icons.work
                                    : Icons.event_busy,
                                color: Color(0xFF6366F1),
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                currentShift != null
                                    ? 'Aktuell: Schicht ${currentShift.timeRange}'
                                    : currentDayOff!.isFullDay
                                        ? 'Aktuell: Ganzer Tag frei'
                                        : 'Aktuell: Teilweise frei ${currentDayOff.timeRange}',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Options
                    _buildOptionTile(
                      context: context,
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
                    _buildOptionTile(
                      context: context,
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
                    _buildOptionTile(
                      context: context,
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
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                      SizedBox(height: 16),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.clear,
                        iconColor: Color(0xFF6B7280),
                        title: 'Planung entfernen',
                        subtitle: 'Alle Einstellungen für diesen Tag löschen',
                        onTap: () {
                          Navigator.of(context).pop();
                          onRemoveEntry();
                        },
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFE30613),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(Icons.schedule, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schicht auswählen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            CalendarUtils.formatDisplayDate(selectedDate),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Clear option
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          onClearShift();
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: currentSelection != null
                                ? Color(0xFFE30613).withOpacity(0.05)
                                : Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentSelection != null
                                  ? Color(0xFFE30613).withOpacity(0.3)
                                  : Color(0xFFE5E7EB),
                              width: currentSelection != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: currentSelection != null
                                      ? Color(0xFFE30613).withOpacity(0.1)
                                      : Color(0xFF6B7280).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.clear,
                                  color: currentSelection != null
                                      ? Color(0xFFE30613)
                                      : Color(0xFF6B7280),
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
                                        color: currentSelection != null
                                            ? Color(0xFFE30613)
                                            : Color(0xFF6B7280),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      currentSelection != null
                                          ? 'Aktuelle Auswahl entfernen'
                                          : 'Kein Dienst an diesem Tag',
                                      style: TextStyle(
                                        color: currentSelection != null
                                            ? Color(0xFFE30613).withOpacity(0.7)
                                            : Color(0xFF9CA3AF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (currentSelection != null)
                                Icon(Icons.remove_circle,
                                    color: Color(0xFFE30613), size: 20),
                            ],
                          ),
                        ),
                      ),

                      // Divider
                      if (currentSelection != null) ...[
                        Container(height: 1, color: Color(0xFFE5E7EB)),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
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
                        ),
                      ],

                      // Shifts list
                      Expanded(
                        child: ListView.builder(
                          itemCount: availableShifts.length,
                          itemBuilder: (context, index) {
                            final shift = availableShifts[index];
                            final isSelected = currentSelection?.id == shift.id;
                            final shiftType =
                                CalendarUtils.getShiftType(shift.timeRange);

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onShiftSelected(shift);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? CalendarUtils.getShiftTypeColor(
                                                shiftType)
                                            .withOpacity(0.05)
                                        : Color(0xFFFAFAFA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? CalendarUtils.getShiftTypeColor(
                                                  shiftType)
                                              .withOpacity(0.3)
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
                                              ? CalendarUtils.getShiftTypeColor(
                                                  shiftType)
                                              : CalendarUtils.getShiftTypeColor(
                                                      shiftType)
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          CalendarUtils.getShiftTypeIcon(
                                              shiftType),
                                          color: isSelected
                                              ? Colors.white
                                              : CalendarUtils.getShiftTypeColor(
                                                  shiftType),
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shift.timeRange,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: isSelected
                                                    ? CalendarUtils
                                                        .getShiftTypeColor(
                                                            shiftType)
                                                    : Color(0xFF111827),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              '${CalendarUtils.getShiftTypeName(shiftType)} • ${CalendarUtils.calculateDuration(shift.timeRange)}',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? CalendarUtils
                                                            .getShiftTypeColor(
                                                                shiftType)
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
                                        Icon(Icons.check_circle,
                                            color:
                                                CalendarUtils.getShiftTypeColor(
                                                    shiftType),
                                            size: 20),
                                    ],
                                  ),
                                ),
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
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(Icons.schedule, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teilweise frei',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              CalendarUtils.formatDisplayDate(selectedDate),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon:
                              Icon(Icons.close, color: Colors.white, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Wähle die Zeit in der du frei haben willst:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),

                      // Start time
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (time != null) {
                            setState(() {
                              startTime = time;
                            });
                          }
                        },
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
                                child: Icon(Icons.play_arrow,
                                    color: Color(0xFF6366F1), size: 18),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Von',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Text(
                                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // End time
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (time != null) {
                            setState(() {
                              endTime = time;
                            });
                          }
                        },
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
                                child: Icon(Icons.stop,
                                    color: Color(0xFF6366F1), size: 18),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Bis',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Text(
                                '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                ),
                                child: Text(
                                  'Abbrechen',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
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
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  'Speichern',
                                  style: TextStyle(fontWeight: FontWeight.w600),
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

  static void showSummaryDialog({
    required BuildContext context,
    required Map<String, SelectedShift> selectedShifts,
    required Map<String, DayOff> daysOff,
    required Function(String, {SelectedShift? shift, DayOff? dayOff})
        onRemoveItem,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFE30613),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(Icons.list_alt, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Übersicht',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: (selectedShifts.isEmpty && daysOff.isEmpty)
                    ? Container(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.schedule_outlined,
                                size: 40,
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Keine Planungen vorhanden',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tippe auf einen Tag im Kalender, um eine Schicht oder freie Zeit zu planen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.all(20),
                        child: ListView.builder(
                          itemCount: selectedShifts.length + daysOff.length,
                          itemBuilder: (context, index) {
                            if (index < selectedShifts.length) {
                              // Shift item
                              final entry =
                                  selectedShifts.entries.elementAt(index);
                              final shift = entry.value;
                              final dateKey = entry.key;
                              final shiftType =
                                  CalendarUtils.getShiftType(shift.timeRange);

                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: CalendarUtils.getShiftTypeColor(
                                            shiftType)
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: CalendarUtils.getShiftTypeColor(
                                                shiftType)
                                            .withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color:
                                              CalendarUtils.getShiftTypeColor(
                                                      shiftType)
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          CalendarUtils.getShiftTypeIcon(
                                              shiftType),
                                          color:
                                              CalendarUtils.getShiftTypeColor(
                                                  shiftType),
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              CalendarUtils.formatDisplayDate(
                                                  shift.date),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              '${shift.timeRange} • ${CalendarUtils.getShiftTypeName(shiftType)}',
                                              style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            CalendarUtils.calculateDuration(
                                                shift.timeRange),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: CalendarUtils
                                                  .getShiftTypeColor(shiftType),
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () => onRemoveItem(dateKey,
                                                shift: shift),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFE30613)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Color(0xFFE30613),
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              // Day off item
                              final dayOffIndex = index - selectedShifts.length;
                              final entry =
                                  daysOff.entries.elementAt(dayOffIndex);
                              final dayOff = entry.value;
                              final dateKey = entry.key;

                              Color itemColor = dayOff.isFullDay
                                  ? Color(0xFF059669)
                                  : Color(0xFF6366F1);
                              IconData itemIcon = dayOff.isFullDay
                                  ? Icons.event_busy
                                  : Icons.schedule;

                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: itemColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: itemColor.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: itemColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          itemIcon,
                                          color: itemColor,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              CalendarUtils.formatDisplayDate(
                                                  dayOff.date),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              dayOff.isFullDay
                                                  ? 'Ganzer Tag frei'
                                                  : 'Teilweise frei ${dayOff.timeRange}',
                                              style: TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (!dayOff.isFullDay)
                                            Text(
                                              CalendarUtils.calculateDuration(
                                                  dayOff.timeRange!),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: itemColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () => onRemoveItem(dateKey,
                                                dayOff: dayOff),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFE30613)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Color(0xFFE30613),
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showTokenInfoDialog({
    required BuildContext context,
    required String? apiToken,
    required VoidCallback onChangeToken,
  }) {
    String maskedToken = apiToken != null
        ? '${apiToken.substring(0, 8)}${'*' * (apiToken.length - 12)}${apiToken.substring(apiToken.length - 4)}'
        : 'Kein Token';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info, color: Color(0xFF6366F1), size: 18),
            ),
            SizedBox(width: 12),
            Text(
              'API-Token Information',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktueller Token:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: Text(
                maskedToken,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF059669).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF059669).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Token ist gültig und gespeichert',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 14,
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Schließen',
              style: TextStyle(
                  color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onChangeToken();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE30613),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Token ändern',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static void showLogoutDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFE30613).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: Color(0xFFE30613), size: 18),
            ),
            SizedBox(width: 12),
            Text(
              'Abmelden',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du dich wirklich abmelden?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF59E0B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dies wird:',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Den gespeicherten API-Token löschen\n• Alle geplanten Schichten entfernen\n• Dich zur Token-Eingabe zurückführen',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 13,
                          ),
                        ),
                      ],
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Abbrechen',
              style: TextStyle(
                  color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE30613),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Abmelden',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static void showChangeTokenDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning, color: Color(0xFFF59E0B), size: 18),
            ),
            SizedBox(width: 12),
            Text(
              'API-Token ändern',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Möchtest du wirklich einen neuen API-Token eingeben? Dies wird alle aktuellen Daten zurücksetzen.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Abbrechen',
              style: TextStyle(
                  color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE30613),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Token ändern',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static void showQuickRemoveDialog({
    required BuildContext context,
    required DateTime date,
    required String itemType,
    required String itemDetails,
    required bool isShift,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFE30613).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline,
                  color: Color(0xFFE30613), size: 18),
            ),
            SizedBox(width: 12),
            Text(
              '$itemType entfernen',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Willst du den ${isShift ? 'Schicht' : 'Freizeiteintrag'} wirklich entfernen?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
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
                      color: isShift
                          ? Color(0xFFE30613).withOpacity(0.1)
                          : Color(0xFF059669).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isShift ? Icons.work : Icons.event_busy,
                      size: 20,
                      color: isShift ? Color(0xFFE30613) : Color(0xFF059669),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CalendarUtils.formatDisplayDate(date),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          itemDetails,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Abbrechen',
              style: TextStyle(
                  color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE30613),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Entfernen',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for option tiles
  static Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
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
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
          ],
        ),
      ),
    );
  }
}

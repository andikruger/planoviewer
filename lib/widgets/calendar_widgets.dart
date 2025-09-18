// widgets/calendar_widgets.dart

// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../models/calendar_model.dart';
import '../utils/calendar_utils.dart';

class QuickStatWidget extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const QuickStatWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  }) : super(key: key);

  @override
  _QuickStatWidgetState createState() => _QuickStatWidgetState();
}

class _QuickStatWidgetState extends State<QuickStatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.icon != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.icon != null) ...[
                    SizedBox(width: 12),
                    Icon(
                      widget.icon,
                      size: 20,
                      color: widget.color.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DayOptionTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  const DayOptionTile({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  _DayOptionTileState createState() => _DayOptionTileState();
}

class _DayOptionTileState extends State<DayOptionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(vertical: 6),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.iconColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? widget.iconColor.withOpacity(0.3)
                  : Color(0xFFE5E7EB),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (widget.isSelected || _isPressed)
                BoxShadow(
                  color: widget.iconColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF9CA3AF),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarDayWidget extends StatefulWidget {
  final int dayNumber;
  final DateTime date;
  final SelectedShift? selectedShift;
  final DayOff? dayOff;
  final bool isWeekend;
  final bool isPastDate;
  final bool isToday;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CalendarDayWidget({
    Key? key,
    required this.dayNumber,
    required this.date,
    this.selectedShift,
    this.dayOff,
    required this.isWeekend,
    required this.isPastDate,
    this.isToday = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  _CalendarDayWidgetState createState() => _CalendarDayWidgetState();
}

class _CalendarDayWidgetState extends State<CalendarDayWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isToday) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayType = CalendarUtils.getDayType(
        widget.selectedShift, widget.dayOff, widget.isWeekend);
    final hasContent = widget.selectedShift != null || widget.dayOff != null;

    return GestureDetector(
      onTapDown: widget.isPastDate
          ? null
          : (_) {
              _pressController.forward();
            },
      onTapUp: widget.isPastDate
          ? null
          : (_) {
              _pressController.reverse();
              widget.onTap?.call();
            },
      onTapCancel: widget.isPastDate
          ? null
          : () {
              _pressController.reverse();
            },
      onLongPress: hasContent ? widget.onLongPress : null,
      child: ScaleTransition(
        scale: widget.isToday ? _pulseAnimation : _scaleAnimation,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _getDayBackgroundColor(
                dayType as String, widget.isPastDate, widget.isToday),
            borderRadius: BorderRadius.circular(12),
            border: widget.isToday
                ? Border.all(
                    color: Color(0xFFE30613),
                    width: 3,
                  )
                : hasContent
                    ? Border.all(
                        color: _getDayBorderColor(
                            dayType as String, widget.isPastDate),
                        width: 2,
                      )
                    : Border.all(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
            boxShadow: [
              if (hasContent || widget.isToday)
                BoxShadow(
                  color:
                      _getDayBorderColor(dayType as String, widget.isPastDate)
                          .withOpacity(0.3),
                  blurRadius: widget.isToday ? 16 : 12,
                  offset: Offset(0, widget.isToday ? 6 : 4),
                ),
            ],
          ),
          child: Container(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.dayNumber}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        widget.isToday ? FontWeight.w900 : FontWeight.w700,
                    color: _getDayTextColor(
                        dayType as String, widget.isPastDate, widget.isToday),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6),
                _buildDayContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDayBackgroundColor(String dayType, bool isPastDate, bool isToday) {
    if (isPastDate) return Color(0xFFF9FAFB);
    if (isToday) return Color(0xFFFEF2F2);

    switch (dayType) {
      case 'shift':
        return Color(0xFFFEF2F2);
      case 'dayOff':
        return Color(0xFFF0FDF4);
      case 'partialDayOff':
        return Color(0xFFFFF8E1);
      case 'weekend':
        return Color(0xFFFFF8E1);
      default:
        return Colors.white;
    }
  }

  Color _getDayBorderColor(String dayType, bool isPastDate) {
    if (isPastDate) return Color(0xFFE5E7EB);

    switch (dayType) {
      case 'shift':
        return Color(0xFFE30613);
      case 'dayOff':
        return Color(0xFF059669);
      case 'partialDayOff':
        return Color(0xFFFF8F00);
      case 'weekend':
        return Color(0xFFFF8F00);
      default:
        return Color(0xFFE5E7EB);
    }
  }

  Color _getDayTextColor(String dayType, bool isPastDate, bool isToday) {
    if (isPastDate) return Color(0xFF9CA3AF);
    if (isToday) return Color(0xFFE30613);

    switch (dayType) {
      case 'shift':
        return Color(0xFF111827);
      case 'dayOff':
        return Color(0xFF111827);
      case 'partialDayOff':
        return Color(0xFF111827);
      case 'weekend':
        return Color(0xFF111827);
      default:
        return Color(0xFF111827);
    }
  }

  Widget _buildDayContent() {
    if (widget.selectedShift != null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(0xFFE30613).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              CalendarUtils.getStartTime(widget.selectedShift!.timeRange),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE30613),
                letterSpacing: 0.5,
              ),
            ),
            Container(
              width: 16,
              height: 2,
              margin: EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFFE30613),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Text(
              CalendarUtils.getEndTime(widget.selectedShift!.timeRange),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE30613),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else if (widget.dayOff != null) {
      if (widget.dayOff!.isFullDay) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFF059669).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                size: 16,
                color: Color(0xFF059669),
              ),
              SizedBox(height: 2),
              Text(
                'FREI',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFFFF8F00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                CalendarUtils.getStartTime(widget.dayOff!.timeRange!),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF8F00),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                width: 16,
                height: 2,
                margin: EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFFF8F00),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Text(
                CalendarUtils.getEndTime(widget.dayOff!.timeRange!),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF8F00),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }
    } else if (widget.isWeekend) {
      return Container(
        width: 20,
        height: 3,
        decoration: BoxDecoration(
          color: Color(0xFFFF8F00),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else if (!widget.isPastDate) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.add,
          size: 14,
          color: Color(0xFF9CA3AF),
        ),
      );
    }
    return SizedBox(height: 20);
  }
}

// Additional calendar header widget for month/year display
class CalendarHeaderWidget extends StatelessWidget {
  final String monthYear;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const CalendarHeaderWidget({
    Key? key,
    required this.monthYear,
    this.onPrevious,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF111827).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFFE30613),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              monthYear,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (onPrevious != null)
            Container(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: onPrevious,
                icon: Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xFFF3F4F6),
                  foregroundColor: Color(0xFF111827),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          SizedBox(width: 8),
          if (onNext != null)
            Container(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: onNext,
                icon: Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xFFF3F4F6),
                  foregroundColor: Color(0xFF111827),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

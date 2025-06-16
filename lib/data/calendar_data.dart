// data/calendar_data.dart

import '../models/calendar_model.dart';

class CalendarData {
  static List<AvailableShift> getAvailableShifts() {
    final shifts = [
      AvailableShift(
          id: "99cc0a9f-c683-4426-ac41-0627b905df39", timeRange: "0600-1100"),
      AvailableShift(
          id: "b42cd2db-683f-45e6-9f62-093f6ffb7d0b", timeRange: "1500-2330"),
      AvailableShift(
          id: "500f91ed-f09e-4065-8a5a-0ee96a9fb294", timeRange: "0900-2100"),
      AvailableShift(
          id: "a43bef61-5544-44cb-99e8-117e1a231877", timeRange: "0430-1030"),
      AvailableShift(
          id: "cf1d95ae-f8cf-4c4b-b98e-122762393f65", timeRange: "0430-1430"),
      AvailableShift(
          id: "d771ea86-0caf-44df-aac6-1b8bc00fa630", timeRange: "0800-1800"),
      AvailableShift(
          id: "8c1a6349-0a00-46b5-9fe6-1ef685ffee78", timeRange: "0830-1330"),
      AvailableShift(
          id: "58b78a88-067c-43d5-8507-2ae5159b58e3", timeRange: "0800-1300"),
      AvailableShift(
          id: "3a6d4103-5df4-4e5d-96c1-2c0549852e23", timeRange: "0730-1730"),
      AvailableShift(
          id: "fd6787d7-4a44-4201-986c-306f9b42510e", timeRange: "0600-1200"),
      AvailableShift(
          id: "0d737488-ecd7-43a7-a7b5-3405739f1b45", timeRange: "1600-2100"),
      AvailableShift(
          id: "e8935a76-b77f-4599-8a54-35b45d7e94f2", timeRange: "0530-1030"),
      AvailableShift(
          id: "d1f84925-e5a2-48b9-8870-44cba556bdf6", timeRange: "0500-1430"),
      AvailableShift(
          id: "9ce119ae-66b9-47b2-9f59-46ee166047e5", timeRange: "1200-2300"),
      AvailableShift(
          id: "6a177183-41a9-47bc-99a5-4bf7924d86d5", timeRange: "1100-2100"),
      AvailableShift(
          id: "3068b840-22e2-4e3e-a660-4f349baa80d6", timeRange: "0730-1800"),
      AvailableShift(
          id: "75c6bfe3-b2a1-4ae6-821a-5abad6b04f8d", timeRange: "0500-1530"),
      AvailableShift(
          id: "caa287ad-fe59-4efd-81da-5af990981b7c", timeRange: "0800-1400"),
      AvailableShift(
          id: "0ae0f4be-b467-4560-910c-7a8137644d00", timeRange: "0500-1100"),
      AvailableShift(
          id: "2dbfcb33-852c-4f5a-8903-884fbd5146a8", timeRange: "1500-2100"),
      AvailableShift(
          id: "005b8aab-0603-4499-81cf-95c7456b3ece", timeRange: "0430-1400"),
      AvailableShift(
          id: "7530094b-4ab7-40a1-a264-9aebcab7f99e", timeRange: "1500-2300"),
      AvailableShift(
          id: "05831d1d-4df3-42e3-a567-9c5c2b284f43", timeRange: "0900-1800"),
      AvailableShift(
          id: "8e36a89f-055b-4e57-9d67-a3613b922006", timeRange: "1415-0030"),
      AvailableShift(
          id: "20263900-1e69-46ff-bd19-a3dd78f0bba1", timeRange: "1730-2330"),
      AvailableShift(
          id: "629087ac-2786-4dad-bc35-aa6a4af3439e", timeRange: "0800-2000"),
      AvailableShift(
          id: "7849b831-d03c-4a17-b75d-ad810a401ce1", timeRange: "0630-1800"),
      AvailableShift(
          id: "ab156a63-9678-459a-996b-ae77d407a03f", timeRange: "0900-1500"),
      AvailableShift(
          id: "62d7f2ef-d09e-4fd3-ba94-bb79b2d38d01", timeRange: "1330-2330"),
      AvailableShift(
          id: "a510df32-e3aa-4eb2-bfc0-cccdf104844b", timeRange: "0500-1330"),
      AvailableShift(
          id: "56453b3e-ce94-48fb-a973-d9ef790aa5d0", timeRange: "0530-1130"),
      AvailableShift(
          id: "b53532f1-fef8-44d0-a3f3-e77ef7d5bb13", timeRange: "0700-1300"),
      AvailableShift(
          id: "24f3b3cf-6ee5-422d-9b2b-eac622647c00", timeRange: "0830-2030"),
      AvailableShift(
          id: "96ef0825-c3f5-48ee-8f4c-eace745e0db9", timeRange: "0500-1600"),
      AvailableShift(
          id: "f2659024-ca2f-4fb0-a7f9-eb6099ff6f3f", timeRange: "1830-0530"),
      AvailableShift(
          id: "d35bb1f7-c52b-4d42-870e-ef05481eb0cb", timeRange: "1200-2100"),
      AvailableShift(
          id: "cc635f62-2b64-4af9-b416-efbb498640b9", timeRange: "0600-1430"),
      AvailableShift(
          id: "3cc1b96a-6466-4329-9458-fab3b7ddfe05", timeRange: "1630-2230"),
      AvailableShift(
          id: "55888940-1201-4d88-818a-fd925399c9db", timeRange: "1530-2130"),
      AvailableShift(
          id: "2238cdc1-d483-4ce5-9ab8-fe45fe3a0099", timeRange: "0730-1330"),
    ];

    // Sort by start time
    shifts.sort((a, b) {
      final timeA = _parseTime(a.timeRange.split('-')[0]) ?? 0;
      final timeB = _parseTime(b.timeRange.split('-')[0]) ?? 0;
      return timeA.compareTo(timeB);
    });

    return shifts;
  }

  static int? _parseTime(String timeStr) {
    if (timeStr.length != 4) return null;

    final hours = int.tryParse(timeStr.substring(0, 2));
    final minutes = int.tryParse(timeStr.substring(2, 4));

    if (hours == null || minutes == null) return null;

    return hours * 60 + minutes;
  }
}

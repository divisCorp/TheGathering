import 'dart:convert';

import 'package:the_gathering/models/event.dart';
import 'package:url_launcher/url_launcher.dart';

/// Calendar export helpers (ICS + Google / Outlook). PR5 foundation.
class CalendarService {
  /// Build a minimal ICS document for an event.
  static String toIcs(GatheringEvent event) {
    String fmt(DateTime dt) {
      final u = dt.toUtc();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${u.year}${two(u.month)}${two(u.day)}T'
          '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    }

    final end = event.endTime ?? event.startTime.add(const Duration(hours: 2));
    final desc = (event.description ?? '')
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', '\\n')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');
    final title = event.title
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');
    final location = (event.address ?? '')
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');

    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//The Gathering//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:${event.id}@thegathering.app',
      'DTSTAMP:${fmt(DateTime.now())}',
      'DTSTART:${fmt(event.startTime)}',
      'DTEND:${fmt(end)}',
      'SUMMARY:$title',
      if (desc.isNotEmpty) 'DESCRIPTION:$desc',
      if (location.isNotEmpty) 'LOCATION:$location',
      'URL:https://diviscorp.github.io/TheGathering/',
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ].join('\r\n');
  }

  /// Google Calendar template URL (works well on web + mobile).
  static Uri googleCalendarUri(GatheringEvent event) {
    String fmt(DateTime dt) {
      final u = dt.toUtc();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${u.year}${two(u.month)}${two(u.day)}T'
          '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    }

    final end = event.endTime ?? event.startTime.add(const Duration(hours: 2));
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': event.title,
      'dates': '${fmt(event.startTime)}/${fmt(end)}',
      if (event.description != null && event.description!.isNotEmpty)
        'details': event.description!,
      if (event.address != null && event.address!.isNotEmpty)
        'location': event.address!,
    };
    return Uri.https('calendar.google.com', '/calendar/render', params);
  }

  static Future<bool> openGoogleCalendar(GatheringEvent event) async {
    final uri = googleCalendarUri(event);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Outlook web calendar compose URL.
  static Uri outlookCalendarUri(GatheringEvent event) {
    final end = event.endTime ?? event.startTime.add(const Duration(hours: 2));
    String fmt(DateTime dt) => dt.toUtc().toIso8601String();
    final params = <String, String>{
      'path': '/calendar/action/compose',
      'rru': 'addevent',
      'subject': event.title,
      'startdt': fmt(event.startTime),
      'enddt': fmt(end),
      if (event.description != null && event.description!.isNotEmpty)
        'body': event.description!,
      if (event.address != null && event.address!.isNotEmpty)
        'location': event.address!,
    };
    return Uri.https('outlook.live.com', '/calendar/0/deeplink/compose', params);
  }

  static Future<bool> openOutlookCalendar(GatheringEvent event) async {
    final uri = outlookCalendarUri(event);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// data: URI for downloading/opening ICS on web browsers.
  static Uri icsDataUri(GatheringEvent event) {
    final ics = toIcs(event);
    return Uri.dataFromString(
      ics,
      mimeType: 'text/calendar',
      encoding: utf8,
    );
  }

  static Future<bool> openIcsDataUri(GatheringEvent event) async {
    final uri = icsDataUri(event);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

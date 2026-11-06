import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/status_color_service.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/today/today_model.dart';
import 'package:task_chat/update_status/models/status_chip_model.dart';

void main() {
  setUp(() {
    StatusColorService.resetToDefaults();
  });

  tearDown(() {
    StatusColorService.resetToDefaults();
  });

  group('StatusColorService Tests', () {
    test('Default backend colors match expected hex codes', () {
      expect(StatusColorService.getColor('New'), const Color(0xFF3B82F6));
      expect(StatusColorService.getColor('Scheduled'), const Color(0xFF7C3AED));
      expect(StatusColorService.getColor('Completed'), const Color(0xFF10B981));
      expect(StatusColorService.getColor('Cancelled'), const Color(0xFFEF4444));
      expect(StatusColorService.getColor('Pending'), const Color(0xFF8B5CF6));
    });

    test('parseHexColor parses 6-digit and 8-digit hex codes with or without #', () {
      expect(StatusColorService.parseHexColor('#3b82f6'), const Color(0xFF3B82F6));
      expect(StatusColorService.parseHexColor('3b82f6'), const Color(0xFF3B82F6));
      expect(StatusColorService.parseHexColor('#ff10b981'), const Color(0xFF10B981));
      expect(StatusColorService.parseHexColor(''), isNull);
      expect(StatusColorService.parseHexColor(null), isNull);
      expect(StatusColorService.parseHexColor('invalid'), isNull);
    });

    test('registerStatus dynamically updates status color from backend', () {
      StatusColorService.registerStatus('Scheduled', '#F59E0B');
      expect(StatusColorService.getColor('Scheduled'), const Color(0xFFF59E0B));
      expect(StatusColorService.getColor('scheduled'), const Color(0xFFF59E0B));
    });

    test('registerChips dynamically populates backend status colors', () {
      final chips = [
        const StatusChipModel(
          id: 1,
          code: 'NEW',
          label: 'New',
          colorCode: '#0284C7',
          sortOrder: 1,
          isActive: true,
        ),
        const StatusChipModel(
          id: 2,
          code: 'DONE',
          label: 'Completed',
          colorCode: '#059669',
          sortOrder: 2,
          isActive: true,
        ),
      ];

      StatusColorService.registerChips(chips);

      expect(StatusColorService.getColor('NEW'), const Color(0xFF0284C7));
      expect(StatusColorService.getColor('New'), const Color(0xFF0284C7));
      expect(StatusColorService.getColor('DONE'), const Color(0xFF059669));
      expect(StatusColorService.getColor('Completed'), const Color(0xFF059669));
    });

    test('getBadgeColors returns consistent bg, text, and dot colors', () {
      final badge = StatusColorService.getBadgeColors('Completed');
      expect(badge.text, const Color(0xFF10B981));
      expect(badge.dot, const Color(0xFF10B981));
      expect(badge.bg, const Color(0xFF10B981).withValues(alpha: 0.12));
    });

    test('getAvatarColors returns consistent background and icon colors', () {
      final avatar = StatusColorService.getAvatarColors(
        'Cancelled',
        customColor: const Color(0xFFEF4444),
      );
      expect(avatar.icon, const Color(0xFFEF4444));
      expect(avatar.background, const Color(0xFFEF4444).withValues(alpha: 0.15));
    });

    test('BookingModel parses statusColorCode from backend and toChatItem uses it', () {
      final booking = BookingModel.fromJson({
        'id': 101,
        'name': 'Test User',
        'mobile': '9876543210',
        'address': 'Kozhikode',
        'notes': 'Urgent',
        'status': 'Scheduled',
        'status_color_code': '#F59E0B',
        'stateName': 'Kerala',
        'districtName': 'Kozhikode',
        'areaName': 'Beach',
        'documents': [],
      });

      expect(booking.statusColorCode, '#F59E0B');

      final item = booking.toChatItem();
      expect(item['tagTextColor'], const Color(0xFFF59E0B));
      expect(item['avatarTextColor'], const Color(0xFFF59E0B));
    });

    test('CustomerDetailsModel stores statusColorCode and applies to customer header badge', () {
      const customer = CustomerDetailsModel(
        id: '1',
        name: 'Arun',
        inquiry: 'Door enquiry',
        status: 'Completed',
        phoneNumber: '9876543210',
        addressLine1: 'Test Address',
        addressLine2: 'Kozhikode',
        statusColorCode: '#10B981',
      );

      final badgeColors = StatusColorService.getBadgeColors(
        customer.status,
        customColor: StatusColorService.parseHexColor(customer.statusColorCode),
      );

      expect(badgeColors.text, const Color(0xFF10B981));
      expect(badgeColors.dot, const Color(0xFF10B981));
    });
  });
}


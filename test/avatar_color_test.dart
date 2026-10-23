import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/widgets/user_circle_avatar.dart';
import 'package:task_chat/today/widgets/chat_list_item_tile.dart';

void main() {
  group('Avatar letter-pair color rules', () {
    test('PZ pair has the same colour', () {
      final pColor = getAvatarColorsForName('Peter');
      final zColor = getAvatarColorsForName('Zack');
      expect(pColor.background, equals(zColor.background));
      expect(pColor.icon, equals(zColor.icon));
    });

    test('AQ pair has the same colour', () {
      final aColor = getAvatarColorsForName('Alice');
      final qColor = getAvatarColorsForName('Quincy');
      expect(aColor.background, equals(qColor.background));
      expect(aColor.icon, equals(qColor.icon));
    });

    test('BR pair has the same colour', () {
      final bColor = getAvatarColorsForName('Bob');
      final rColor = getAvatarColorsForName('Rahul');
      expect(bColor.background, equals(rColor.background));
      expect(bColor.icon, equals(rColor.icon));
    });

    test('CS pair has the same colour', () {
      final cColor = getAvatarColorsForName('Charlie');
      final sColor = getAvatarColorsForName('Sneha');
      expect(cColor.background, equals(sColor.background));
      expect(cColor.icon, equals(sColor.icon));
    });

    test('DT pair has the same colour', () {
      final dColor = getAvatarColorsForName('David');
      final tColor = getAvatarColorsForName('Tom');
      expect(dColor.background, equals(tColor.background));
      expect(dColor.icon, equals(tColor.icon));
    });

    test('EU pair has the same colour', () {
      final eColor = getAvatarColorsForName('Elena');
      final uColor = getAvatarColorsForName('Uma');
      expect(eColor.background, equals(uColor.background));
      expect(eColor.icon, equals(uColor.icon));
    });

    test('FV pair has the same colour', () {
      final fColor = getAvatarColorsForName('Farhan');
      final vColor = getAvatarColorsForName('Varun');
      expect(fColor.background, equals(vColor.background));
      expect(fColor.icon, equals(vColor.icon));
    });

    test('GW pair has the same colour', () {
      final gColor = getAvatarColorsForName('George');
      final wColor = getAvatarColorsForName('Walter');
      expect(gColor.background, equals(wColor.background));
      expect(gColor.icon, equals(wColor.icon));
    });

    test('HX pair has the same colour', () {
      final hColor = getAvatarColorsForName('Harry');
      final xColor = getAvatarColorsForName('Xavier');
      expect(hColor.background, equals(xColor.background));
      expect(hColor.icon, equals(xColor.icon));
    });

    test('IY pair has the same colour', () {
      final iColor = getAvatarColorsForName('Isaac');
      final yColor = getAvatarColorsForName('Yusuf');
      expect(iColor.background, equals(yColor.background));
      expect(iColor.icon, equals(yColor.icon));
    });

    test('Case-insensitivity applies to letter matching', () {
      expect(getAvatarColorsForName('peter').background, equals(getAvatarColorsForName('Zack').background));
      expect(getAvatarColorsForName('alice').background, equals(getAvatarColorsForName('quincy').background));
      expect(getAvatarColorsForName('rahul').background, equals(getAvatarColorsForName('bob').background));
    });

    test('The 10 pairs have unique distinct colors from each other', () {
      final pairs = [
        getAvatarColorsForName('P'),
        getAvatarColorsForName('A'),
        getAvatarColorsForName('B'),
        getAvatarColorsForName('C'),
        getAvatarColorsForName('D'),
        getAvatarColorsForName('E'),
        getAvatarColorsForName('F'),
        getAvatarColorsForName('G'),
        getAvatarColorsForName('H'),
        getAvatarColorsForName('I'),
      ];

      final backgrounds = pairs.map((p) => p.background).toSet();
      expect(backgrounds.length, 10, reason: 'All 10 letter pairs must have distinct background colors');
    });

    testWidgets('ChatListItemTile renders avatar with name-resolved color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatListItemTile(
              title: 'Peter Parker',
              date: '23/10/2026',
              tagText: 'Scheduled',
              location: 'Kochi',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(UserCircleAvatar),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      final containerWidget = tester.widget<Container>(containerFinder);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(getAvatarColorsForName('P').background));
    });
  });
}

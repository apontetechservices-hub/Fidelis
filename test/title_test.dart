import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/features/rosary/mystery_data.dart';

void main() {
  test('es mystery titles', () {
    print('JOYFUL-ES: ${MysteryData.getMysteries('joyful').first.title('es')}');
    print('GLORIOUS-ES: ${MysteryData.getMysteries('glorious').first.title('es')}');
    print('JOYFUL-EN: ${MysteryData.getMysteries('joyful').first.title('en')}');
  });
}

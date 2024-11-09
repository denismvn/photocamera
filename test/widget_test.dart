import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:photocamera/main.dart';

void main() {
  testWidgets('Test MyApp', (WidgetTester tester) async {
    // Инициализация необходимых ресурсов
    final cameras = await availableCameras(); // Получаем доступные камеры

    // Запускаем приложение
    await tester.pumpWidget(MyApp(cameras));

    // Проверяем, что приложение запустилось
    expect(find.byType(MyApp), findsOneWidget);
    
    // Можно добавить дополнительные проверки для других виджетов
  });
}

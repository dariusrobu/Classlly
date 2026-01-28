import 'package:home_widget/home_widget.dart';

class WidgetService {
  // static const String _appGroupId = 'group.com.classlly.app'; // Replace with actual App Group ID if known, or use a placeholder
  static const String _iOSWidgetName =
      'ClassllyWidgets'; // Replace with actual iOS widget name
  static const String _androidWidgetName =
      'ClassllyWidget'; // Replace with actual Android widget name

  Future<void> refreshUpNextWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iOSWidgetName,
        qualifiedAndroidName: 'com.classlly.app.ClassllyWidget',
      );
    } catch (e) {
      // Handle error or log it
      print('Error updating widget: $e');
    }
  }

  Future<void> saveWidgetData(String key, String value) async {
    try {
      await HomeWidget.saveWidgetData<String>(key, value);
      await refreshUpNextWidget();
    } catch (e) {
      print('Error saving widget data: $e');
    }
  }
}

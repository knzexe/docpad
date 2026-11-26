class Breakpoints {
  static const double mobile = 720;
  static const double desktop = 1100;
  static const double editorColumns = 900;

  static bool isMobile(double width) => width < mobile;

  static bool isDesktop(double width) => width >= desktop;

  static bool usesCompactActions(double width) => width < desktop;

  static bool usesEditorColumns(double width) => width >= editorColumns;
}

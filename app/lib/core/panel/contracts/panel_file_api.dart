abstract class PanelFileApi {
  Future<Map<String, dynamic>> searchFiles(Map<String, dynamic> body);

  Future<Map<String, dynamic>> loadFileContent(Map<String, dynamic> body);

  Future<Map<String, dynamic>> readFileByLine(Map<String, dynamic> body);
}

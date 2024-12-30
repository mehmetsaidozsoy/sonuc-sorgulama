import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;

class ExcelService {
  Excel? _excel;
  Map<String, int>? _columnIndices;
  String? _currentSheet;

  Future<void> _loadExcel() async {
    if (_excel != null) return;

    try {
      final ByteData data = await rootBundle.load('assets/BakSonuc2024.xlsx');
      final bytes = data.buffer.asUint8List();
      _excel = Excel.decodeBytes(bytes);
      print('Excel dosyası yüklendi. Sayfa sayısı: ${_excel!.sheets.length}');
      print('Sayfalar: ${_excel!.sheets.keys.join(', ')}');
    } catch (e) {
      print('Excel yükleme hatası: $e');
      rethrow;
    }
  }

  Future<void> _initializeSheet(String sheetName) async {
    await _loadExcel();
    if (_excel == null) throw Exception('Excel dosyası yüklenemedi');

    if (_currentSheet == sheetName && _columnIndices != null) return;

    final sheet = _excel!.sheets[sheetName];
    if (sheet == null) {
      print('Sayfa bulunamadı: $sheetName');
      throw Exception('Belirtilen sayfa bulunamadı: $sheetName');
    }

    // İlk satırı başlık olarak kullan
    final headers = sheet.row(0);
    _columnIndices = {};

    for (var i = 0; i < headers.length; i++) {
      final header = headers[i]?.value?.toString().trim();
      if (header != null && header.isNotEmpty) {
        _columnIndices![header] = i;
        print('Sütun bulundu: $header -> $i');
      }
    }

    _currentSheet = sheetName;
    print('Sütun başlıkları: ${_columnIndices!.keys.join(', ')}');
  }

  String? _getCellValue(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    return row[index]?.value?.toString();
  }

  Future<Map<String, dynamic>?> searchResult(String adayNo,
      {String? sheetName}) async {
    try {
      await _initializeSheet(
          sheetName ?? _excel?.sheets.keys.first ?? 'Sayfa1');

      final sheet = _excel!.sheets[_currentSheet!]!;
      print('Aranıyor: $adayNo, Satır sayısı: ${sheet.maxRows}');

      // İlk satırdaki tüm başlıkları al
      final headers = sheet.row(0);
      final headerNames = List<String>.filled(headers.length, '');
      for (var i = 0; i < headers.length; i++) {
        headerNames[i] = headers[i]?.value?.toString().trim() ?? '';
      }

      // TC Kimlik/Aday No sütununu bul
      final idColumnIndices = headerNames
          .asMap()
          .entries
          .where((e) =>
              e.value.toUpperCase().contains('TC') ||
              e.value.toUpperCase().contains('ADAY') ||
              e.value.toUpperCase().contains('NO'))
          .map((e) => e.key)
          .toList();

      if (idColumnIndices.isEmpty) {
        print('TC Kimlik/Aday No sütunu bulunamadı');
        return null;
      }

      // Verileri ara
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;

        // Tüm olası ID sütunlarını kontrol et
        for (var idIndex in idColumnIndices) {
          final currentId = _getCellValue(row, idIndex)?.trim();
          print('Kontrol edilen satır $i, sütun $idIndex: $currentId');

          if (currentId == adayNo.trim()) {
            // Tüm sütunları otomatik olarak map'e ekle
            final result = <String, dynamic>{};
            for (var j = 0; j < headerNames.length; j++) {
              if (headerNames[j].isNotEmpty) {
                result[headerNames[j]] = _getCellValue(row, j) ?? '';
              }
            }
            print('Bulunan sonuç: $result');
            return result;
          }
        }
      }

      print('Sonuç bulunamadı: $adayNo');
      return null;
    } catch (e) {
      print('Arama hatası: $e');
      rethrow;
    }
  }
}

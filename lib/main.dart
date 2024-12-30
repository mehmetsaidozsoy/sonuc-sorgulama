import 'package:flutter/material.dart';
import 'services/excel_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonuç Sorgulama',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _adayNoController = TextEditingController();
  final ExcelService _excelService = ExcelService();
  Map<String, dynamic>? _sonuc;
  bool _yukleniyor = false;
  String? _hata;

  void _sonucSorgula() async {
    if (_adayNoController.text.isEmpty) {
      setState(() {
        _hata = 'Lütfen aday numarası giriniz';
      });
      return;
    }

    setState(() {
      _yukleniyor = true;
      _hata = null;
      _sonuc = null;
    });

    try {
      final sonuc = await _excelService.searchResult(_adayNoController.text);
      if (mounted) {
        setState(() {
          _sonuc = sonuc != null ? Map<String, dynamic>.from(sonuc) : null;
          if (sonuc == null) {
            _hata = 'Sonuç bulunamadı';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hata = 'Bir hata oluştu: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonuç Sorgulama'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _adayNoController,
                          decoration: const InputDecoration(
                            labelText: 'Aday Numarası',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            hintText: 'Örnek: 19856576615',
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) => _sonucSorgula(),
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _yukleniyor ? null : _sonucSorgula,
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _yukleniyor ? Colors.grey : Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_yukleniyor)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.search,
                                        color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _yukleniyor ? 'Sorgulanıyor...' : 'Sorgula',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_hata != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _hata!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_sonuc != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _sonuc!.entries
                                    .firstWhere(
                                      (e) =>
                                          e.key.toUpperCase().contains('AD') ||
                                          e.key.toUpperCase().contains('İSİM'),
                                      orElse: () => const MapEntry('', ''),
                                    )
                                    .value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _sonuc!.entries
                                    .firstWhere(
                                      (e) =>
                                          e.key.toUpperCase().contains('NO') ||
                                          e.key.toUpperCase().contains('TC'),
                                      orElse: () => const MapEntry('', ''),
                                    )
                                    .value,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSection(
                                'Genel Bilgiler',
                                _sonuc!.entries
                                    .where((e) =>
                                        (e.key
                                                .toUpperCase()
                                                .contains('SINIF') ||
                                            e.key
                                                .toUpperCase()
                                                .contains('GRUP') ||
                                            e.key
                                                .toUpperCase()
                                                .contains('ŞUBE')) &&
                                        !e.key.toUpperCase().contains('PUAN'))
                                    .toList(),
                              ),
                              const Divider(height: 32),
                              _buildSection(
                                'Ders Puanları',
                                _sonuc!.entries
                                    .where((e) =>
                                        !e.key
                                            .toUpperCase()
                                            .contains('TOPLAM') &&
                                        (e.value.toString().contains('.') ||
                                            e.key
                                                .toUpperCase()
                                                .contains('PUAN') ||
                                            e.key
                                                .toUpperCase()
                                                .contains('NOT')))
                                    .toList(),
                              ),
                              const Divider(height: 32),
                              _buildSection(
                                'Sonuç',
                                _sonuc!.entries
                                    .where((e) =>
                                        e.key
                                            .toUpperCase()
                                            .contains('TOPLAM') ||
                                        e.key.toUpperCase().contains('SONUÇ') ||
                                        e.key.toUpperCase().contains('DURUM') ||
                                        e.key
                                            .toUpperCase()
                                            .contains('AÇIKLAMA'))
                                    .toList(),
                                isResult: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<MapEntry<String, dynamic>> entries,
      {bool isResult = false}) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isResult ? Colors.blue : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((entry) {
          final value = entry.value.toString();
          final isNumeric = double.tryParse(value) != null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${entry.key}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight:
                          isNumeric ? FontWeight.bold : FontWeight.normal,
                      color: isResult ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: double.tryParse(value) != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _adayNoController.dispose();
    super.dispose();
  }
}

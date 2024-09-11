import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart' as pdfLib;
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:example/widgets/chat_input_box.dart';

class SectionChat extends StatefulWidget {
  const SectionChat({super.key});

  @override
  State<SectionChat> createState() => _SectionChatState();
}

class _SectionChatState extends State<SectionChat> {
  final controller = TextEditingController();
  final gemini = Gemini.instance;
  bool _loading = false;
  bool get loading => _loading;
  set loading(bool set) => setState(() => _loading = set);

  final List<Content> chats = [];
  String pdfText = '';

  @override
  void initState() {
    super.initState();
    loadPdfText(); // PDF 텍스트 로딩
  }

  Future<void> loadPdfText() async {
    try {
      // PDF 다운로드
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/photo2story/flutter_gemini_chat/master/example/data/20231226_Guide_1000.pdf'));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/guide.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Syncfusion을 사용해 PDF 텍스트 추출
        final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
        pdfText = PdfTextExtractor(document).extractText();
        print('Extracted PDF text: $pdfText');

        setState(() {
          // 상태 업데이트하여 PDF 텍스트 로드 완료
        });

        document.dispose(); // 메모리 해제
      } else {
        throw Exception('Failed to load PDF');
      }
    } catch (e) {
      print('Error loading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: chats.isNotEmpty
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      reverse: true,
                      child: ListView.builder(
                        itemBuilder: chatItem,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chats.length,
                        reverse: false,
                      ),
                    ),
                  )
                : const Center(child: Text('Search something!'))),
        if (loading) const CircularProgressIndicator(),
        ChatInputBox(
          controller: controller,
          onSend: () {
            if (controller.text.isNotEmpty) {
              final searchedText = controller.text;
              chats.add(Content(
                  role: 'user', parts: [Parts(text: searchedText)]));
              controller.clear();
              loading = true;

              gemini.chat(chats).then((value) {
                final output = searchInPdf(searchedText);
                chats.add(Content(
                    role: 'model', parts: [Parts(text: output)]));
                loading = false;
              });
            }
          },
        ),
      ],
    );
  }

  String searchInPdf(String query) {
    // PDF 텍스트에서 사용자가 입력한 내용을 검색
    if (pdfText.contains(query)) {
      return 'Found in PDF: $query';
    } else {
      return 'Not found in PDF.';
    }
  }

  Widget chatItem(BuildContext context, int index) {
    final Content content = chats[index];

    return Card(
      elevation: 0,
      color: content.role == 'model'
          ? Colors.blue.shade800
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.role ?? 'role'),
            Markdown(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                data: content.parts?.lastOrNull?.text ??
                    'cannot generate data!'),
          ],
        ),
      ),
    );
  }
}

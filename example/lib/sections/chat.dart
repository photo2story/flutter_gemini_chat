import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';  // To store the file locally
import 'package:syncfusion_flutter_pdf/pdf.dart';   // To extract text from PDF

class SectionChat extends StatefulWidget {
  const SectionChat({super.key});

  @override
  State<SectionChat> createState() => _SectionChatState();
}

class _SectionChatState extends State<SectionChat> {
  final controller = TextEditingController();
  bool _loading = false;
  List<String> chats = [];

  final String githubPdfUrl = "https://raw.githubusercontent.com/photo2story/flutter_gemini_chat/master/example/data/20231226_Guide_1000.pdf";

  // Function to download and read PDF using syncfusion_flutter_pdf
  Future<String> fetchPdfFromGithub(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/temp_guide.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Load the PDF document
        final List<int> bytes = file.readAsBytesSync();
        final PdfDocument document = PdfDocument(inputBytes: bytes);

        // Extract text from the first page
        String text = PdfTextExtractor(document).extractText(startPageIndex: 0, endPageIndex: 0);
        document.dispose();

        return text;
      } else {
        throw Exception('Failed to load PDF. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching PDF: $e");
      return 'Error fetching PDF: $e';
    }
  }

  void handlePdfChat(String pdfUrl) async {
    setState(() => _loading = true);
    String extractedText = await fetchPdfFromGithub(pdfUrl);

    setState(() {
      chats.add("PDF 첫 페이지 내용: $extractedText");
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with PDF'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(chats[index]),
                );
              },
            ),
          ),
          if (_loading) const CircularProgressIndicator(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Type a message...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (controller.text.startsWith("/pdf")) {
                    controller.clear();
                    handlePdfChat(githubPdfUrl);  // Fetch PDF from GitHub
                  } else if (controller.text.isNotEmpty) {
                    setState(() {
                      chats.add(controller.text);
                      controller.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

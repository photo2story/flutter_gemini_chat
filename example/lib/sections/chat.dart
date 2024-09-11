// chat.dart


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_text/pdf_text.dart';

class SectionChat extends StatefulWidget {
  const SectionChat({super.key});

  @override
  State<SectionChat> createState() => _SectionChatState();
}

class _SectionChatState extends State<SectionChat> {
  final TextEditingController controller = TextEditingController();
  bool _loading = false;
  List<String> chats = [];

  // Function to extract text from the first page of a PDF
  Future<String> fetchFirstPageText() async {
    try {
      final filePath = 'C:/Users/user/OneDrive/Work/Source/Repos/flutter_gemini_chat/example/data/20231226_Guide_1000.pdf';
      final file = File(filePath);

      if (await file.exists()) {
        PDFDoc doc = await PDFDoc.fromFile(file);

        // Get text from the first page
        String firstPageText = await doc.pageAt(1).text;

        return firstPageText;
      } else {
        return 'PDF 파일을 찾을 수 없습니다.';
      }
    } catch (e) {
      print("PDF 파일을 읽는 중 오류가 발생했습니다: $e");
      return 'PDF 파일을 읽는 중 오류가 발생했습니다.';
    }
  }

  // Function to send the extracted text to the chat
  void handlePdfToChat() async {
    setState(() => _loading = true);

    // Fetch the first page text from the PDF
    String pdfText = await fetchFirstPageText();

    // Add PDF content as user input
    setState(() {
      chats.add("PDF 첫 페이지: $pdfText");
      _loading = false;
    });
  }

  // Regular message sending function
  void onSend() {
    final userMessage = controller.text;
    setState(() {
      chats.add(userMessage);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with PDF'),
        actions: [
          // Button to fetch and send PDF first page text
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: handlePdfToChat,  // Send PDF first page text to chat
          ),
        ],
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
          // Text Input and Send Button
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
                  if (controller.text.isNotEmpty) {
                    onSend();  // Send user text to chat
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

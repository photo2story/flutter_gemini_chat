// chat.dart


import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:pdf/widgets.dart' as pdf_package;
import 'package:pdf/pdf.dart';

// New dependency to extract text from PDFs
import 'package:pdf_text/pdf_text.dart';

class SectionChat extends StatefulWidget {
  const SectionChat({super.key});

  @override
  State<SectionChat> createState() => _SectionChatState();
}

class _SectionChatState extends State<SectionChat> {
  final controller = TextEditingController();
  final gemini = Gemini.instance;
  bool _loading = false;

  // List to store chat messages
  final List<Content> chats = [];

  // Function to download and parse PDF from GitHub URL
  Future<String> fetchPdfFromGithub(String url) async {
    try {
      // Download the PDF file from the GitHub URL
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final file = File('/tmp/temp.pdf');
        await file.writeAsBytes(response.bodyBytes);

        // Extract text using pdf_text package
        PDFDoc doc = await PDFDoc.fromFile(file);
        String pdfText = await doc.text;

        return pdfText;
      } else {
        throw Exception('Failed to load PDF');
      }
    } catch (e) {
      print("Error fetching PDF: $e");
      return 'Error fetching PDF';
    }
  }

  // Function to handle Gemini chat based on PDF
  void handlePdfChat(String pdfUrl) async {
    loading = true;
    // Fetch and extract text from PDF
    String extractedText = await fetchPdfFromGithub(pdfUrl);

    // Add PDF content as user input
    chats.add(Content(role: 'user', parts: [Parts(text: extractedText)]));

    // Call Gemini API to generate a response
    final response = await gemini.chat(chats);

    // Add Gemini model response to the chat
    chats.add(Content(
      role: 'model',
      parts: [Parts(text: response?.output ?? "No response")],
    ));

    loading = false;
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
              : const Center(child: Text('Start chatting!')),
        ),
        if (loading) const CircularProgressIndicator(),
        ChatInputBox(
          controller: controller,
          onSend: () {
            if (controller.text.startsWith("/pdf ")) {
              // If user sends a PDF command (e.g., /pdf URL)
              final pdfUrl = controller.text.replaceFirst("/pdf ", "");
              controller.clear();
              handlePdfChat(pdfUrl);
            } else if (controller.text.isNotEmpty) {
              final userText = controller.text;
              chats.add(Content(role: 'user', parts: [Parts(text: userText)]));
              controller.clear();
              loading = true;

              gemini.chat(chats).then((value) {
                chats.add(Content(
                    role: 'model', parts: [Parts(text: value?.output)]));
                loading = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget chatItem(BuildContext context, int index) {
    final Content content = chats[index];
    return Card(
      elevation: 0,
      color:
          content.role == 'model' ? Colors.blue.shade800 : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.role ?? 'role'),
            Text(content.parts?.lastOrNull?.text ?? 'cannot generate data!'),
          ],
        ),
      ),
    );
  }
}

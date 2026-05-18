import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  // Correo de contacto para aumentar la cuota diaria gratuita a 50,000 caracteres
  static const String _contactEmail = 'cristian.cifuentes.smartpantry@gmail.com';

  /// Traduce un texto del inglés al español (o viceversa) de forma asíncrona.
  /// Divide textos largos en fragmentos pequeños para no sobrepasar el límite de la API de 400-500 caracteres.
  Future<String> translate(String text, {String from = 'en', String to = 'es'}) async {
    if (text.trim().isEmpty) return text;

    // Si el texto es corto, se traduce directamente
    if (text.length <= 400) {
      return await _translateChunk(text, from: from, to: to);
    }

    // Dividimos por saltos de línea para preservar el formato original
    List<String> paragraphs = text.split('\n');
    List<String> translatedParagraphs = [];

    for (String paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) {
        translatedParagraphs.add('');
        continue;
      }

      // Si un párrafo individual es demasiado largo, lo dividimos por oraciones
      if (paragraph.length > 400) {
        List<String> sentences = paragraph.split(RegExp(r'(?<=\.)\s+'));
        List<String> translatedSentences = [];
        
        for (String sentence in sentences) {
          if (sentence.trim().isNotEmpty) {
            String translatedSentence = await _translateChunk(sentence, from: from, to: to);
            translatedSentences.add(translatedSentence);
          }
        }
        translatedParagraphs.add(translatedSentences.join(' '));
      } else {
        String translatedParagraph = await _translateChunk(paragraph, from: from, to: to);
        translatedParagraphs.add(translatedParagraph);
      }
    }

    return translatedParagraphs.join('\n');
  }

  /// Petición HTTP individual de un trozo corto de texto
  Future<String> _translateChunk(String chunk, {required String from, required String to}) async {
    try {
      final encodedText = Uri.encodeComponent(chunk);
      final url = Uri.parse('$_baseUrl?q=$encodedText&langpair=$from|$to&de=$_contactEmail');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['responseData'] != null && data['responseData']['translatedText'] != null) {
          final translated = data['responseData']['translatedText'] as String;
          // Decodificar entidades HTML si la API devuelve algo como &#39;
          return _decodeHtmlEntities(translated);
        }
      }
    } catch (e) {
      print("Error traduciendo fragmento: $e");
    }
    return chunk; // En caso de error, devolvemos el texto original
  }

  /// Utilidad sencilla para limpiar algunas entidades HTML comunes que la API de MyMemory puede retornar
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&deg;', '°');
  }
}

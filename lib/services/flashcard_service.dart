import '../models/app_models.dart';

class FlashcardService {
  final List<FlashcardItem> _defaultFlashcards = [
    // 1. Math & Numeracy
    FlashcardItem(
      id: 'fc01',
      hindiWord: 'गणित',
      tribalWord: 'ᱞᱮᱠᱷᱟ (लेखा)',
      englishMeaning: 'Mathematics',
      phonetic: 'Lekha',
      iconSymbol: '🔢',
      exampleSentenceHindi: 'आज हम गणित सीखेंगे।',
      exampleSentenceTribal: 'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱞᱮᱠᱷᱟ ᱵᱚᱱ ᱪᱮᱫᱟ᱾',
    ),
    FlashcardItem(
      id: 'fc02',
      hindiWord: 'गिनती (१ से १०)',
      tribalWord: 'ᱢᱤᱫ ᱠᱷᱚᱱ ᱜᱮᱞ (मिद खोन गेल)',
      englishMeaning: 'Counting 1 to 10',
      phonetic: 'Mid khon gel',
      iconSymbol: '🧮',
      exampleSentenceHindi: 'एक से दस तक गिनती करो।',
      exampleSentenceTribal: 'ᱢᱤᱫ ᱠᱷᱚᱱ ᱜᱮᱞ ᱦᱟᱹᱵᱤᱡ ᱞᱮᱠᱷᱟᱭ ᱢᱮ᱾',
    ),
    FlashcardItem(
      id: 'fc03',
      hindiWord: 'एक',
      tribalWord: 'ᱢᱤᱫ (मिद)',
      englishMeaning: 'One (1)',
      phonetic: 'Mid',
      iconSymbol: '1️⃣',
      exampleSentenceHindi: 'एक सेब लाओ।',
      exampleSentenceTribal: 'ᱢᱤᱫᱴᱟᱝ ᱥᱮᱣ ᱟᱹᱜᱩᱭ ᱢᱮ᱾',
    ),
    FlashcardItem(
      id: 'fc04',
      hindiWord: 'दो',
      tribalWord: 'ᱵᱟᱨ (बार)',
      englishMeaning: 'Two (2)',
      phonetic: 'Bar',
      iconSymbol: '2️⃣',
      exampleSentenceHindi: 'दो हाथ जोड़ो।',
      exampleSentenceTribal: 'ᱵᱟᱨᱭᱟ ᱛᱤ ᱡᱚᱲᱟᱣ ᱢᱮ᱾',
    ),
    FlashcardItem(
      id: 'fc05',
      hindiWord: 'दस',
      tribalWord: 'ᱜᱮᱞ (गेल)',
      englishMeaning: 'Ten (10)',
      phonetic: 'Gel',
      iconSymbol: '🔟',
      exampleSentenceHindi: 'दस उंगलियां गिनो।',
      exampleSentenceTribal: 'ᱜᱮᱞᱴᱟᱝ ᱠᱟ ᱴᱩ ᱞᱮᱠᱷᱟᱭ ᱢᱮ᱾',
    ),

    // 2. Science & Nature
    FlashcardItem(
      id: 'fc06',
      hindiWord: 'पौधा',
      tribalWord: 'ᱫᱟᱨᱮ (दारे)',
      englishMeaning: 'Plant',
      phonetic: 'Dare',
      iconSymbol: '🌱',
      exampleSentenceHindi: 'पौधे को पानी दो।',
      exampleSentenceTribal: 'ᱫᱟᱨᱮ ᱨᱮ ᱫᱟᱜ ᱫᱩᱞ ᱢᱮ᱾',
    ),
    FlashcardItem(
      id: 'fc07',
      hindiWord: 'पेड़',
      tribalWord: 'ᱫᱟᱨᱮ (दारे)',
      englishMeaning: 'Tree',
      phonetic: 'Dare',
      iconSymbol: '🌳',
      exampleSentenceHindi: 'पेड़ हमें हवा देते हैं।',
      exampleSentenceTribal: 'ᱫᱟᱨᱮ ᱟᱵᱚ ᱦᱚᱭ ᱮᱢᱟᱵᱚᱱᱟ᱾',
    ),
    FlashcardItem(
      id: 'fc08',
      hindiWord: 'पानी',
      tribalWord: 'ᱫᱟᱜ (दाग)',
      englishMeaning: 'Water',
      phonetic: 'Dag',
      iconSymbol: '💧',
      exampleSentenceHindi: 'साफ पानी पीना चाहिए।',
      exampleSentenceTribal: 'ᱥᱟᱯᱷᱟ ᱫᱟᱜ ᱧᱩ ᱞᱟᱹᱠᱛᱤ ᱟ᱾',
    ),
    FlashcardItem(
      id: 'fc09',
      hindiWord: 'धूप / सूरज',
      tribalWord: 'ᱥᱤᱛᱩᱝ (सितुंग)',
      englishMeaning: 'Sunlight / Sun',
      phonetic: 'Situng',
      iconSymbol: '☀️',
      exampleSentenceHindi: 'सूरज पूरब में उगता है।',
      exampleSentenceTribal: 'ᱥᱤ ᱥᱟ ᱨᱮ ᱨᱟ ᱟ᱾',
    ),
    FlashcardItem(
      id: 'fc10',
      hindiWord: 'हवा',
      tribalWord: 'ᱦᱚᱭ (होय)',
      englishMeaning: 'Air / Wind',
      phonetic: 'Hoy',
      iconSymbol: '🌬️',
      exampleSentenceHindi: 'ताजी हवा सांस लेने के लिए अच्छी है।',
      exampleSentenceTribal: 'ᱱᱟᱯᱟᱭ ᱦᱚᱭ ᱥᱟᱦᱮᱫ ᱞᱟᱹᱜᱤᱫ ᱵᱩ ᱟ᱾',
    ),
    FlashcardItem(
      id: 'fc11',
      hindiWord: 'पृथ्वी / धरती',
      tribalWord: 'ᱫᱷᱟᱹᱨᱛᱤ (धर्ती)',
      englishMeaning: 'Earth',
      phonetic: 'Dharti',
      iconSymbol: '🌍',
      exampleSentenceHindi: 'धरती हमारी माता है।',
      exampleSentenceTribal: 'ᱫᱷᱟᱹᱨᱛᱤ ᱟᱵᱚᱨᱤᱱ ᱟ ᱟ᱾',
    ),

    // 3. Classroom Instructions & School Life
    FlashcardItem(
      id: 'fc12',
      hindiWord: 'किताब',
      tribalWord: 'ᱯᱩᱛᱷᱤ (पुथि)',
      englishMeaning: 'Book',
      phonetic: 'Puthi',
      iconSymbol: '📖',
      exampleSentenceHindi: 'अपनी किताब खोलो।',
      exampleSentenceTribal: 'ᱟᱯᱱᱟᱨᱟ ᱯᱩᱛᱷᱤ ᱡᱷᱤ ᱢᱮ᱾',
    ),
    FlashcardItem(
      id: 'fc13',
      hindiWord: 'कलम',
      tribalWord: 'ᱠᱚᱞᱚᱢ (कलम)',
      englishMeaning: 'Pen / Pencil',
      phonetic: 'Kolom',
      iconSymbol: '✏️',
      exampleSentenceHindi: 'कलम से लिखो।',
      exampleSentenceTribal: 'ᱠᱚᱞᱚᱢ ᱛᱮ ᱚᱞ ᱢᱮ᱾',
    ),
    FlashcardItem(
      id: 'fc14',
      hindiWord: 'स्कूल',
      tribalWord: 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ (इतुन असड़ा)',
      englishMeaning: 'School',
      phonetic: 'Itun Asda',
      iconSymbol: '🏫',
      exampleSentenceHindi: 'बच्चे स्कूल जा रहे हैं।',
      exampleSentenceTribal: 'ᱜᱤ ᱠᱚ ᱤ ᱠᱚ ᱪᱟᱞᱟ ᱠᱟᱱᱟ᱾',
    ),
    FlashcardItem(
      id: 'fc15',
      hindiWord: 'शिक्षक',
      tribalWord: 'ᱢᱟᱪᱮᱛ (माचेत)',
      englishMeaning: 'Teacher',
      phonetic: 'Machet',
      iconSymbol: '👨‍🏫',
      exampleSentenceHindi: 'शिक्षक पाठ पढ़ाते हैं।',
      exampleSentenceTribal: 'ᱢᱟᱪᱮᱛ ᱯᱟᱴᱷ ᱯᱟᱲᱦᱟᱣᱟᱭ᱾',
    ),
    FlashcardItem(
      id: 'fc16',
      hindiWord: 'छात्र',
      tribalWord: 'ᱪᱮᱛᱮᱫᱤ (चेतेदिया)',
      englishMeaning: 'Student',
      phonetic: 'Chetediya',
      iconSymbol: '🎒',
      exampleSentenceHindi: 'छात्र ध्यान से सुनते हैं।',
      exampleSentenceTribal: 'ᱪᱮᱛᱮᱫᱤ ᱫᱷᱮᱭᱟᱱ ᱛᱮᱠᱚ ᱟ ᱟ᱾',
    ),

    // 4. Greetings & Classroom Praise
    FlashcardItem(
      id: 'fc17',
      hindiWord: 'नमस्ते',
      tribalWord: 'ᱡᱚᱦᱟᱨ (जोहार)',
      englishMeaning: 'Greeting / Hello',
      phonetic: 'Johar',
      iconSymbol: '🙏',
      exampleSentenceHindi: 'नमस्ते बच्चों, आप सब कैसे हैं?',
      exampleSentenceTribal: 'ᱡᱚᱦᱟᱨ ᱜᱤ ᱠᱚ, ᱟᱯᱮ ᱪᱮ ᱞᱮᱠᱟ ᱢᱮᱱᱟ?',
    ),
    FlashcardItem(
      id: 'fc18',
      hindiWord: 'शाबाश / बहुत बढ़िया',
      tribalWord: 'ᱥᱟ ᱥ! ᱟᱹᱰᱤ ᱱᱟ ᱟᱭ (साबास! अड़ि नापाय)',
      englishMeaning: 'Well done! / Excellent',
      phonetic: 'Sabas! Adi napay',
      iconSymbol: '🌟',
      exampleSentenceHindi: 'शाबाश! बहुत बढ़िया काम किया।',
      exampleSentenceTribal: 'ᱥᱟ ᱥ! ᱟᱹᱰᱤ ᱱᱟ ᱟᱭ ᱠᱟ ᱠᱮᱫᱟ᱾',
    ),
    FlashcardItem(
      id: 'fc19',
      hindiWord: 'पढ़ना',
      tribalWord: 'ᱯᱟᱲᱦᱟᱣ (पड़ाव)',
      englishMeaning: 'To Read / Study',
      phonetic: 'Padhaw',
      iconSymbol: '📚',
      exampleSentenceHindi: 'रोज पाठ पढ़ना चाहिए।',
      exampleSentenceTribal: 'ᱫᱤᱱᱟ ᱯᱟ ᱯᱟᱲᱦᱟᱣ ᱞᱟ ᱟ᱾',
    ),
    FlashcardItem(
      id: 'fc20',
      hindiWord: 'लिखना',
      tribalWord: 'ᱚᱞ (ओल)',
      englishMeaning: 'To Write',
      phonetic: 'Ol',
      iconSymbol: '✍️',
      exampleSentenceHindi: 'कॉपी में लिखो।',
      exampleSentenceTribal: 'ᱠᱚ ᱨᱮ ᱚᱞ ᱢᱮ᱾',
    ),
  ];

  List<FlashcardItem> getFlashcardsForSession(List<TranslationResult> sessionLogs) {
    final list = List<FlashcardItem>.from(_defaultFlashcards);

    // Extract dynamic vocabulary from session logs
    for (var log in sessionLogs) {
      if (log.originalText.contains('एक') || log.originalText.contains('गिनती')) {
        if (!list.any((fc) => fc.id == 'fc_dyn_num')) {
          list.insert(
            0,
            FlashcardItem(
              id: 'fc_dyn_num',
              hindiWord: 'गिनती (1-10)',
              tribalWord: 'ᱢᱤ ᱠᱷᱚᱱ ᱜᱮᱞ (मिद खोन गेल)',
              englishMeaning: 'Counting (1 to 10)',
              phonetic: 'Mid khon gel',
              iconSymbol: '🧮',
              exampleSentenceHindi: 'एक से दस तक गिनती करो।',
              exampleSentenceTribal: 'ᱢᱤ ᱠᱷᱚᱱ ᱜᱮᱞ ᱦᱟ ᱞᱮᱠᱷᱟᱭ ᱢᱮ᱾',
            ),
          );
        }
      }
    }

    return list;
  }
}

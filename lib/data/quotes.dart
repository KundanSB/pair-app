/// A rotating "quote of the day" — both partners see the SAME quote on
/// the same calendar day, computed purely client-side (no API, no cost).
class Quotes {
  static const List<String> _quotes = [
    "Distance means so little when someone means so much.",
    "The best thing to hold onto in life is each other.",
    "Home isn't a place, it's a person.",
    "Every love story is beautiful, but ours is my favorite.",
    "You are my today and all of my tomorrows.",
    "Being deeply loved gives you strength; loving deeply gives you courage.",
    "In your smile, I see something more beautiful than the stars.",
    "Together is a wonderful place to be, even miles apart.",
    "I love you not only for what you are, but for what I am when I'm with you.",
    "A thousand miles can't keep two hearts apart.",
    "You are my favorite notification.",
    "Some people are worth melting for.",
    "Love doesn't need to be perfect, it just needs to be true.",
    "Wherever you are is my favorite place.",
    "Time zones can't change how much I miss you.",
    "I carry your heart with me, I carry it in my heart.",
    "You're the reason I look at my phone and smile like an idiot.",
    "Every day without you is like a book without pages.",
  ];

  static String today() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }
}

import 'package:flutter/material.dart';
import '../models/models.dart';
import 'prompt_packs.dart';
import 'screens/tictactoe_screen.dart';
import 'screens/connect_four_screen.dart';
import 'screens/rock_paper_scissors_screen.dart';
import 'screens/prompt_card_screen.dart';

enum GameCategory { boards, duels, prompts }

extension GameCategoryLabel on GameCategory {
  String get label => switch (this) {
        GameCategory.boards => 'Board games',
        GameCategory.duels => 'Quick duels',
        GameCategory.prompts => 'Conversation & card games',
      };
}

class GameDefinition {
  final String id;
  final String title;
  final String emoji;
  final GameCategory category;
  final Widget Function(Pairing pairing, bool isHost) builder;
  const GameDefinition({required this.id, required this.title, required this.emoji, required this.category, required this.builder});
}

/// THE LIST. To add a prompt-card game: write a content list in
/// prompt_packs.dart, add one entry below. To add a new mechanic: follow
/// tictactoe_screen.dart's pattern, add one entry below.
class GameCatalog {
  static final List<GameDefinition> all = [
    GameDefinition(id: 'tictactoe', title: 'Tic-Tac-Toe', emoji: '⭕', category: GameCategory.boards, builder: (p, h) => TicTacToeScreen(pairing: p, isHost: h)),
    GameDefinition(id: 'connect4', title: 'Connect Four', emoji: '🔴', category: GameCategory.boards, builder: (p, h) => ConnectFourScreen(pairing: p, isHost: h)),
    GameDefinition(id: 'rps', title: 'Rock Paper Scissors', emoji: '✊', category: GameCategory.duels, builder: (p, h) => RockPaperScissorsScreen(pairing: p, isHost: h)),
    GameDefinition(id: 'truth_or_dare', title: 'Truth or Dare', emoji: '🔥', category: GameCategory.prompts, builder: (p, h) => PromptCardScreen(pairing: p, isHost: h, title: 'Truth or Dare', deck: PromptDecks.truthOrDare)),
    GameDefinition(id: 'would_you_rather', title: 'Would You Rather', emoji: '🤔', category: GameCategory.prompts, builder: (p, h) => PromptCardScreen(pairing: p, isHost: h, title: 'Would You Rather', deck: PromptDecks.wouldYouRather)),
    GameDefinition(id: 'never_have_i_ever', title: 'Never Have I Ever', emoji: '🙈', category: GameCategory.prompts, builder: (p, h) => PromptCardScreen(pairing: p, isHost: h, title: 'Never Have I Ever', deck: PromptDecks.neverHaveIEver)),
    GameDefinition(id: 'this_or_that', title: 'This or That', emoji: '⚖️', category: GameCategory.prompts, builder: (p, h) => PromptCardScreen(pairing: p, isHost: h, title: 'This or That', deck: PromptDecks.thisOrThat)),
    GameDefinition(id: 'twenty_questions', title: '20 Questions', emoji: '💬', category: GameCategory.prompts, builder: (p, h) => PromptCardScreen(pairing: p, isHost: h, title: '20 Questions', deck: PromptDecks.twentyQuestions)),
    GameDefinition(id: 'couple_trivia', title: 'Couple Trivia', emoji: '🧠', category: GameCategory.prompts, builder: (p, h) => PromptCardScreen(pairing: p, isHost: h, title: 'Couple Trivia', deck: PromptDecks.coupleTrivia)),
  ];

  static GameDefinition byId(String id) => all.firstWhere((g) => g.id == id);
  static List<GameDefinition> inCategory(GameCategory category) => all.where((g) => g.category == category).toList();
}

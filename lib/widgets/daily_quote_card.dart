import 'package:flutter/material.dart';
import '../data/quotes.dart';
import '../theme/app_theme.dart';

class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.blush, AppTheme.lavender]),
        borderRadius: BorderRadius.circular(20),
      ),
      // Semantics: this whole card is decorative + informational, group
      // it as one block for screen readers instead of reading the icon
      // and text as two separate unlabeled elements.
      child: Semantics(
        label: 'Quote of the day: ${Quotes.today()}',
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 20, semanticLabel: ''),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                Quotes.today(),
                style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

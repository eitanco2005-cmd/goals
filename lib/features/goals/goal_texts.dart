/// Hebrew + English versions of a goal text (name or unit) and which of
/// them, if any, is a machine translation.
typedef GoalTexts = ({String he, String en, String machine});

/// The texts after someone typed [typed] while using [lang].
///
/// * New text: the other language is machine-translated.
/// * Changing the machine-translated language: a manual correction (kept,
///   nothing is translated again).
/// * Changing the other language: the machine side is translated again.
/// * Offline / no translation: the other language keeps its own text, or
///   gets [typed] when both were the same.
Future<GoalTexts> resolveGoalTexts({
  required GoalTexts? old,
  required String typed,
  required String lang,
  required Future<String?> Function(String text, String to) translate,
}) async {
  final other = lang == 'he' ? 'en' : 'he';
  GoalTexts make(String mine, String theirs, String machine) => lang == 'he'
      ? (he: mine, en: theirs, machine: machine)
      : (he: theirs, en: mine, machine: machine);

  if (typed.isEmpty) return make('', '', '');
  if (old == null) {
    final t = await translate(typed, other);
    return t == null ? make(typed, typed, '') : make(typed, t, other);
  }
  final mine = lang == 'he' ? old.he : old.en;
  final theirs = lang == 'he' ? old.en : old.he;
  if (typed == mine) return old;
  if (old.machine == lang) return make(typed, theirs, '');
  final t = await translate(typed, other);
  if (t != null) return make(typed, t, other);
  return theirs == mine || theirs.isEmpty
      ? make(typed, typed, '')
      : make(typed, theirs, old.machine);
}

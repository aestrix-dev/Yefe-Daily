class VerseModel {
  final String text;
  final String reference;
  final String date;

  const VerseModel({
    required this.text,
    required this.reference,
    required this.date,
  });

  static VerseModel get sample => const VerseModel(
    text:
        '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future."',
    reference: 'Jeremiah 29:11',
    date: 'June 9 • Day 01 of your journey',
  );
}

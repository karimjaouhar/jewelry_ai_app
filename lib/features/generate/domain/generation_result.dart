class GenerationResult {
  const GenerationResult({
    required this.imageUrls,
    this.seed,
  });

  final List<String> imageUrls;
  final int? seed;
}

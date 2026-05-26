import '../../models/complaint_type.dart';
import '../../models/sector_model.dart';

/// Rule-based smart analysis (no external AI API required).
/// Can be swapped for Cloud Functions + Gemini/OpenAI later.
class SmartAnalysisService {
  const SmartAnalysisService();

  static const _negativeWords = [
    'urgent',
    'emergency',
    'danger',
    'unsafe',
    'harassment',
    'violence',
    'broken',
    'theft',
    'flood',
    'fire',
    'abuse',
  ];

  static const _positiveWords = [
    'thank',
    'appreciate',
    'great',
    'excellent',
    'improve',
    'suggest',
    'recommend',
    'better',
  ];

  SmartAnalysisResult analyze({
    required String title,
    required String description,
    required String sectorId,
  }) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    final type = _detectType(text);
    final priority = _detectPriority(text);
    final category = _detectCategory(text, sectorId);
    final tags = _extractTags(text);
    final sentiment = _sentimentScore(text);
    final isSpam = _isSpam(text);
    final duplicateHint = _duplicateFingerprint(title, description);

    return SmartAnalysisResult(
      suggestedType: type,
      suggestedPriority: priority,
      suggestedCategory: category,
      suggestedTags: tags,
      sentimentScore: sentiment,
      isLikelySpam: isSpam,
      duplicateFingerprint: duplicateHint,
    );
  }

  ComplaintType _detectType(String text) {
    if (text.contains('suggest') ||
        text.contains('recommend') ||
        text.contains('would be better') ||
        text.contains('please add')) {
      return ComplaintType.suggestion;
    }
    return ComplaintType.complaint;
  }

  ComplaintPriority _detectPriority(String text) {
    if (text.contains('emergency') ||
        text.contains('immediate') ||
        text.contains('life threatening')) {
      return ComplaintPriority.emergency;
    }
    if (_negativeWords.any((w) => text.contains(w))) {
      return ComplaintPriority.high;
    }
    if (text.length > 400) return ComplaintPriority.medium;
    return ComplaintPriority.low;
  }

  String _detectCategory(String text, String sectorId) {
    final sector = CampusSectors.byId(sectorId);
    if (sector == null) return 'General';

    if (text.contains('food') || text.contains('meal')) return 'Food Service';
    if (text.contains('wifi') || text.contains('internet')) return 'IT';
    if (text.contains('room') || text.contains('dorm')) return 'Housing';
    if (text.contains('exam') || text.contains('grade')) return 'Academic';
    if (text.contains('fee') || text.contains('payment')) return 'Finance';
    return sector.name;
  }

  List<String> _extractTags(String text) {
    final tags = <String>[];
    for (final word in [..._negativeWords, ..._positiveWords]) {
      if (text.contains(word)) tags.add(word);
    }
    return tags.take(5).toList();
  }

  double _sentimentScore(String text) {
    var score = 0.0;
    for (final w in _negativeWords) {
      if (text.contains(w)) score -= 0.15;
    }
    for (final w in _positiveWords) {
      if (text.contains(w)) score += 0.1;
    }
    return score.clamp(-1.0, 1.0);
  }

  bool _isSpam(String text) {
    if (text.length < 15) return true;
    final repeated = RegExp(r'(.)\1{6,}');
    if (repeated.hasMatch(text)) return true;
    if (RegExp(r'(http|www\.|\.com)').allMatches(text).length > 3) return true;
    return false;
  }

  String _duplicateFingerprint(String title, String description) {
    final normalized =
        '${title.toLowerCase().trim()}|${description.toLowerCase().trim()}';
    return normalized.hashCode.toRadixString(16);
  }
}

class SmartAnalysisResult {
  const SmartAnalysisResult({
    required this.suggestedType,
    required this.suggestedPriority,
    required this.suggestedCategory,
    required this.suggestedTags,
    required this.sentimentScore,
    required this.isLikelySpam,
    required this.duplicateFingerprint,
  });

  final ComplaintType suggestedType;
  final ComplaintPriority suggestedPriority;
  final String suggestedCategory;
  final List<String> suggestedTags;
  final double sentimentScore;
  final bool isLikelySpam;
  final String duplicateFingerprint;
}

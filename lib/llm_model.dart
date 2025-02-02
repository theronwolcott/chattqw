enum LLMModelCompany {
  OpenAI('OpenAI'),
  Anthropic('Anthropic'),
  DeepSeek('DeepSeek'),
  Google('Google'),
  Meta("Meta");

  final String value;
  const LLMModelCompany(this.value);
}

class LLMModel {
  final LLMModelCompany company;
  final String name;
  final String value;
  final String short;

  LLMModel({
    required this.company,
    required this.name,
    required this.value,
    required this.short,
  });

  @override
  String toString() {
    return 'LLMModel(company: ${company.value}, name: $name, value: $value, short: $short)';
  }
}

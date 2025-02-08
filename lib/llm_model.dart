enum LLMModelCompany {
  OpenAI('OpenAI'),
  Anthropic('Anthropic'),
  DeepSeek('DeepSeek'),
  Google('Google'),
  Meta("Meta"),
  Mistral("Mistral");

  final String value;
  const LLMModelCompany(this.value);
}

class LLMModel {
  final LLMModelCompany company;
  final String name;
  // used to call the openAI API
  final String value;
  // displayed on the main page of the app
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

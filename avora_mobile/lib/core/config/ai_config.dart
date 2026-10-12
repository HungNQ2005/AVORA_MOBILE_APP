const String _inlineGroqApiKey = '';

const String groqApiKey = String.fromEnvironment(
  'GROQ_API_KEY',
  defaultValue: _inlineGroqApiKey,
);

const String groqModel = String.fromEnvironment(
  'GROQ_MODEL',
  defaultValue: 'qwen/qwen3.8-27b',
);

const String groqBaseUrl = 'https://api.groq.com/openai/v1';

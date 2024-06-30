CREATE INDEX IF NOT EXISTS Pronunciation_word ON Pronunciation (word);
CREATE INDEX IF NOT EXISTS PartOfSpeech_word ON PartOfSpeech (word);
CREATE INDEX IF NOT EXISTS PartOfSpeech_pos ON PartOfSpeech (pos);
CREATE INDEX IF NOT EXISTS SemanticLink_word1 ON SemanticLink (word1);
CREATE INDEX IF NOT EXISTS SemanticLink_word2 ON SemanticLink (word2);
CREATE INDEX IF NOT EXISTS Definitions_word ON Definitions (word);

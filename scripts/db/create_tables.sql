CREATE TABLE IF NOT EXISTS Pronunciation (
    word TEXT,
    pronunciation TEXT,
    type TEXT,
    n_syllables INT,
    PRIMARY KEY (word, pronunciation)
);


CREATE TABLE IF NOT EXISTS PartOfSpeech (
    word TEXT,
    pos TEXT,
    PRIMARY KEY (word, pos)
);


CREATE TABLE IF NOT EXISTS SemanticLink (
    word1 TEXT,
    word2 TEXT,
    pos TEXT,
    type TEXT,
    PRIMARY KEY (word1, word2, pos, type)
);


CREATE TABLE IF NOT EXISTS Definitions (
    word TEXT,
    basename TEXT,
    list_index INTEGER,
    definition TEXT
);


CREATE VIRTUAL TABLE IF NOT EXISTS DefinitionsFTS USING fts5 (
    word UNINDEXED,
    definition,
    tokenize = 'trigram case_sensitive 0 remove_diacritics 1'
);

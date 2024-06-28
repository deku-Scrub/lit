CREATE TABLE IF NOT EXISTS Pronunciation (
    word TEXT,
    pronunciation TEXT,
    type TEXT,
    n_syllables INT,
    primary key (word, pronunciation)
);


CREATE TABLE IF NOT EXISTS PartOfSpeech (
    word TEXT,
    pos TEXT,
    PRIMARY KEY (word, pos)
);


CREATE TABLE IF NOT EXISTS Synonym (
    word1 TEXT,
    word2 TEXT,
    PRIMARY KEY (word1, word2)
);


CREATE VIRTUAL TABLE IF NOT EXISTS Definition USING fts5 (
    word UNINDEXED,
    definition,
    tokenize = 'trigram case_sensitive 0 remove_diacritics 1'
);

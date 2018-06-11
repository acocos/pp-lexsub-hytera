## HyTERA: Automated Paraphrase Lattice Creation for HyTER Machine Translation Evaluation

This repo contains code from the paper:

Marianna Apidianaki, Guillaume Wisniewski, Anne Cocos, and Chris Callison-Burch. 2018. Automated Paraphrase Lattice Creation for HyTER Machine Translation Evaluation. In Proceedings of NAACL 2018 (Short Papers). New Orleans, LA.

### Overview

Machine translation (MT) evaluation works by comparing a translated sentence (as output by some automatic MT system) to a "reference" sentence (written by a human translator) in the same language. An evaluation system measures the 'closeness' of the machine-generated translation to the human reference translation. If the evaluation system is good, then a machine-generated translation that is 'close' to its reference should be rated as high-quality. 

The difficult part is measuring 'closeness', because two sentences can convey the same message but have different wording. The HyTER MT Evaluation system ([Dreyer & Marcu, 2012](https://dl.acm.org/citation.cfm?id=2382052)) addresses this difficulty by enumerating paraphrases for parts of the reference sentence, and judging a MT sentence as 'good' if it matches any of the combinations of paraphrases for the reference.

Our system automates the process of enumerating paraphrases for parts of the reference sentence. For every content word in the reference, it looks up the word's paraphrases from the Paraphrase Database ([PPDB](www.paraphrase.org)) and evaluates whether the paraphrase is a good fit in context using the AddCos ([Melamud et al. 2015](www.aclweb.org/anthology/W15-1501)) lexical substitution metric. If so, the paraphrase is added to the lattice.

### Getting started

Before running this code, you'll need to download our re-implementation of the AddCos metric and HyTER MT evaluation system, and a few other resources.

1. Clone the git repository [https://github.com/acocos/lexsub\_addcos](https://github.com/acocos/lexsub\_addcos) from the base directory of this repo.
    ` git clone https://github.com/acocos/lexsub_addcos`
2. Install the re-implementation of HyTER and its dependencies, following the instructions on the site: [https://bitbucket.org/gwisniewski/hytera](https://bitbucket.org/gwisniewski/hytera)
3. Download a copy of PPDB from [www.paraphrase.org](www.paraphrase.org). For the paper we use English PPDB-XXL.
    `wget -P ./data http://nlpgrid.seas.upenn.edu/PPDB/eng/ppdb-2.0-xxl-lexical.gz`
4. Download or train your own part-of-speech-tagged `gensim` word embeddings. If you train your own, tokens should be of the format `word_NN`, using the Penn Treebank tag set. The embeddings we used for the paper are available to download:
    `wget -P ./data http://www.seas.upenn.edu/~acocos/data/word-pos.agiga.4b.gensim3.4.tar.gz`
5. Install required Python packages (see `requirements.txt`):
    - spaCy (you'll also need to install the 'en' models, see [spaCy website](https://spacy.io/models/) for details)
    - gensim
    - scikit-learn

When you're finished, your directory structure should look something like this:

```
data/
    ppdb-2.0-xxl-lexical.gz
    word_pos.agiga.4b.gensim3.4
    ...
hytera/
    ...
    openfst-1.6.3/
    boost_1_65_1/
    ...
format_for_addcos.py
format_for_hyter.py
lexsub_addcos/
    ...
    lexsub_addcos_ppdb.py
    ...
pipeline.sh
README.md (this readme)
testdata/
    newstest2016-deen-ref.en
    newstest2016.online-A.0.de-en
tokenizer_wmt/
    tokenizer.perl
    nonbreaking_prefixes/
        ...
```


### Running the code

To run this code, you'll need files containing reference and translation sentences such as the ones given as examples in `testdata/`.

To generate paraphrase lattices, first check `pipeline.sh` to make sure all the specified paths are correct for your configuration.

Simply run:
`pipeline.sh <REFFILE> <HYPFILE>`

where `<REFFILE>` is the file containing reference sentences (one per line), and `<HYPFILE>` contains predicted translations. For example:

`pipeline.sh testdata/newstest2016-deen-ref.en testdata/newstest2016.online-A.0.de-en`


 

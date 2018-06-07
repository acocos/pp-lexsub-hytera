#!/usr/bin/env python

'''
format_for_addcos.py

Format a file of tokenized reference sentences (one per line) for input to the lexsub_addcos 
script

Takes one argument -- the name of the file containing tokenized sentences

'''
import os, sys
import spacy
import json

def format(fin):
    sents = [l.decode('utf8').strip().lower() for l in fin]
    sent_toks = []
    tgt_words = []
    tgt_offsets = []
    tgt_ids = []
    
    # POS-tag
    poslookup = {'NOUN': 'n',
                 'VERB': 'v',
                 'ADJ': 'a',
                 'ADV': 'r'}
    nlp = spacy.load('en', disable=['parser','ner','textcat'])
    tgtid = 1
    for i, sent in enumerate(sents):
        if i % 500==0:
            sys.stderr.write('.')
        proc = nlp(sent)
        pos = [t.pos_ for t in proc]
        text = [t.text for t in proc]
        sent_toks.append(['_'.join((t.text, t.tag_)) for t in proc])
        toff, shortpos = zip(*[(j,poslookup[p]) for j,p in enumerate(pos) if p in ['NOUN', 'VERB', 'ADV', 'ADJ']])
        tgt_offsets.append(toff)
        tgt_words.append(['.'.join((text[j],sp)) for j,sp in zip(toff, shortpos)])
        these_tgtids = []
        for j in range(len(tgt_offsets[-1])):
            these_tgtids.append(tgtid)
            tgtid += 1
        tgt_ids.append(these_tgtids)
    sys.stderr.write('\n')
    
    data = zip(range(len(sent_toks)), sent_toks, tgt_words, tgt_offsets, tgt_ids)
    return data

def write_for_addcos(data, fout):
    for drow in data:
        sent_id, sent_toks, tgt_words, tgt_offsets, tgt_ids = drow
        for i, tw in enumerate(tgt_words):
            print >> fout, '\t'.join((tw.encode('utf8'), '%d'%tgt_ids[i], '%d'%tgt_offsets[i], ' '.join(sent_toks).encode('utf8')))

def write_all_data(data, fout):
    print >> fout, json.dumps(data, fout)

if __name__=="__main__":
    datafile = sys.argv[1]
    data = format(open(datafile, 'rU'))
    
    with open(datafile+'.addcosinput', 'w') as fout:
        write_for_addcos(data, fout)
    with open(datafile+'.alldata.json', 'w') as fout:
        write_all_data(data, fout)
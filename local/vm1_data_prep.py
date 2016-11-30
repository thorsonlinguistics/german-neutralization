#!/usr/bin/python

# The input is the path to a directory containing Verbmobil data. This
# directory contains numerous subdirectories, each of which contains data
# files for Verbmobil.

import glob
import json
import os
import re
import sys
import random

from collections import defaultdict
from operator import itemgetter

# Symbols used in transcriptions
UNSTRESSED = ['a:', 'a', 'e', 'e:', 'E', 'i:', 'i', 'I', 'o:', 'o', 'O', 'u:',
        'u', 'U', 'y:', 'y', 'Y', '2:', '2', '9', 'a~', 'E~', 'O~', '9~',
        'aI', 'aU', 'OY', '@', '6']
PRIMARY = ['\'' + vowel for vowel in UNSTRESSED]
SECONDARY = ['"' + vowel for vowel in UNSTRESSED]
CONSONANTS = ['z', 'S', 'Z', 'C', 'x', 'N', 'Q', 'b', 'd', 'f', 'g', 'h', 'j',
        'k', 'l', 'm', 'n', 'p', 'r', 's', 't', 'v', 'T', 'w', 'b0',
        'd0', 'z0', 'g0']
SPECIAL = ['<usb>']
SAMPA = UNSTRESSED + PRIMARY + SECONDARY + CONSONANTS + SPECIAL

def assocs(labels):
    """
    Converts a list of labels to a dictionary.
    """

    d = {}

    for label in labels:
        d[label["name"]] = label["value"]

    return d

def ensure_dirs(paths):
    """
    Ensures that the given directories exist. If they don't, they will be
    created if possible. 
    """

    for path in paths:
        try:
            os.makedirs(path)
        except OSError as e:
            if not os.path.isdir(path):
                raise e

def process_json(filenames, training, ambiguous, special):
    """
    Process all of the JSON files in the relevant directories under VM1. This
    function writes several files:

        - /data/test/text: the transcripts of each utterance
        - /data/test/spk2utt: maps speaker ids to utterance ids
        - /data/test/utt2spk: maps utterance ids to speaker ids
        - /data/test/wav.scp: commands to pipe wave files to Kaldi
    """

    # We only want dialogs in German: K, L, M, N, G, W

    sid_to_uid = defaultdict(list)
    uid_to_sid = {}
    uid_to_text = {}
    uid_to_wav = {}
        
    for filename in filenames: 
        with open(filename, 'r') as infile:
            content = json.loads(infile.read())
           
            # Get meta info
            uid_parts = content["name"].split('_')
            uid = '_'.join([uid_parts[2], uid_parts[0], uid_parts[1]])
            wavfile = os.path.abspath(os.path.join(
                os.path.dirname(filename), 
                content["annotates"]
            ))

            # Add to the dict for wav
            uid_to_wav[uid] = wavfile

            # Get speaker ID
            sid = assocs(content["levels"][0]["items"][0]["labels"])["SPN"]

            # Add to the dict for spk2utt
            sid_to_uid[sid].append(uid)

            # Add to the dict for utt2spk
            uid_to_sid[uid] = sid

            # Get tokens
            tokens = []
            for item in content["levels"][1]["items"]:
                labels = assocs(item["labels"])
           
                try:
                    tokens.append(labels["ORT"])
                except KeyError:
                    continue

            # Add to the dict for text
            uid_to_text[uid] = ' '.join(tokens)

    # Now we can write the wav.scp file
    dir_name = "" 
    if training:
        dir_name = "train"
    else:
        dir_name = "test"
    if ambiguous:
        dir_name += "_ambiguous"
    else:
        dir_name += "_unambiguous"
    with open('data/%s/wav.scp' % dir_name, 'w') as outfile:
        for key, value in sorted(uid_to_wav.items(), key=itemgetter(0)):
            outfile.write("%s cat %s |\n" % (key, value))

    # Now we can write the text
    with open('data/%s/text' % dir_name, 'w') as outfile:
        for key, value in sorted(uid_to_text.items(), key=itemgetter(0)):
            if ambiguous:
                value = convert_ambiguous(value, special)
            else:
                value = convert_unambiguous(value, special)
            outfile.write("%s %s\n" % (key, value))

    # We also write the raw text
    with open('data/%s/raw_text' % dir_name, 'w') as outfile:
        for key, value in sorted(uid_to_text.items(), key=itemgetter(0)):
            if ambiguous:
                value = convert_ambiguous(value, special)
            else:
                value = convert_unambiguous(value, special)
            outfile.write("%s\n" % (value))

    # Now we can write utt2spk
    with open('data/%s/utt2spk' % dir_name, 'w') as utt2spk:
        for key, value in sorted(uid_to_sid.items(), key=itemgetter(0)):
            utt2spk.write("%s %s\n" % (key, value))

    # Now we can update spk2utt
    with open('data/%s/spk2utt' % dir_name, 'w') as spk2utt:
        for key, values in sorted(sid_to_uid.items(), key=itemgetter(0)):
            values = sorted(values)
            spk2utt.write("%s %s\n" % (key, ' '.join(values)))

    return sid_to_uid.keys()

def convert_ambiguous(text, special):
    """
    Replaces devoiced words in the text with their ambiguous lexical entries.
    """

    words = []

    for word in re.finditer(r'\S+', text):
        if word.group(0) in special:
            words.append(word.group(0) + '2')
        else:
            words.append(word.group(0))

    return ' '.join(words)

def convert_unambiguous(text, special):
    """
    Replaces devoiced words in the text with their unambiguous lexical entries.
    """

    words = []

    for word in re.finditer(r'\S+', text):
        if word.group(0) in special:
            words.append(word.group(0) + '1')
        else:
            words.append(word.group(0))

    return ' '.join(words)

def process_extra():
    """
    Generates the following files:
        - data/local/dict/silence_phones.txt
    """

    with open('data/local/dict/silence_phones.txt', 'w') as outfile:
        outfile.write("sil\n")

    with open('data/local/dict/optional_silence.txt', 'w') as outfile:
        outfile.write("sil\n")

    with open('data/local/dict/nonsilence_phones.txt', 'w') as outfile:
        for phone in SAMPA:
            outfile.write("%s\n" % phone)

def process_aufdat(sids, training, ambiguous):
    """
    Processes speaker information in the aufdat file. This should produce the
    following files:

        - data/test/spk2gender
    """

    filename = os.path.join(sys.argv[2], 'doc/AufDat.txt')

    speakers = {}
    with open(filename, 'r') as infile:
        for line in infile:
            columns = line.split('\t')
            id1 = columns[14]
            gender1 = columns[15]
            id2 = columns[23]
            gender2 = columns[24]

            if id1 in sids:
                speakers[id1] = gender1
            if id2 in sids:
                speakers[id2] = gender2

    dir_name = ""
    if training:
        dir_name = "train"
    else:
        dir_name = "test"
    if ambiguous:
        dir_name += "_ambiguous"
    else:
        dir_name += "_unambiguous"
    with open('data/%s/spk2gender' % dir_name, 'w') as outfile:
        for speaker, gender in sorted(speakers.items(), key=itemgetter(0)):
            if gender == 'w':
                gender = 'f'
            outfile.write("%s %s\n" % (speaker, gender))

def process_lexicon():
    """
    Processes the lexicon. This should produce the following files:

        - data/local/dict/lexicon.txt
    """

    semivoiced = {'t': 'd0', 's': 'z0', 'k': 'g0', 'p': 'b0'}
    voiced = {'t': 'd', 's': 'z', 'k': 'g', 'p': 'b'}

    filename = os.path.join(sys.argv[2], 'doc/vm_ger.lex')

    # Recognizes a SAMPA character
    sampa = re.compile(r'|'.join(SAMPA))

    # Recognizes a non-SAMPA character
    nonsampa = re.compile(r'(?!%s)' % '|'.join(SAMPA))

    entries = []
    special_entries = []
    with open(filename, 'r') as infile:
        for line in infile:
            columns = line.split('\t')
            word = columns[0]
            entry = columns[1]

            # Remove non-SAMPA characters
            entry = nonsampa.sub('', entry)
            
            # Divide the entry at each SAMPA character
            new_entry = []
            current_entry = entry
            while current_entry:
                try:
                    phone = sampa.match(current_entry).group(0)
                except AttributeError:
                    current_entry = current_entry[1:]
                    if current_entry == '':
                        break
                    else:
                        continue

                new_entry.append(phone)
                current_entry = sampa.sub('', current_entry, 1)

            if is_voiceless(new_entry, word):
                # Original just has a voiceless obstruent at the end
                original_out = new_entry[:]

                voiced_equiv = voiced[original_out[-1]]

                # We also add an entry with the semivoiced
                semivoiced_out = new_entry[:]
                semivoiced_out[-1] = semivoiced[original_out[-1]]

                # And we also have an entry with the fully voiced form
                voiced_out = new_entry[:]
                voiced_out[-1] = voiced_equiv

                entries.append((word + '1', ' '.join(original_out)))
                entries.append((word + '2', ' '.join(semivoiced_out)))
                entries.append((word + '2', ' '.join(original_out)))
                entries.append((word + '2', ' '.join(voiced_out)))

                special_entries.append(word)
            elif is_devoiced(new_entry, word):
                # Original just has a voiceless obstruent at the end
                original_out = new_entry[:]

                # Semivoiced has a devoiced obstruent at the end
                semivoiced_out = new_entry[:]
                semivoiced_out[-1] = semivoiced[new_entry[-1]]

                # Voiced has a voiced obstruent at the end
                voiced_out = new_entry[:]
                voiced_out[-1] = voiced[new_entry[-1]]

                entries.append((word + '1', ' '.join(semivoiced_out)))
                entries.append((word + '2', ' '.join(semivoiced_out)))
                entries.append((word + '2', ' '.join(original_out)))
                entries.append((word + '2', ' '.join(voiced_out)))

                special_entries.append(word)
            else:
                entries.append((word, ' '.join(new_entry)))

    entries.append(('!SIL', 'sil'))

    max_word = max(len(w) for (w, _) in entries)

    with open('data/local/dict/lexicon.txt', 'w') as outfile:
        for key, value in entries:
            outfile.write(("%-" + str(max_word) + "s %s\n") % (key,
                value))

    return special_entries

def is_devoiced(entry, word):
    """
    Returns True if the last phone in entry is a devoiced version of the last
    grapheme in word.
    """

    voiced_orth = {'p': 'b', 't': 'd', 'k': 'g', 's': 's'}

    if entry[-1] in ['p', 't', 'k', 's'] and word[-1] == \
            voiced_orth[entry[-1]] and word[-2:] not in ['"s', 'ss']:
        return True
    else:
        return False

def is_voiceless(entry, word):
    """
    Returns True if the last phone in entry is underlyingly voiceless, at least
    based on the orthography.
    """

    if (word.endswith('ss') or word.endswith('p') or \
            word.endswith('t') or word.endswith('k') or \
            word.endswith('th') or word.endswith('"s') or \
            word.endswith('z')) and entry[-1] in ['p', 't', 'k', 's']:
        return True
    else:
        return False

def main():

    if len(sys.argv) != 3:
        print ("Usage: %s /path/to/VM1 /path/to/doc" % (sys.argv[0]))
        sys.exit(1)

    # Output files go in either data/local/dict or data/test
    ensure_dirs(['data/local/dict', 'data/test_ambiguous',
        'data/test_unambiguous', 'data/train_ambiguous', 
        'data/train_unambiguous'])

    #Create list of test files and list of training files
    filenames = glob.glob(os.path.join(sys.argv[1], '[klmngw]*/*.json'))
    random.shuffle (filenames)
    idx = int (len (filenames) * .7)
    training_files = filenames[:idx]
    test_files = filenames[idx:]

    # Process everything we can out of the lexicon
    special = process_lexicon()

    # Process everything we can out of the JSON
    sids_training1 = process_json(training_files, True, True, special)
    sids_training2 = process_json(training_files, True, False, special)
    sids_test1 = process_json(test_files, False, True, special)
    sids_test2 = process_json(test_files, False, False, special)

    # Process everything we can out of the speaker info
    process_aufdat(sids_training1, True, True)
    process_aufdat(sids_training2, True, False)
    process_aufdat(sids_test1, False, True)
    process_aufdat(sids_test2, False, False)

    # There are a small number of additional files that need to be generated
    process_extra()

if __name__ == "__main__":
    main()

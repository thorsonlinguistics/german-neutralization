addpath('Kaldi-alignments-matlab', 'Kaldi-alignments-matlab/extra');

% Monophone model

alifile = '../exp/mono_ambi_ali/ali.all.gz';
wavscp = '../data/test_ambiguous/wav.scp';
model = '../exp/mono_ambi_ali/final.mdl';
phones = '../data/lang/phones.txt';
transcript = '../data/test_ambiguous/text';
datbase = 'Kaldi-alignments-matlab/matlab-mat/VM1_mono';
audiodir = 'Kaldi-alignments-matlab/matlab-wav/VM1_mono';

if (audiodir == 0)
    convert_ali(alifile,wavscp,model,phones,transcript,datbase);
else
    convert_ali(alifile,wavscp,model,phones,transcript,datbase,audiodir);
end

% Tri1

alifile = '../exp/tri1_ambi_ali/ali.all.gz';
wavscp = '../data/test_ambiguous/wav.scp';
model = '../exp/tri1_ambi_ali/final.mdl';
phones = '../data/lang/phones.txt';
transcript = '../data/test_ambiguous/text';
datbase = 'Kaldi-alignments-matlab/matlab-mat/VM1_tri1';
audiodir = 'Kaldi-alignments-matlab/matlab-wav/VM1_tri1';

if (audiodir == 0)
    convert_ali(alifile,wavscp,model,phones,transcript,datbase);
else
    convert_ali(alifile,wavscp,model,phones,transcript,datbase,audiodir);
end

% Tri2b

alifile = '../exp/tri2b_ambi_ali/ali.all.gz';
wavscp = '../data/test_ambiguous/wav.scp';
model = '../exp/tri2b_ambi_ali/final.mdl';
phones = '../data/lang/phones.txt';
transcript = '../data/test_ambiguous/text';
datbase = 'Kaldi-alignments-matlab/matlab-mat/VM1_tri2b';
audiodir = 'Kaldi-alignments-matlab/matlab-wav/VM1_tri2b';

if (audiodir == 0)
    convert_ali(alifile,wavscp,model,phones,transcript,datbase);
else
    convert_ali(alifile,wavscp,model,phones,transcript,datbase,audiodir);
end

% Analyze 

addpath('Kaldi-alignments-matlab/matlab-mat');

process_alignments('mono');
process_alignments('tri1');
process_alignments('tri2b');

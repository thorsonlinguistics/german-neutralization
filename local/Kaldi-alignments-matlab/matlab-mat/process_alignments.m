function [TOK] = process_alignments(aliset)
% alignments must be a string matching the final destination of the data file.
% E.g. 'VM1'

%% load data
dbstop if error
% Load sets dat to a structure. It has to be initialized first.
dat = 0;
alignments = ['VM1_' aliset];
datbase =  ['G:' filesep 'projects' filesep 'speech' filesep 'data' filesep 'matlab-mat'];
datfile = [datbase filesep alignments '.mat'];
load(datfile);


Scp = dat.scp;
P = dat.phone_indexer;
Uid = dat.uid;
Basic = dat.basic;
Align_pdf = dat.pdf;
Align_phone = dat.align_phone;
Align_phone_len = dat.phone_seq;
Tra = dat.tra;

%% dictate phone sets
voiced_orth = {'b2', 'd2', 'g2', 's2'};
voiceless_orth = {'ss2', 'p2', 't2', 'k2', 'th2', '"s2', 'z2'};
target_orth = [voiced_orth, voiceless_orth];
incomplete = {'b0','d0','z0','g0'};
voiced_cons = {'z','Z','N','Q','b','d','g','j','l','m','n','r','v','w'};
voiceless_cons = {'S','C','x','f','h','k','p','s','t','T'};
vowels_unstressed = {'a:','a','e','e:','E','i:','i','I','o:','o','O','u:','u','U',...
'y:','y','Y','2:','2','9','a~','E~','O~','9~','aI','aU','OY','@','6'};
%{
% vowels_primary = {'a:' % 'a' % 'e' % 'e:' % 'E' % 'i:' % 'i' % 'I' % 'o:'
% 'o' % 'O' % 'u:' % 'u' % 'U' % 'y:' % 'y' % 'Y' % '2:' % '2' % '9' % 'a~'
% 'E~' % 'O~' % '9~' % 'aI' % 'aU' % 'OY' % '@' % ''6') % '"a:' % '"a' %
'"e' % '"e:' % '"E' % '"i:' % '"i' % '"I' % '"o:' % '"o' % '"O' % '"u:' %
'"u' % '"U' % '"y:' % '"y' % '"Y' % '"2:' % '"2' % '"9' % '"a~' % '"E~' %
'"O~' % '"9~' % '"aI' % '"aU' % '"OY' % '"@' % '"6'}
%}


% Index in Uid and Align of the utterance being displayed.
for ui = 1:length(Uid)
	%% skip empty/error utterances
	utt = Tra(Uid{ui});
	if isempty(utt{1})
		continue
	end
	%% initialize variables
	Pb = 0;
	Wb = 0;
	tra = 0;
	uid = 0;
	PX = 0;
	F = 0;
	
	%% retrieve utterance data from datfile
	utterance_data(ui);
	
	wrdends = Wb(2,:);
	phnends = Pb(2,:);
	wrdstarts = Wb(1,:);
	% phonestarts = Pb(1,:);
	wrdnum = find(wrdends);
% 	phnnum = find(phnends);
	
	%% find relevant tokens and orthographic form
	i = 1;
	tokix = logical(zeros(size(tra)));
	for w = 1:length(tra)
		wrd = tra{w};
		if length(char(wrd))>2
			wend3 = wrd(end-2:end);
		else 
			wend3 = wrd;
		end
		if length(char(wrd))>1
			wend2 = wrd(end-1:end);
		else
			wend2 = wrd;
		end
		if ismember(wend3,{'ss2', 'th2', '"s2'})
			orth{i} = wend3;
			i = i+1;
			tokix(w) = true;
		elseif ismember(wend2,target_orth)
			orth{i} = wend2;
			i = i+1;
			tokix(w) = true;
		else
			continue
		end
		
	end
	
% 	tokix = cellfun(@(c) ~isempty(strfind(c,'2')),tra);
	wrdix = wrdnum(tokix);
% 	phnix = phnnum(tokix);
	
	%skip utterance if no tokens are found
	if sum(tokix)==0
		continue
	end
	
	%% Put data into structure array (struct) indexed by token
	tok.utt = ui*ones(sum(tokix),1);
	for t = 1:sum(tokix)
		tok.uid{t,1} = uid;
		tok.trans{t,1} = [tra];
	end
	tok.wrd = tra(tokix)';
	tok.orth = orth';
	tok.phnindex = wrdends(tokix)';
	tok.phnid = PX(tok.phnindex)';
	
	tok.phn = dat.phone_indexer.ShortSpell(tok.phnid(:))';
	nextphnid = zeros(size(tok.wrd));
	prevphnid = zeros(size(tok.wrd));
	uttphnnum = zeros(size(tok.wrd));
	uttwrdnum = zeros(size(tok.wrd));
	ppindex = zeros(size(tok.wrd));
	npindex = zeros(size(tok.wrd));
	windex = zeros(size(tok.wrd));
	for x = 1:length(wrdix)
		pix = find(phnends==tok.phnindex(x));
		uttphnnum(x) = pix;
		wix = find(wrdends==tok.phnindex(x));
		windex(x) = wix;
		
		if pix > 1
			prevphnend = phnends(pix-1);
			ppindex(x) = prevphnend;
			prevphnid(x) = PX(prevphnend);
		else
			prevphnend = NaN;
			ppindex(x) = NaN;
			prevphnid(x) = 1;
		end
		% if word is not last in utterance
		if wix ~= length(wrdends)
			nextphnend = phnends(pix+1);
			npindex(x) = nextphnend;
			nextphnid(x) = PX(nextphnend);
		else
			%set phn ID to that for silence, <eps>
			nextphnend = NaN;
			npindex(x) = NaN;
			nextphnid(x) = 1;
		end
	end
	tok.uttwrdnum = windex;
	tok.uttphnnum = uttphnnum;
	tok.prevpix = ppindex;
	tok.nextpix = npindex;
	tok.prevphnid = prevphnid;
	tok.nextphnid = nextphnid;
	tok.prevphn = dat.phone_indexer.ShortSpell(prevphnid(:))';
	tok.nextphn = dat.phone_indexer.ShortSpell(nextphnid(:))';
	clear nextphnid;
	clear nextwrdons;
	clear orth;
	
	%% convert struct to table and append to conglomerate table
	T = struct2table(tok);
	
	if ui ~= 1 & ~isempty(utt{1})
		TOK = [TOK;T];
	else
		TOK = T;
	end
	
	clear tok;
end


%% Define function "utterance_data(k)
% Set phone and audio data for k'th utterance.
	function utterance_data(k)
		uid = cell2mat(Uid(k));
		[F,Sb,Pb,Wb,tra] = parse_ali(uid,Align_pdf,Align_phone_len,...
			Tra,P,k);
		% Escape underline for display.
		%         uid2 = strrep(uid, '_', '\_');
		PX = Align_phone{k};
		%         PDF = Align_pdf{k};
		% Maximum frame index
		%         [~,Fn] = size(F);
		% Load audio. Cat the pipe Scp(uid) into a temporary file.
		% cmd = [Scp(uid), ' cat > \tmp\display_ali_tmp.wav'];
		% This helps flac work.
		% setenv('PATH', '\opt\local\bin:\opt\local\sbin:\opt\local\bin:\opt\local\sbin:\usr\local\bin:\usr\bin:\bin:\usr\sbin:\sbin:\opt\X11\bin');
		% system(cmd);
		% wav = '\tmp\display_ali_tmp.wav';
		% Read the temporary wav file.
		% [w,fs] = audioread(wav);
		% Number of audio samples in a centisecond frame.
		%         wav = find_audio(uid);
		%         disp(wav);
		%         [w,fs] = audioread(wav);
		%         w2 = w;
		%         [~,ch] = size(w);
		%         if (ch == 2)
		%             w = w(:,2);
		%         end
		%         M = fs / 100;
		%         [nsample,~] = size(w);
		%         [~,nframe] = size(F);
		%         % pitch
		%         [fx,tt]=fxrapt(w,fs);
	end

%% add variables compiled from raw input
TOK.tokenid = zeros(size(TOK.utt));
TOK.orth_voiced = false(size(TOK.utt));
TOK.surf_voicedfull = false(size(TOK.utt));
TOK.incomplete = false(size(TOK.utt));
TOK.devoicing = false(size(TOK.utt));
TOK.voicing = false(size(TOK.utt));
TOK.prev_voiced = false(size(TOK.utt));
TOK.next_voiced = false(size(TOK.utt));

for i = 1:length(TOK.utt)
	TOK.tokenid(i) = i;
	% mark voiced underlying forms as 1 (true)
% 	voiceless orthographic forms: ss, p, t, k, th, "s, and z
	if ismember(TOK.orth{i},voiced_orth)
		TOK.orth_voiced(i) = true;
	end
	
	% mark voiced surface forms (aligments) as 1 (true)
	if ismember(TOK.phn{i}, voiced_cons)
		TOK.surf_voicedfull(i) = true;
	end
	
	% mark intermediate voicing surface forms (d0, b0, etc.) as 1 (true)
	if ismember(TOK.phn{i},incomplete)
		TOK.incomplete(i) = true;
	end
	
	% mark surface forms that have been devoiced, full or incomplete
	if TOK.orth_voiced(i) & ~TOK.surf_voicedfull(i)
		TOK.devoicing(i) = true;
	end
	
	% mark surface forms that have become voiced, full or incomplete
	if ~TOK.orth_voiced(i) & (TOK.surf_voicedfull(i) | TOK.incomplete(i))
		TOK.voicing(i) = true;
	end
	
	% indicate place of articulation of each surface phone (and underlying)
	if ~isempty(strfind(TOK.phn{i},'s')) | ~isempty(strfind(...
			TOK.phn{i},'z')) | ~isempty(strfind(TOK.phn{i},'d'))...
			| ~isempty(strfind(TOK.phn{i},'t'))
		TOK.phn_place{i} = 'alveolar';
	elseif ~isempty(strfind(TOK.phn{i},'b')) | ~isempty(strfind(...
			TOK.phn{i},'p'))
		TOK.phn_place{i} = 'bilabial';
	elseif ~isempty(strfind(TOK.phn{i},'g')) | ~isempty(strfind(...
			TOK.phn{i},'k'))
		TOK.phn_place{i} = 'velar';
	end
	
	% indicate manner of articulation for each surface phone (and
	% underlying)
	if ~isempty(strfind(TOK.phn{i},'s')) | ~isempty(strfind(...
			TOK.phn{i},'z'))
		TOK.phn_manner{i} = 'fricative';
	else
		TOK.phn_manner{i} = 'stop';
	end
	
	%mark preceding and following phones as voiced or voiceless
	if ~ismember(TOK.prevphn{i},voiceless_cons)
		TOK.prev_voiced(i) = true;
	end
	
	if ~ismember(TOK.nextphn{i},voiceless_cons)
		TOK.next_voiced(i) = true;
	end
	
end



%% Edit table variable descriptions

% rearrange table columns
TOK = TOK(:,[17 4 5 8 18:22 25 26 16 24 15 23 3 1 2 6 7 9 10 11 13 12 14]);

%tokenid
TOK.Properties.VariableDescriptions{1} = ...
	'number of relevant token (word final obstruent; double)';
%wrd
TOK.Properties.VariableDescriptions{2} = ...
	'word containing token (cell array of stings)';
%orth
TOK.Properties.VariableDescriptions{3} = ...
	'orthographic form of token (cell array of strings)';
%phn
TOK.Properties.VariableDescriptions{4} = ...
	'phonetic transcription of token in kaldi alignments (cell array of strings)';
%orth_voiced
TOK.Properties.VariableDescriptions{5} = ...
	'logical for voicing of orthographic form, 1 = voiced';
%surf_voicedfull
TOK.Properties.VariableDescriptions{6} = ...
	'logical for full voicing of surface/phonetic/alignment form, 1= fully voiced';
%incomplete
TOK.Properties.VariableDescriptions{7} = ...
	'logical for incomplete devoicing or intermediate level of voicing (e.g. x0 forms), 1=partial voicing';
%devoicing
TOK.Properties.VariableDescriptions{8} = ...
	'logical for devoicing from orth to phn, complete or incomplete, 1=surface form loses voicing';
%voicing
TOK.Properties.VariableDescriptions{9} = ...
	'logical for voicing from orth to phn, complete or incomplete, 1=surface form gains voicing';
%phn_place
TOK.Properties.VariableDescriptions{10} = ...
	'cell array of strings describing place of articulation of token';
%phn_manner
TOK.Properties.VariableDescriptions{11} = ...
	'cell array or strings describing manner of articulation of token';
%nextphn
TOK.Properties.VariableDescriptions{12} = ...
	'cell array of strings listing first phone of the next word';
%next_voiced
TOK.Properties.VariableDescriptions{13} = ...
	'logical for voicing of initial phone of following word, 1=voiced';
%prevphn
TOK.Properties.VariableDescriptions{14} = ...
	'cell array of strings listing phone preceding token phone';
%prev_voiced
TOK.Properties.VariableDescriptions{15} = ...
	'logical for voicing of preceding phone, 1 = voiced';
%trans
TOK.Properties.VariableDescriptions{16} = ...
	'cell array of full orthographic transcription of utterance';
%utt
TOK.Properties.VariableDescriptions{17} = ...
	'utterance number (of those which include a relevant token)';
%uid
TOK.Properties.VariableDescriptions{18} = ...
	'utterance ID in alignments';
%phnindex
TOK.Properties.VariableDescriptions{19} = ...
	'frame index of end of each word, used to retrieve phone id of token';
%phnid
TOK.Properties.VariableDescriptions{20} = ...
	'phone ID of token, used to retreive phonetic transcription of token';
%uttwrdnum
TOK.Properties.VariableDescriptions{21} = ...
	'token is in the nth word in utterance (double)';
%uttphnnum
TOK.Properties.VariableDescriptions{22} = ...
	'token is nth phone in utterance (double)';
%prevpix
TOK.Properties.VariableDescriptions{23} = ...
	'frame index of preceding phone, used to retrieve phone id (double)';
%prevphnid
TOK.Properties.VariableDescriptions{24} = ...
	'phone id of preceding phone, used to retrieve phonetic transcription';
%nextpix
TOK.Properties.VariableDescriptions{25} = ...
	'frame index of initial phone of following word, used to retrieve phone id (double)';
%nextphnid
TOK.Properties.VariableDescriptions{26} = ...
	'phone ID of first phone of word following the token phone, used to retrieve phonetic transcription';


%% Save data table as "tokens.mat"
save([datbase filesep alignments '_results' filesep aliset '_tokens.mat'],'TOK');

end




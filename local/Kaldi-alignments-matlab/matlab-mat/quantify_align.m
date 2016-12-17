function quantify_align(option)
%UNTITLED Summary of this function goes here
%   option = 1 if any required TOK tables do not exist yet
%   option = 2 if *all* TOK tables already exist and should simply be loaded
datbase =  ['G:' filesep 'projects' filesep 'speech' filesep 'data' filesep 'matlab-mat'];

alisets = {'mono','tri1','tri2b'};

if option == 1
	for a = 1:length(alisets)
		aliset = alisets{a};
		process_alignments(aliset);
	end
	
end

for a = 1:length(alisets)
	aliset = alisets{a};
	alignments = ['VM1_' aliset];
	load([datbase filesep alignments '_results' filesep aliset '_tokens.mat']);
	writetable(TOK,[datbase filesep alignments '_results' filesep aliset '_tokens.xls']);
	analyze_tokens(TOK,aliset,datbase);
end
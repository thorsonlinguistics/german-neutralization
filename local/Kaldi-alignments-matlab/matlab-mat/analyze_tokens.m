function analyze_tokens(T,aliset,datbase)
dbstop if error
%T is a table containing relevant variables
alignments = ['VM1_' aliset];
%% split by change type and level
%only tokens showing incomplete devoicing
TID = T(T.incomplete & T.devoicing, :);

%only tokens showing complete devoicing
TCD = T(~T.incomplete & T.devoicing, :);

%only tokens showing incomplete voicing
TIV = T(T.incomplete & T.voicing, :);

%only tokens showing complete voicing
TCV = T(~T.incomplete & T.voicing, :);

%only tokens showing no change in voicing
NC= T(~T.voicing & ~T.devoicing,:);

sortT.names = {'Incomplete Devoicing'; 'Complete Devoicing'; 'Incomplete Voicing'; 'Complete Voicing'; 'No Change in Voicing'};
sortT.counts = [size(TID,1); size(TCD,1); size(TIV,1); size(TCV,1); size(NC,1)];
sortT.percents = (sortT.counts/size(T,1))*100;
SORTT = struct2table(sortT);

save([datbase filesep alignments '_results' filesep aliset '_totalcounts.mat'],'SORTT');


%% split by orthographic voicing first

%only underlyingly voiced tokens
OVD = T(T.orth_voiced,:);
OVDD = OVD(OVD.devoicing,:);
%binomial dist of voiced segments becoming incomplete
r = binornd(size(OVDD,1),0.5);
[phat,pci] = binofit(sum(OVDD.incomplete),size(OVDD,1),0.01); %to 99% confidence interval

rep = 100000;
above = false(1,rep);
for i = 1:rep
	trials = randi([0 1],1,319); %size(OVDD,1));
	if sum(trials) >= 254 %sum(OVDD.incomplete)
		above(i) = true;
	end
end
p_incdev = sum(above)/rep
	
%only underlyingly voiceless tokens
OVL = T(~T.orth_voiced,:);


%% then split Orthographic Voiced by change type
%only tokens showing incomplete devoicing
OVD_ID = OVD(OVD.incomplete & OVD.devoicing, :);

%only tokens showing complete devoicing
OVD_CD = OVD(~OVD.incomplete & OVD.devoicing, :);

%only tokens showing incomplete voicing
OVD_IV = OVD(OVD.incomplete & OVD.voicing, :);

%only tokens showing complete voicing
OVD_CV = OVD(~OVD.incomplete & OVD.voicing, :);

%only tokens showing no change in voicing
OVD_NC= OVD(~OVD.voicing & ~OVD.devoicing,:);

sortOVD.names = {'Incomplete Devoicing'; 'Complete Devoicing'; 'Incomplete Voicing'; 'Complete Voicing'; 'No Change in Voicing'};
sortOVD.counts = [size(OVD_ID,1); size(OVD_CD,1); size(OVD_IV,1); size(OVD_CV,1); size(OVD_NC,1)];
sortOVD.percents = (sortOVD.counts/size(OVD,1))*100;
SORTOVD = struct2table(sortOVD);

save([datbase filesep alignments '_results' filesep aliset '_voicedcounts.mat'],'SORTOVD');

%% then split orthographic voiceless by change type
%only tokens showing incomplete devoicing
OVL_ID = OVL(OVL.incomplete & OVL.devoicing, :);

%only tokens showing complete devoicing
OVL_CD = OVL(~OVL.incomplete & OVL.devoicing, :);

%only tokens showing incomplete voicing
OVL_IV = OVL(OVL.incomplete & OVL.voicing, :);

%only tokens showing complete voicing
OVL_CV = OVL(~OVL.incomplete & OVL.voicing, :);

%only tokens showing no change in voicing
OVL_NC= OVL(~OVL.voicing & ~OVL.devoicing,:);
rep = 100000;
above = false(1,rep);
for i = 1:rep
	trials = randi([0 1],1,size(OVL,1));
	if sum(trials) >= size(OVL_NC);
		above(i) = true;
	end
end
p_statvoiceless = sum(above)/rep

sortOVL.names = {'Incomplete Devoicing'; 'Complete Devoicing'; 'Incomplete Voicing'; 'Complete Voicing'; 'No Change in Voicing'};
sortOVL.counts = [size(OVL_ID,1); size(OVL_CD,1); size(OVL_IV,1); size(OVL_CV,1); size(OVL_NC,1)];
sortOVL.percents = (sortOVL.counts/size(OVL,1))*100;
SORTOVL = struct2table(sortOVL);

save([datbase filesep alignments '_results' filesep aliset '_voicelesscounts.mat'],'SORTOVL');

%% plot counts bar graph

countbar = figure; 
combinedcounts = [SORTT.counts(:), SORTOVD.counts(:), SORTOVL.counts(:)];
bar(combinedcounts,'grouped');hold on;
set(gca, 'XTickLabel',SORTT.names, 'XTick',1:numel(SORTT.names))
title(['Token Counts by Voicing Change: ' aliset]);
ylabel(sprintf('Number of phones'));


%% plot percentages bar graph

percentbar = figure; hold on;
combinedpercents = [SORTOVD.percents(:), SORTOVL.percents(:)];
bar(combinedpercents,'grouped');hold on;
set(gca, 'XTickLabel',SORTT.names, 'XTick',1:numel(SORTT.names))
title(['Token Percentages by Voicing Change Type: ' aliset]);
% ylabel(sprintf('Percent of %i total phones',size(T,1)));
ylim([0 100]);

vdi = SORTOVD.counts(1)+SORTOVD.counts(3);
vdc = SORTOVD.counts(2)+ SORTOVD.counts(4);
vdn = SORTOVD.counts(5);
vli = SORTOVL.counts(1)+SORTOVL.counts(3);
vlc = SORTOVL.counts(2)+ SORTOVL.counts(4);
vln = SORTOVL.counts(5);
ti = SORTT.counts(1)+SORTT.counts(3);
tc = SORTT.counts(2)+ SORTT.counts(4);
tn = SORTT.counts(5);

%% sort by completeness of voicing change
I = table;

I.set = {'all';'voiced';'voiceless'};
I.incomplete = [ti; vdi; vli];
I.complete = [tc; vdc; vlc];
I.static = [tn; vdn; vln];
I.totals = [size(T,1); size(OVD,1); size(OVL,1)];

save([datbase filesep alignments '_results' filesep aliset '_incompletecounts.mat'],'I');
writetable(I,[datbase filesep alignments '_results' filesep aliset '_incompletecounts.xls']);

combinedinc = [I.complete(2:3), I.incomplete(2:3), I.static(2:3)]';
figure;
bar(combinedinc,'stacked');
type = {'complete','incomplete','static'};
set(gca, 'XTickLabel',type, 'XTick',1:numel(type));
title(['Token Counts by Voicing Change Level: ' aliset ' alignments']);
lgd = legend({'voiced','voiceless'},'Location','northwest');
title(lgd,'Underlying Token Set');
ylabel('Number of Phones');
xlabel('Voicing Change Level');
grid on;

cleanfigure; 
matlab2tikz([datbase filesep alignments '_results' filesep aliset '_countplot.tex']); 



end
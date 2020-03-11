% close all
clear all; clc

%% Set the folder
cd '/home/is18902/git/Robopilot_Carla/PythonAPI/examples/ExperimentResutls'

%% or add results directory to path
addpath('~/git/Robopilot_Carla/PythonAPI/examples/ExperimentResutls')

% set graph display as option
display_graphs = 1;
display_graphs_2 = 0;
plot_velocity_graph = 0;

%% setup for multiple reads
nFilep1='Experiment-'; nFilep2='.csv';
nVelocities = 1;
fileNumberOffset = 0; %for file ...-5001.csv use = 4, 6001 = 5

file = 'TEST_Cars_OUTPUT.txt';
data = importfile_data(file);

%% Find the number of exclusive agents & tests
agentIDs = unique(data.agentID,'stable');
agentIDs = table2array(agentIDs);
Agents = unique(data.agentNo,'stable');
nAgents = length(Agents);
nRepeats = max(data.repeatNo);
maxTime = max(data.time);
timeStep = 0.1;

%% Store raw, non-interpolated data (T,X,Y) and variance
rawData = zeros(nRepeats,nAgents,3,round(maxTime/timeStep));
variance = zeros(nRepeats,nAgents,2);
avgVar = zeros(nRepeats,1);

%% For each agent get (T,X,Y) and interpolate, then variance
for i=1:nRepeats
    for j=1:nAgents
        sel1 = data.repeatNo==i; %select data for each repeat
        sel2 = data.agentNo==j; %select data for each agent
        sel = sel1 & sel2;
        tempData = data(sel,:);
        tempT = tempData.time;
        tempX = tempData.x;
        tempY = tempData.y;
        rawData(i,j,:,:) = [tempT, tempX, tempY]';
    end
end

%% Interpolate data if you need to?
% % interpolate data
% regT = min(tempT):0.1:max(tempT);
% regX=interp1(tempT,tempX,regT,'linear','extrap');
% regY=interp1(tempT,tempY,regT,'linear','extrap');

%% Get variance per experiment and agent
for i=1:nRepeats
    agentVar = zeros(nAgents,1);
    for j=1:nAgents
        rawX = squeeze(rawData(:,j,2,:)); % x data
        rawY = squeeze(rawData(:,j,3,:)); % y data
        varX = var(rawX,0,1);
        varY = var(rawY,0,1);
        avgVarX = mean(varX); %take average x-variance over all repeats
        avgVarY = mean(varY);
        maxVarX = max(varX);
        maxVarY = max(varY);

        agentVar(j) = mean([avgVarX,avgVarY]); %take mean of x & y variance
    end
    
    avgVar(i) = mean(agentVar); %take mean overall agents x & y
end

experimentVariance = mean(avgVar)
experimentDeviation = sqrt(experimentVariance)

%% Get variance and deviation from mean (cm)
% varX
% varY = var(tempY);
% Variance = var(VeloctiyInLoop_Data(:,6:8,:), 0, 3); %GC - i think this is incorrect, need to interp against time
% %ArrayOfVariances(:,:,k) = Variance; % |X|Y|Z| Third dimension is the different velocities data
% ArrayOfVariances(:,1,k) = varX; % |X|Y| Third dimension is the different velocities data
% ArrayOfVariances(:,2,k) = varY; % |X|Y| Third dimension is the different velocities data
% currentMeanVarX = mean(varX);
% currentMeanVarY = mean(varY);
% %get the std deviation from the mean
% currentMeanCmX = sqrt(currentMeanVarX);
% currentMeanCmY = sqrt(currentMeanVarY);
% % store the variance
% meanXvar(nS,k,nT) = currentMeanVarX;
% meanYvar(nS,k,nT) = currentMeanVarY;
% aa=1; 
% 
% 
%  Plot the output  
%     if display_graphs==1
%     figure(8); clf;
%     subplot(4,1,1)
%     plot(allT,allX,'-r');ylabel('P(x,t)');
%     xlim([1,minTime])
% %     title(sprintf('%s %s for $v$=%d $\\bar{S_x}$=%5.1f $\\bar{S_y}$=%5.1f',...
% %         tag,stressTag,VelocityInTheLoop,currentMeanCmX,currentMeanCmY),...
% %         'Interpreter','latex','FontSize',12); 
% 
% %cpu only logging
%     title(sprintf('%s %s=%5.1f $v$=%d $\\bar{S_x}$=%5.1f $\\bar{S_y}$=%5.1f',...
%     tag,stressTag,currentCPUutil,VelocityInTheLoop,currentMeanCmX,currentMeanCmY),...
%     'Interpreter','latex','FontSize',12); 
% %gpu only logging
%     title(sprintf('%s sm=%.0f mem=%.0f mclk=%.0f pclk=%.0f $v$=%d $\\bar{S_x}$=%5.1f $\\bar{S_y}$=%5.1f',...
%     stressTag,smGPU,memGPU,mclkGPU,pclkPU,VelocityInTheLoop,currentMeanCmX,currentMeanCmY),...
%     'Interpreter','latex','FontSize',12);
% %gpu & cpu logging    
%     title(sprintf('cpu=%.0f sm=%.0f mem=%.0f mclk=%.0f pclk=%.0f $v$=%d $\\bar{S_x}$=%5.1f $\\bar{S_y}$=%5.1f',...
%     currentCPUutil,smGPU,memGPU,mclkGPU,pclkPU,VelocityInTheLoop,currentMeanCmX,currentMeanCmY),...
%     'Interpreter','latex','FontSize',12);
% 
%     subplot(4,1,2)
%     plot(allT,allY,'-r');ylabel('P(y,t)');
%     xlim([1,minTime])
%     subplot(4,1,3)
%     plot(regT(sel),varX,'-r');ylabel('\sigma_x','FontSize',12); %ylim([0 200])
%     xlim([1,minTime])
%     subplot(4,1,4)
%     plot(regT(sel),varY,'-r');ylabel('\sigma_y','FontSize',12);
%     xlim([1,minTime])
%     
%     formattype = 'png';
%     savefile = sprintf('Pxyt %s for v=%d',filename,VelocityInTheLoop);
%     saveas(gcf,savefile,formattype)
%     end














%% 
nTag = {'CPU0 GPU0','CPU2 GPU0.25','CPU4 GPU0.5','CPU6 GPU0.75','CPU8 GPU1','CPU16 GPU2','CPU32 GPU4'};
nStressTag={''};


% store max/mean variance for X and Y for each v and SS option (5)
maxXvar  = zeros(numel(nStressTag),nVelocities,numel(nTag));
maxYvar  = zeros(numel(nStressTag),nVelocities,numel(nTag));
meanXvar = zeros(numel(nStressTag),nVelocities,numel(nTag));
meanYvar = zeros(numel(nStressTag),nVelocities,numel(nTag));
meanGPU = zeros(numel(nStressTag),nVelocities,numel(nTag));
meanCPU =  zeros(numel(nStressTag),nVelocities,numel(nTag));


for nS=1:numel(nStressTag)
for nT=1:numel(nTag)
for nV=1:numel(nVelocities) 
%create filename & read 
filename = sprintf('%s%d%03d%s',nFilep1,fileNumberOffset+nS,nT,nFilep2);
GPUfilename = sprintf('gpu%d%03d.log',fileNumberOffset+nS,nT);
cpu_file = sprintf('cpu%d%03d.log',fileNumberOffset+nS,nT);

stressTag = nStressTag{nS};
tag=nTag{nT}; 

AllRunsData = csvread(filename); % Get data from csv file to MATLAB
MaxNumberOfRows = size(AllRunsData,1);
NumberOfDifferentVelocities      = max(AllRunsData(:,1)); 
NumberOfRepeatsForEachVelocity   = max(AllRunsData(:,2));
SummaryOfData = zeros(NumberOfDifferentVelocities * NumberOfRepeatsForEachVelocity , 6); % |Experiement number|Repeat Number|Number of recorded points for run|
                                                                                     % |Veolcity value of Box in that run|Start index in AllRunsData|End index in AllRunsData|

counter = 0;
for i = 1:NumberOfDifferentVelocities
    
    indx = AllRunsData(:,1) == i;
    ExtractingExperimentData = AllRunsData(indx,:); % Extracting data for experiment with same Box Velocity
    
    for j = 1:NumberOfRepeatsForEachVelocity        
        indx2 = (AllRunsData(:,2) == j & AllRunsData(:,1) == i);        
        counter = counter + 1; 
        SummaryOfData(counter,1)  = i;
        SummaryOfData(counter,2)  = j;
        SummaryOfData(counter,3)  = size(ExtractingExperimentData(ExtractingExperimentData(:,2) == j,:),1);
        SummaryOfData(counter,4)  = ExtractingExperimentData(1,9);
        SummaryOfData(counter,5)  = find(indx2,1,'first');
        SummaryOfData(counter,6)  = find(indx2,1,'last');

    end
end

MaxNumOfRecordedPoints = max(SummaryOfData(:,3));
ArrayOfVelocities      = unique(SummaryOfData(:,4));
ArrayOfVariances       = zeros(MaxNumOfRecordedPoints,3,NumberOfDifferentVelocities);

%%
for k = 1:NumberOfDifferentVelocities
    
    VelocityInTheLoop = ArrayOfVelocities(k);    
    indx3 = SummaryOfData(:,4) == VelocityInTheLoop;    
    VelocityInLoop_SummaryOfData = SummaryOfData(indx3,:);    
    VeloctiyInLoop_Data = zeros(MaxNumOfRecordedPoints, size(AllRunsData,2),NumberOfRepeatsForEachVelocity);
    
    for l = 1:NumberOfRepeatsForEachVelocity
        
        VolatileDataStorage = AllRunsData(VelocityInLoop_SummaryOfData(l,5):VelocityInLoop_SummaryOfData(l,6),:);
        
        % Make sure repeated runs have the same dimensions
        if size(VolatileDataStorage,1) < MaxNumOfRecordedPoints            
            DiffInSize = MaxNumOfRecordedPoints - size(VolatileDataStorage,1);
            VolatileDataStorage = [VolatileDataStorage; repmat(VolatileDataStorage(end,:),DiffInSize,1)];
        end
        
            VeloctiyInLoop_Data(:,:,l) = VolatileDataStorage;
    end
    
    
    
    %% GC Graphs show inconsistency in time steps (see 5001.csv,v=500)
    gregCode=1;
    if gregCode==1
        allX = squeeze(VeloctiyInLoop_Data(:,6,:));
        allY = squeeze(VeloctiyInLoop_Data(:,7,:));
        allT = squeeze(VeloctiyInLoop_Data(:,3,:));
        if display_graphs==1
            figure(9);clf;plot(allX,allY,'.k','MarkerSize',4);
            xlabel('x pos');ylabel('y pos');
            title(sprintf('%s %s for $v$=%d',tag,stressTag,VelocityInTheLoop),'Interpreter','latex','FontSize',14);
            formattype = 'png';
            savefile = sprintf('xy %s %s for v=%d',tag,stressTag,VelocityInTheLoop);
            saveas(gcf,savefile,formattype)
        end
    minTime = min(allT(end,:));
    end
    
    
    
    %% GC Variance based on indexed data
    regX = (0:1.0:250); regY=(0:1.0:250);
    x=allX(:,1);
    y=allY(:,1);
    t=1:length(x);
    var_indx = var(allX,0,2);
    var_indy = var(allY,0,2);
    
%     % Plot the output using index spacing
%     if display_graphs==1
%     figure(7); clf;
%     subplot(4,1,1)
%     plot(t,allX,'-g');ylabel('P(x,i)');
%     %title('Using array index (n)');
%     %title(sprintf('%s for $v$=%d',filename,VelocityInTheLoop),'Interpreter','latex','FontSize',14);
%     title(sprintf('%s %s for $v$=%d',tag,stressTag,VelocityInTheLoop),'Interpreter','latex','FontSize',14);
%     subplot(4,1,2)
%     plot(t,allY,'-g');ylabel('P(y,i)');
%     subplot(4,1,3)
%     plot(t,var_indx,'-g');ylabel('\sigma_x','FontSize',12);
%     subplot(4,1,4)
%     plot(t,var_indy,'-g');ylabel('\sigma_y','FontSize',12);    
%     formattype = 'png';
%     savefile = sprintf('Pxyi %s for v=%d',filename,VelocityInTheLoop);
%     saveas(gcf,savefile,formattype)
%     end



    %% Varience based on simTime
    % store output
    interpX = []; interpY = []; maxT=0;

    for i=1:NumberOfRepeatsForEachVelocity 
        % get data
        simTime = allT(:,i);
        simX = allX(:,i);
        simY = allY(:,i);

        
        % remove duplicate time points at end
        [uniq_t, ind_t] = unique(simTime);
        uniq_x = simX(ind_t);
        uniq_y = simY(ind_t);

        % interpolate data
        regT=linspace(1,minTime,MaxNumOfRecordedPoints);
        regX=interp1(uniq_t,uniq_x,regT,'linear','extrap');
        regY=interp1(uniq_t,uniq_y,regT,'linear','extrap');

        % plot original & inerpolated data Y
        if display_graphs_2==1
        figure(2); clf; hold on; 
        p2 = plot(simTime,simY,'ob','MarkerSize', 10);
        p4 = plot(regT,regY,':b');
        legend([p2 p4],'y raw','y interp')
        title(sprintf('%s %s run=%d $v$=%d',tag,stressTag,i,VelocityInTheLoop),'Interpreter','latex','FontSize',12); 
        
        % plot original & inerpolated data X 
        figure(3); clf; hold on;
        p1 = plot(simTime,simX,'or','MarkerSize', 10);
        p3 = plot(regT,regX,':r');
        legend([p1 p3],'x raw','x interp','Location','best')
        title(sprintf('%s %s run=%d $v$=%d',tag,stressTag,i,VelocityInTheLoop),'Interpreter','latex','FontSize',12); 
        end
        
        %  store interpolated results in array
        interpX = [interpX; regX];
        interpY = [interpY; regY];

        %  Find the longest time sequence
        currentMaxTime = max(simTime);
              if currentMaxTime > maxT; maxT=currentMaxTime; end
      
    end

    % trim to max time
    maxT_2dp = round(maxT,2);
    sel = regT<maxT_2dp;
    interpX_trim = interpX(:,sel);
    interpY_trim = interpY(:,sel);

    % Plot interpolated data
    varX = var(interpX_trim); varY = var(interpY_trim);
    
    % Get variance and deviation from mean (cm)
    Variance = var(VeloctiyInLoop_Data(:,6:8,:), 0, 3); %GC - i think this is incorrect, need to interp against time
    %ArrayOfVariances(:,:,k) = Variance; % |X|Y|Z| Third dimension is the different velocities data
    ArrayOfVariances(:,1,k) = varX; % |X|Y| Third dimension is the different velocities data
    ArrayOfVariances(:,2,k) = varY; % |X|Y| Third dimension is the different velocities data
    currentMeanVarX = mean(varX);
    currentMeanVarY = mean(varY);
    %get the std deviation from the mean
    currentMeanCmX = sqrt(currentMeanVarX);
    currentMeanCmY = sqrt(currentMeanVarY);
    % store the variance
    meanXvar(nS,k,nT) = currentMeanVarX;
    meanYvar(nS,k,nT) = currentMeanVarY;
    aa=1; 
    
    %% get average GPU util.
    GPUlog= readGPUlog(GPUfilename);
    %select useful info and remove NaN rows
    A=GPUlog(:,{'gpu','pwr','sm','mem','mclk','pclk'});    
    A=A(~any(ismissing(A),2),:);
    selCard = A.gpu==0;
    smGPU   = mean(A.sm(selCard));  %Utilisation of Streaming Multiprocessor clock (%)
    memGPU  = mean(A.mem(selCard)); %Utilisation of memory (%)
    mclkGPU = mean(A.mclk(selCard));%memory speed (MHz)
    pclkPU  = mean(A.pclk(selCard));%GPU processor speed (MHz)
    
    %% find the average CPU utilisation
    % open the CPU log file
    CPUlog = readCPUlogFile(cpu_file);
    % take a moving average of the util
    currentCPUutil = mean(movmean(CPUlog.VarName2,15));
    meanCPU(nS,k,nT) = currentCPUutil;
    
    %%
    
    % Plot the output  
    if display_graphs==1
    figure(8); clf;
    subplot(4,1,1)
    plot(allT,allX,'-r');ylabel('P(x,t)');
    xlim([1,minTime])
%     title(sprintf('%s %s for $v$=%d $\\bar{S_x}$=%5.1f $\\bar{S_y}$=%5.1f',...
%         tag,stressTag,VelocityInTheLoop,currentMeanCmX,currentMeanCmY),...
%         'Interpreter','latex','FontSize',12); 

%cpu only logging
    title(sprintf('%s %s=%5.1f $v$=%d $\\bar{S_x}$=%5.1f $\\bar{S_y}$=%5.1f',...
    tag,stressTag,currentCPUutil,VelocityInTheLoop,currentMeanCmX,currentMeanCmY),...
    'Interpreter','latex','FontSize',12); 
%gpu only logging
    title(sprintf('%s sm=%.0f mem=%.0f mclk=%.0f pclk=%.0f $v$=%d $\\bar{S_x}$=%5.1f $\\bar{S_y}$=%5.1f',...
    stressTag,smGPU,memGPU,mclkGPU,pclkPU,VelocityInTheLoop,currentMeanCmX,currentMeanCmY),...
    'Interpreter','latex','FontSize',12);
%gpu & cpu logging    
    title(sprintf('cpu=%.0f sm=%.0f mem=%.0f mclk=%.0f pclk=%.0f $v$=%d $\\bar{S_x}$=%5.1f $\\bar{S_y}$=%5.1f',...
    currentCPUutil,smGPU,memGPU,mclkGPU,pclkPU,VelocityInTheLoop,currentMeanCmX,currentMeanCmY),...
    'Interpreter','latex','FontSize',12);

    subplot(4,1,2)
    plot(allT,allY,'-r');ylabel('P(y,t)');
    xlim([1,minTime])
    subplot(4,1,3)
    plot(regT(sel),varX,'-r');ylabel('\sigma_x','FontSize',12); %ylim([0 200])
    xlim([1,minTime])
    subplot(4,1,4)
    plot(regT(sel),varY,'-r');ylabel('\sigma_y','FontSize',12);
    xlim([1,minTime])
    
    formattype = 'png';
    savefile = sprintf('Pxyt %s for v=%d',filename,VelocityInTheLoop);
    saveas(gcf,savefile,formattype)
    end

%     %optional box-whisker plot, reduce to 200ms blocks
%     varXmean = BlockMean(interpX_trim, 1, 25); varXmean = varXmean - mean(varXmean);
%     varYmean = BlockMean(interpY_trim, 1, 25); varYmean = varYmean - mean(varYmean);
%     figure(3); clf; boxplot(varXmean);
%     figure(4); clf; boxplot(varYmean);



end %k loop velocities
% MaxArrayOfVariances = max(ArrayOfVariances);


    
end %nV loop velocity

% % Store the max XY var
% varTemp = squeeze(MaxArrayOfVariances);
% maxXvar(nS,:,nT) = varTemp(1,:)';
% maxYvar(nS,:,nT) = varTemp(2,:)';

end %nT loop sub-stepping option

%% Plot X resutls
if plot_velocity_graph==1
figure(1); clf
sp(1) = subplot(2,1,1);
x = ArrayOfVelocities;
p(1) = plot(x,meanXvar(nS,:,1),'-r'); hold on
p(2) = plot(x,meanXvar(nS,:,2),'-k');
p(3) = plot(x,meanXvar(nS,:,3),'--k');
p(4) = plot(x,meanXvar(nS,:,4),':k');
p(5) = plot(x,meanXvar(nS,:,5),'-.k');
% plot(x,y,'+');
title(sprintf('Stress Test: %s',nStressTag{nS}),'Interpreter','latex','FontSize',14); 
ylabel('log(\sigma_x)','FontSize',12); 
set(gca, 'YScale', 'log')
axis normal
set(gca,'XTickLabel',[]) 
xlim([min(ArrayOfVelocities) max(ArrayOfVelocities)])
ylim([10e0 10e3])
% legend(nTag{:},'Location','Best')
lgd = legend(p,nTag{:},'Location','North');
lgd.Orientation='horizontal';


sp(2) = subplot(2,1,2);
x = ArrayOfVelocities;
m(1) = plot(x,meanYvar(nS,:,1),'-r'); hold on
m(2) = plot(x,meanYvar(nS,:,2),'-k');
m(3) = plot(x,meanYvar(nS,:,3),'--k');
m(4) = plot(x,meanYvar(nS,:,4),':k');
m(5) = plot(x,meanYvar(nS,:,5),'-.k');% plot(x,y,'+');
set(gca, 'YScale', 'log')
ylabel('log(\sigma_y)','FontSize',12); 
xlabel('Velocity(UE4 units/s)')
ylim([10e0 10e3])
hLeg=legend();set(hLeg,'visible','off')
xlim([min(ArrayOfVelocities) max(ArrayOfVelocities)])

set(sp(1),'position',[.13 .53 .78 .4 ])
set(sp(2),'position',[.13 .10 .78 .4 ])

formattype = 'png';
savefile = sprintf('Stress Test %s',nStressTag{nS});
saveas(gcf,savefile,formattype)
end

end %for nS

%% Summary table mean and max var over all v
meanXvarOverAllVelocity = squeeze(mean(meanXvar,2));
meanYvarOverAllVelocity = squeeze(mean(meanYvar,2));
XY=cat(3,meanXvarOverAllVelocity,meanYvarOverAllVelocity);
meanVarOverAllVel = mean(XY,3);
% rearrange so 'none' is first
meanVarOverAllVel = [meanVarOverAllVel(4,:);meanVarOverAllVel(1:3,:)];
nStressTagR = {nStressTag{4},nStressTag{1:3}};

% put into real units variance = distance^2 - so sqrt
% rearrange so none category is first
cmUnits = sqrt(meanVarOverAllVel);
figure;
bar(cmUnits,'DisplayName','cmUnits')
xticklabels(nStressTagR)
ylabel('deviation (cm)')
legend(nTag,'Location','northwest')
formattype = 'png';
savefile = sprintf('Deviation Summary');
saveas(gcf,savefile,formattype)
SummaryResultsTable = array2table(meanVarOverAllVel,'VariableNames',nTag,...
    'RowNames',nStressTagR);
cmResultsTable = array2table(cmUnits,'VariableNames',nTag,...
    'RowNames',nStressTagR);

% store as csv
writetable(SummaryResultsTable,'SummaryResultsTable.csv');
writetable(cmResultsTable,'cmResultsTable.csv');







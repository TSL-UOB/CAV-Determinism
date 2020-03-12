% close all
clear all; close all; clc

%% Set the folder
% cd '/home/is18902/git/Robopilot_Carla/PythonAPI/examples/ExperimentResutls'

%% or add results directory to path
% addpath('~/git/Robopilot_Carla/PythonAPI/examples/ExperimentResutls')

% set graph display as option
display_graphs = 0;
display_graphs_2 = 0;
plot_velocity_graph = 0;

%% setup for multiple reads
nFilep1='Experiment-'; nFilep2='.csv';
nVelocities = 1;
fileNumberOffset = 0; %for file ...-5001.csv use = 4, 6001 = 5

% file = "TEST_CarsPeopleCollision_CG25.txt";
% file = "TEST_CarsCollision_CG25.txt";

% file = "TEST_Cars_CG0.txt";
% file = "TEST_Cars_CG25.txt";
% file = "TEST_Cars_CG50.txt";
% file = "TEST_Cars_CG75.txt";
% file = "TEST_Cars_CG95.txt";
% 
% file = "TEST_CarsCollision_CG0.txt";
file = "TEST_CarsCollision_CG25.txt";
% file = "TEST_CarsCollision_CG50.txt";
% file = "TEST_CarsCollision_CG75.txt";
% file = "TEST_CarsCollision_CG95.txt";
% 
% file = "TEST_CarsPeople_CG0.txt";
% file = "TEST_CarsPeople_CG25.txt";
% file = "TEST_CarsPeople_CG50.txt";
% file = "TEST_CarsPeople_CG75.txt";
% file = "TEST_CarsPeople_CG95.txt";
% 
% file = "TEST_CarsPeopleCollision_CG0.txt";
% file = "TEST_CarsPeopleCollision_CG25.txt";
% file = "TEST_CarsPeopleCollision_CG50.txt";
% file = "TEST_CarsPeopleCollision_CG75.txt";
% file = "TEST_CarsPeopleCollision_CG95.txt";
% 
% file = "TEST_People_CG0.txt";
% file = "TEST_People_CG25.txt";
% file = "TEST_People_CG50.txt";
% file = "TEST_People_CG75.txt";
% file = "TEST_People_CG95.txt";
% 
% file = "TEST_PeopleCollsion_L4_CG0.txt";
% file = "TEST_PeopleCollsion_L4_CG25.txt";
% file = "TEST_PeopleCollsion_L4_CG50.txt";
% file = "TEST_PeopleCollsion_L4_CG75.txt";
% file = "TEST_PeopleCollsion_L4_CG95.txt";
% 
% file = "TEST_PeopleCollsion_L20_CG0.txt";
% file = "TEST_PeopleCollsion_L20_CG25.txt";
% file = "TEST_PeopleCollsion_L20_CG50.txt";
% file = "TEST_PeopleCollsion_L20_CG75.txt";
% file = "TEST_PeopleCollsion_L20_CG95.txt";
% 
% file = "TEST_PeopleCollsion_L200_CG0.txt";
% file = "TEST_PeopleCollsion_L200_CG25.txt";
% file = "TEST_PeopleCollsion_L200_CG50.txt";
% file = "TEST_PeopleCollsion_L200_CG75.txt";
% file = "TEST_PeopleCollsion_L200_CG95.txt";

data = importfile_data(file);

%% Find the number of exclusive agents & tests
agentIDs = unique(data.agentID,'stable');
% agentIDs = table2array(agentIDs);
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
            
        if i == 1
            shortest_tempT = length(tempT); 
        end
        
        
        if length(tempT) < shortest_tempT
            shortest_tempT = length(tempT);
        end
         
        
        tempData = data(sel,:);
        tempT = tempData.time;
        tempT = tempT(1:shortest_tempT);
        tempX = tempData.x;
        tempX = tempX(1:shortest_tempT);
        tempY = tempData.y;
        tempY = tempY(1:shortest_tempT);
        
        rawData = rawData(:,:,:,1:shortest_tempT); % chopping data to the shortest
        rawData(i,j,:,:) = [tempT, tempX, tempY]';
%         a=0
    end
end

%% Interpolate data if you need to?
% % interpolate data
% regT = min(tempT):0.1:max(tempT);
% regX=interp1(tempT,tempX,regT,'linear','extrap');
% regY=interp1(tempT,tempY,regT,'linear','extrap');

%% Deviation vs time
% for i=1:nRepeats
agentVar = zeros(4,length(tempT),nAgents);

for j=1:nAgents
    rawX = squeeze(rawData(:,j,2,:)); % x data
    rawY = squeeze(rawData(:,j,3,:)); % y data
    varX = var(rawX,0,1);
    varY = var(rawY,0,1);
    
    mean_variance = (varX + varY)/2;
    max_variance  = max([varX;varY]);
    
    mean_deviation = sqrt(mean_variance);
    max_deviation  = sqrt(max_variance) ;
    
    agentVar(1,:,j) = varX;
    agentVar(2,:,j) = varY;
    agentVar(3,:,j) = mean_deviation;
    agentVar(4,:,j) = max_deviation;
    
%     agentVar(1,:,j) = varX;
%     agentVar(2,:,j) = varY;
%     agentVar(3,:,j) = sqrt((varX + varY)/2);
    
    
    %         avgVarX = mean(varX); %take average x-variance over all repeats
    %         avgVarY = mean(varY);
    %         maxVarX = max(varX);
    %         maxVarY = max(varY);
    
    %         agentVar(j) = mean([avgVarX,avgVarY]); %take mean of x & y variance
    
    

end
Total_mean_deviation = mean(agentVar(3,:,:),"all");
Total_max_deviation  = max(agentVar(4,:,:),[],"all");

fprintf('======================================== \n')
fprintf('Total_mean_deviation (in meters) = %d \n',Total_mean_deviation)
fprintf('Total_max_deviation (in meters)  = %d \n',Total_max_deviation)
fprintf('========================================\n')

B = permute(agentVar,[3 1 2]);

% %% Plot for VarX, VarY and mean for all agents
% FontSize = 12;   
% time_array = squeeze(rawData(1,1,1,:));
% for j=1:nAgents
%     figure(1)
%     plot(time_array,agentVar(1,:,j),'r','DisplayName',"Var X"); hold on;
%     plot(time_array,agentVar(2,:,j),'g','DisplayName',"Var Y"); hold on;
%     plot(time_array,agentVar(3,:,j),'k','DisplayName',"Mean Var"); hold on;
% 
% end
% annotation('doublearrow',[0.13 0.9],[0.855 0.855],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
% text(0.1,5*10^-4,"mm level",'FontSize',FontSize,"Color","r")
% 
% xlabel("Simulation Time (s)")
% ylabel("Mean Deviation Over Runs No. (m)")
% set(gca,'FontSize',12)
% set(gca, 'YScale', 'log')
% legend("Location","SouthEast")



%FontSize = 12;

% %% Plot for paper (PedCarsCollision)
% figure(2)
% Agent1DataIndex = data.agentNo == 1;
% Agent1Data      = data(Agent1DataIndex,:);
% Agent1Type = IdentifyType(Agent1Data.agentTypeNo(1),Agent1Data.agentNo(1));
% plot(time_array,agentVar(3,:,1),'k--','markerfacecolor','w','LineWidth',1,'DisplayName',Agent1Type); hold on;
% 
% Agent2DataIndex = data.agentNo == 2;
% Agent2Data      = data(Agent2DataIndex,:);
% Agent2Type = IdentifyType(Agent2Data.agentTypeNo(1),Agent2Data.agentNo(1));
% plot(time_array,agentVar(3,:,2),'k-','markerfacecolor','w','LineWidth',1,'DisplayName',Agent2Type); hold on;
% 
% Agent3DataIndex = data.agentNo == 3;
% Agent3Data      = data(Agent3DataIndex,:);
% Agent3Type = IdentifyType(Agent3Data.agentTypeNo(1),Agent3Data.agentNo(1));
% plot(time_array,agentVar(3,:,3),'k-.','markerfacecolor','k','LineWidth',1,'DisplayName',Agent3Type); hold on;
% 
% plot(time_array(60),agentVar(3,60,1)/2,'ko','MarkerSize',20,'LineWidth',3,'DisplayName',"Collision Point"); hold on;
% 
% annotation('doublearrow',[0.13 0.9],[0.7 0.7],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
% text(0.1,5*10^-4,"mm level",'FontSize',FontSize,"Color","r")
% 
% annotation('doublearrow',[0.135 0.32],[0.85 0.85])
% annotation('doublearrow',[0.32 0.9],[0.85 0.85])
% annotation('doublearrow',[0.32 0.32],[0.79 0.87],"Head1Style","none","Head2Style","none")
% annotation('textarrow',[0.7 0.47],[0.4 0.23],'String','Delayed Effect','FontSize',FontSize)
% text(1,5,"Pre Collision",'FontSize',FontSize)
% text(13,5,"Post Collision",'FontSize',FontSize)
% 
% ylim([10^-16 100])
% xlabel("Simulation Time (s)")
% ylabel("Mean Deviation Over Runs No. (m)")
% set(gca,'FontSize',FontSize)
% set(gca, 'YScale', 'log')
% legend("Location","SouthEast")
% 
% % PreCollsion = mean(agentVar(3,1:60,[2,3]),"all")
% % PostCollsion = mean(agentVar(3,60:end,[2,3]),"all")

%% Plot for paper (CarsCollision)
figure(2)
Agent1DataIndex = data.agentNo == 1;
Agent1Data      = data(Agent1DataIndex,:);
Agent1Type = IdentifyType(Agent1Data.agentTypeNo(1),Agent1Data.agentNo(1));
plot(time_array,agentVar(3,:,1),'k--','markerfacecolor','w','LineWidth',1,'DisplayName',Agent1Type); hold on;

Agent2DataIndex = data.agentNo == 2;
Agent2Data      = data(Agent2DataIndex,:);
Agent2Type = IdentifyType(Agent2Data.agentTypeNo(1),Agent2Data.agentNo(1));
plot(time_array,agentVar(3,:,2),'k-','markerfacecolor','w','LineWidth',1,'DisplayName',Agent2Type); hold on;

plot(time_array(100),agentVar(3,100,1)/2,'ko','MarkerSize',12,'LineWidth',2,'DisplayName',"Collision Point"); hold on;

annotation('doublearrow',[0.13 0.9],[0.76 0.76],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
text(0.1,5*10^-4,"mm level",'FontSize',FontSize,"Color","r")

annotation('doublearrow',[0.135 0.441],[0.85 0.85])
annotation('doublearrow',[0.441 0.9],[0.85 0.85])
annotation('doublearrow',[0.441 0.441],[0.75 0.87],"Head1Style","none","Head2Style","none")
text(3,0.1,"Pre Collision",'FontSize',FontSize)
text(15,0.1,"Post Collision",'FontSize',FontSize)

% xlim([min(ArrayOfNumberOfAgents) max(ArrayOfNumberOfAgents)])
xlabel("Simulation Time (s)")
ylabel("Mean Deviation Over Runs No. (m)")
set(gca,'FontSize',FontSize)
set(gca, 'YScale', 'log')
legend("Location","SouthEast")


PreCollsion = mean(agentVar(3,1:60,[1,2]),"all")
PostCollsion = mean(agentVar(3,60:end,[1,2]),"all")

%%


    
%     avgVar(i) = mean(agentVar); %take mean overall agents x & y
% end

% %% Get variance per experiment and agent
% for i=1:nRepeats
%     agentVar = zeros(nAgents,1);
%     for j=1:nAgents
%         rawX = squeeze(rawData(:,j,2,:)); % x data
%         rawY = squeeze(rawData(:,j,3,:)); % y data
%         varX = var(rawX,0,1);
%         varY = var(rawY,0,1);
%         avgVarX = mean(varX); %take average x-variance over all repeats
%         avgVarY = mean(varY);
%         maxVarX = max(varX);
%         maxVarY = max(varY);
% 
%         agentVar(j) = mean([avgVarX,avgVarY]); %take mean of x & y variance
%     end
%     
%     avgVar(i) = mean(agentVar); %take mean overall agents x & y
% end
% 
% experimentVariance = mean(avgVar)
% experimentDeviation = sqrt(experimentVariance)

function AgentType = IdentifyType(x,y)
     if x == 1
         AgentType = sprintf("Car - ID %d",y);
     end
     
     if x == 2
         AgentType = sprintf("Ped - ID %d",y);
     end
end





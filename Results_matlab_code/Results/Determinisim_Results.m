close all
clear all 
clc

CarsCollisionPrePostData = readmatrix("CarsCollisionPrePostData.csv");

CarsPeopleCollisionPrePostData = readmatrix("CarsPeopleCollisionPrePostData.csv");

ExperimentsStressSummaryData = readmatrix("ExperimentsStressSummary.csv");

FontSize = 12;

%% Plot for paper (CarsCollisionPrePostData)
figure(1)
StressArray                        = CarsCollisionPrePostData(1,2:end);
AveragePreCarsCollisionDevaition   = CarsCollisionPrePostData(2,2:end);
AveragePostCarsCollisionDevaition  = CarsCollisionPrePostData(3,2:end);

plot(StressArray,AveragePreCarsCollisionDevaition,'ks','markerfacecolor','k','LineWidth',1,'DisplayName',"Pre Collision"); hold on;

plot(StressArray,AveragePostCarsCollisionDevaition,'ko','markerfacecolor','w','LineWidth',1,'DisplayName',"Post Collision"); hold on;

annotation('doublearrow',[0.13 0.9],[0.518 0.518],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
text(1,8*10^-4,"mm level",'FontSize',FontSize,"Color","r")

yticks([10^-6 10^-3 1])
yticklabels({'10^{-6}','10^{-3}','10^{0}'})
xlabel("CPU + GPU Stress (%)")
ylabel("Mean Deviation Over Runs No. (m)")
set(gca,'FontSize',FontSize)
set(gca, 'YScale', 'log')
legend("Location","SouthEast")


%% Plot for paper (CarsPeopleCollisionPrePostData)
figure(2)
StressArray                              = CarsPeopleCollisionPrePostData(1,2:end);
AveragePreCarsPeopleCollisionDevaition   = CarsPeopleCollisionPrePostData(2,2:end);
AveragePostCarsPeopleCollisionDevaition  = CarsPeopleCollisionPrePostData(3,2:end);
AveragePreCarsPeopleCollisionDevaition(1:4) = 6*10^-15; % Values are very small they are being read as zeros

plot(StressArray,AveragePreCarsPeopleCollisionDevaition,'ks','markerfacecolor','k','LineWidth',1,'DisplayName',"Pre Collision"); hold on;

plot(StressArray,AveragePostCarsPeopleCollisionDevaition,'ko','markerfacecolor','w','LineWidth',1,'DisplayName',"Post Collision"); hold on;
annotation('doublearrow',[0.13 0.9],[0.76 0.76],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
text(1,5*10^-4,"mm level",'FontSize',FontSize,"Color","r")
yticks([10^-15 10^-7 1])
yticklabels({'10^{-15}','10^{-7}','10^{0}'})
xlabel("CPU + GPU Stress (%)")
ylabel("Mean Deviation Over Runs No. (m)")
set(gca,'FontSize',FontSize)
set(gca, 'YScale', 'log')
legend("Location","SouthEast")



%% Plot for paper (ExperimentsSummary)
figure(3)
StressArray               = ExperimentsStressSummaryData(1,2:end);
ID1_CarsOnly              = ExperimentsStressSummaryData(2,2:end);
ID2_CarsCollision         = ExperimentsStressSummaryData(3,2:end);
ID3_CarsPeople            = ExperimentsStressSummaryData(4,2:end);
ID4_CarsPeopleCollsion    = ExperimentsStressSummaryData(9,2:end);
ID5_People                = ExperimentsStressSummaryData(5,2:end);
ID6_PeopleCollisionL4     = ExperimentsStressSummaryData(6,2:end);
ID7_PeopleCollisionL20    = ExperimentsStressSummaryData(7,2:end);
ID8_PeopleCollisionL200   = ExperimentsStressSummaryData(8,2:end);

plot(StressArray,ID1_CarsOnly,'k-d','markerfacecolor','w','LineWidth',1,'DisplayName',"Test ID 1"); hold on;
plot(StressArray,ID2_CarsCollision,'k-d','markerfacecolor','k','LineWidth',1,'DisplayName',"Test ID 2"); hold on;
plot(StressArray,ID3_CarsPeople,'k-o','markerfacecolor','w','LineWidth',1,'DisplayName',"Test ID 3"); hold on;
plot(StressArray,ID4_CarsPeopleCollsion,'k-o','markerfacecolor','k','LineWidth',1,'DisplayName',"Test ID 4"); hold on;
plot(StressArray,ID5_People,'k-s','markerfacecolor','w','LineWidth',1,'DisplayName',"Test ID 5"); hold on;
plot(StressArray,ID7_PeopleCollisionL20,'k-s','markerfacecolor','k','LineWidth',1,'DisplayName',"Test ID 6"); hold on;
% plot(StressArray,ID6_PeopleCollisionL4,'k-s','markerfacecolor','k','LineWidth',1,'DisplayName',"Test ID 6"); hold on;
% plot(StressArray,ID7_PeopleCollisionL20,'k-s','MarkerEdgeColor',[0.7 0.7 0.7],'MarkerFaceColor',[0.7 0.7 0.7],'LineWidth',1,'DisplayName',"Test ID 7"); hold on;
% plot(StressArray,ID8_PeopleCollisionL200,'k-s','MarkerEdgeColor','k','MarkerFaceColor',[0.7 0.7 0.7],'LineWidth',1,'DisplayName',"Test ID 8"); hold on;
annotation('doublearrow',[0.14 0.9],[0.75 0.75],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
text(1,5*10^-4,"mm level",'FontSize',FontSize,"Color","r")

xlabel("CPU + GPU Stress (%)")
ylabel("Total Mean Deviation (m)")
set(gca,'FontSize',FontSize)
set(gca, 'YScale', 'log')
legend("Location","East")

%% Plotting X-Y paths
% CarsPeopleCollision_CG0 = readmatrix("TEST_CarsPeopleCollision_CG95.txt");
% 
% Agent1DataIndex = CarsPeopleCollision_CG0(:,2) == 1;
% Agent1Data      = CarsPeopleCollision_CG0(Agent1DataIndex,:);
% Agent1Type = IdentifyType(Agent1Data(1,5),Agent1Data(1,2));
% 
% Agent2DataIndex = CarsPeopleCollision_CG0(:,2) == 2;
% Agent2Data      = CarsPeopleCollision_CG0(Agent2DataIndex,:);
% Agent2Type = IdentifyType(Agent2Data(1,5),Agent2Data(1,2));
% 
% Agent3DataIndex = CarsPeopleCollision_CG0(:,2) == 3;
% Agent3Data      = CarsPeopleCollision_CG0(Agent3DataIndex,:);
% Agent3Type = IdentifyType(Agent3Data(1,5),Agent3Data(1,2));
% 
% for i = 1:10:max(Agent1Data(:,1))
% RunIndexAgent1 = Agent1Data(:,1) == i;
% RunIndexAgent2 = Agent2Data(:,1) == i;
% RunIndexAgent3 = Agent3Data(:,1) == i;
% 
% figure(1)
% plot(Agent1Data(RunIndexAgent1,8),Agent1Data(RunIndexAgent1,9),'k.','DisplayName',Agent1Type)
% hold on
% plot(Agent2Data(RunIndexAgent2,8),Agent2Data(RunIndexAgent2,9),'r.','DisplayName',Agent2Type)
% hold on
% plot(Agent3Data(RunIndexAgent3,8),Agent3Data(RunIndexAgent3,9),'y.','DisplayName',Agent3Type)
% hold on
% end
%legend


%% Functions
function AgentType = IdentifyType(x,y)
    if x == 1
        AgentType = sprintf("Car - ID %d",y);
    end
    
    if x == 2
        AgentType = sprintf("Ped - ID %d",y);
    end
end


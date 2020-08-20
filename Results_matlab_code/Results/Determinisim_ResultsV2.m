close all
clear all 
clc

CarsCollisionPrePostData = readmatrix("CarsCollisionPrePostData_max.csv");

CarsPeopleCollisionPrePostData = readmatrix("CarPeopleCollisionPrePostData_max.csv");

ExperimentsStressSummaryData = readmatrix("ExperimentsStressSummary_max.csv");

FontSize = 12;

%% Plot for paper (CarsCollisionPrePostData)
figure(1)
StressArray                        = CarsCollisionPrePostData(1,2:end);
AveragePreCarsCollisionDevaition   = CarsCollisionPrePostData(2,2:end);
AveragePostCarsCollisionDevaition  = CarsCollisionPrePostData(3,2:end);

plot(StressArray,AveragePreCarsCollisionDevaition,'ks','markerfacecolor','k','LineWidth',1,'DisplayName',"Pre Collision"); hold on;

plot(StressArray,AveragePostCarsCollisionDevaition,'ko','markerfacecolor','w','LineWidth',1,'DisplayName',"Post Collision"); hold on;

annotation('doublearrow',[0.14 0.9],[0.72 0.72],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
text(1,5*10^-4,"mm level",'FontSize',FontSize,"Color","r")

axis([0 100 10^(-15) 10^(1)])
yticks([10^(-14) 10^(-12) 10^(-10) 10^(-8) 10^(-6) 10^(-4) 10^(-2) 10^(0)])

xlabel("CPU & GPU Resource Utilisation (%)")
ylabel("max \sigma (m)")
set(gca,'FontSize',FontSize)
set(gca, 'YScale', 'log')
% legend("Location","SouthEast")
legend("Position",[0.79 0.3 0 0])

%% Plot for paper (CarsPeopleCollisionPrePostData)
figure(2)
StressArray                              = CarsPeopleCollisionPrePostData(1,2:end);
PreCarsPeopleCollisionDevaition   = CarsPeopleCollisionPrePostData(2,2:end);
PostCarsPeopleCollisionDevaition  = CarsPeopleCollisionPrePostData(3,2:end);
PreCarsPeopleCollisionDevaition(1:4) = 6*10^-15; % Values are very small they are being read as zeros

plot(StressArray,PreCarsPeopleCollisionDevaition,'ks','markerfacecolor','k','LineWidth',1,'DisplayName',"Pre Collision"); hold on;

plot(StressArray,PostCarsPeopleCollisionDevaition,'ko','markerfacecolor','w','LineWidth',1,'DisplayName',"Post Collision"); hold on;

annotation('doublearrow',[0.14 0.9],[0.72 0.72],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
text(1,5*10^-4,"mm level",'FontSize',FontSize,"Color","r")

axis([0 100 10^(-15) 10^(1)])
yticks([10^(-14) 10^(-12) 10^(-10) 10^(-8) 10^(-6) 10^(-4) 10^(-2) 10^(0)])

xlabel("CPU & GPU Resource Utilisation (%)")
ylabel("max \sigma (m)")
set(gca,'FontSize',FontSize)
set(gca, 'YScale', 'log')
% legend("Location","SouthEast")
legend("Position",[0.79 0.3 0 0])

%% Plot for paper (ExperimentsSummary)
figure(3); clf;
StressArray               = ExperimentsStressSummaryData(1,2:end);
ID1_CarsOnly              = ExperimentsStressSummaryData(2,2:end);
ID2_CarsCollision         = ExperimentsStressSummaryData(3,2:end);
ID3_CarsPeople            = ExperimentsStressSummaryData(4,2:end);
ID4_CarsPeopleCollsion    = ExperimentsStressSummaryData(5,2:end);
ID5_People                = ExperimentsStressSummaryData(6,2:end);
ID6_PeopleCollisionL4     = ExperimentsStressSummaryData(7,2:end);
ID7_PeopleCollisionL20    = ExperimentsStressSummaryData(8,2:end);
ID8_PeopleCollisionL200   = ExperimentsStressSummaryData(9,2:end);

plot(StressArray,ID1_CarsOnly,'k-d','markerfacecolor','w','LineWidth',1,'DisplayName',"Test ID 1"); hold on;
plot(StressArray,ID2_CarsCollision,'k-d','markerfacecolor','k','LineWidth',1,'DisplayName',"Test ID 2"); hold on;
plot(StressArray,ID3_CarsPeople,'k-o','markerfacecolor','w','LineWidth',1,'DisplayName',"Test ID 3"); hold on;
plot(StressArray,ID4_CarsPeopleCollsion,'k-o','markerfacecolor','k','LineWidth',1,'DisplayName',"Test ID 4"); hold on;
plot(StressArray,ID5_People,'k-s','markerfacecolor','w','LineWidth',1,'DisplayName',"Test ID 5"); hold on;
plot(StressArray,ID7_PeopleCollisionL20,'k-s','markerfacecolor','k','LineWidth',1,'DisplayName',"Test ID 6"); hold on;
% plot(StressArray,ID6_PeopleCollisionL4,'k-s','markerfacecolor','k','LineWidth',1,'DisplayName',"Test ID 6"); hold on;
% plot(StressArray,ID7_PeopleCollisionL20,'k-s','MarkerEdgeColor',[0.7 0.7 0.7],'MarkerFaceColor',[0.7 0.7 0.7],'LineWidth',1,'DisplayName',"Test ID 7"); hold on;
% plot(StressArray,ID8_PeopleCollisionL200,'k-s','MarkerEdgeColor','k','MarkerFaceColor',[0.7 0.7 0.7],'LineWidth',1,'DisplayName',"Test ID 8"); hold on;
annotation('doublearrow',[0.14 0.9],[0.72 0.72],"Head1Style","none","Head2Style","none","Color","r","LineStyle","--","LineWidth",2)
text(1,5*10^-4,"mm level",'FontSize',FontSize,"Color","r")

axis([0 100 10^(-15) 10^(1)])
yticks([10^(-14) 10^(-12) 10^(-10) 10^(-8) 10^(-6) 10^(-4) 10^(-2) 10^(0)])

xlabel("CPU & GPU Resource Utilisation (%)")
ylabel("max \sigma (m)")
set(gca,'FontSize',FontSize)
set(gca, 'YScale', 'log')
% legend("Location","East")


%% Plotting X-Y paths
figure(1); clf
CarsPeopleCollision_CG0 = readmatrix("TEST_CarsPeopleCollision_CG25.txt");

Agent1DataIndex = CarsPeopleCollision_CG0(:,2) == 1;
Agent1Data      = CarsPeopleCollision_CG0(Agent1DataIndex,:);
Agent1Type = IdentifyType(Agent1Data(1,5),Agent1Data(1,2));

Agent2DataIndex = CarsPeopleCollision_CG0(:,2) == 2;
Agent2Data      = CarsPeopleCollision_CG0(Agent2DataIndex,:);
Agent2Type = IdentifyType(Agent2Data(1,5),Agent2Data(1,2));

Agent3DataIndex = CarsPeopleCollision_CG0(:,2) == 3;
Agent3Data      = CarsPeopleCollision_CG0(Agent3DataIndex,:);
Agent3Type = IdentifyType(Agent3Data(1,5),Agent3Data(1,2));

% for i = 1:10:max(Agent1Data(:,1))
for i = 1:max(Agent1Data(:,1))
RunIndexAgent1 = Agent1Data(:,1) == i;
RunIndexAgent2 = Agent2Data(:,1) == i;
RunIndexAgent3 = Agent3Data(:,1) == i;

figure(1)
plot(Agent1Data(RunIndexAgent1,8),Agent1Data(RunIndexAgent1,9),'-k.','DisplayName',Agent1Type)
hold on
plot(Agent2Data(RunIndexAgent2,8),Agent2Data(RunIndexAgent2,9),'-r.','DisplayName',Agent2Type)
hold on
plot(Agent3Data(RunIndexAgent3,8),Agent3Data(RunIndexAgent3,9),'-b.','DisplayName',Agent3Type)
hold on
end
% legend


%% GC Edit - Show the bifurcation number at time (t)
figure(1);clf;scatter(Agent1Data(:,8),Agent2Data(:,9)) %XY plot
t=0.1; %(s) start of sim
figure(2);clf;histogram(Agent1Data(Agent1Data(:,6)==t,9));
t=10; %(s) end of sim
figure(3);clf;histogram(Agent1Data(Agent1Data(:,6)==t,9),'NumBins',100);
% this shows that for Car 1 there are 3/100 events outside of the normal path
%% Agent 2
figure;scatter(Agent2Data(:,8),Agent2Data(:,9)) %XY plot
t=0.1; %(s) start of sim
figure;histogram(Agent2Data(Agent2Data(:,6)==t,9));
t=9.2; %(s) end of sim
figure;histogram(Agent2Data(Agent2Data(:,6)==t,9));
% this shows that 
%%
t=0.1; %(s) start of sim
figure;histogram(Agent3Data(Agent3Data(:,6)==t,9));
t=23.1; %(s) end of sim
figure;histogram(Agent3Data(Agent3Data(:,6)==t,9));
% this shows that 

%% Functions
function AgentType = IdentifyType(x,y)
    if x == 1
        AgentType = sprintf("Car - ID %d",y);
    end
    
    if x == 2
        AgentType = sprintf("Ped - ID %d",y);
    end
end


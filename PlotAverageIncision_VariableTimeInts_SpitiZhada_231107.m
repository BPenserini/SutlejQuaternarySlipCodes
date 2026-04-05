 %Script to plot average incision rate over various averaging intervals
%(deltaT)
close all

% Define important parameters
deltaT = [1.0e6 1.5e6 2.0e6 2.5e6 3.0e6]'; %Vector of time interval lengths (time before present) in years
numNodes = 100; %Number of model nodes along the Sutlej (not Spiti-Sutlej, used for setting dimension of avg_incision rate matrix)
tInt = 20000; %Interval between model frames in years

% Zhada Cap parameters
Tcap = 0.4e6; %Capture age (important to define when incision should be calculated by uplift, assuming steady state prior to capture)
finalZhadaFrame = 122; %Number associated with final frame (present day in model)
captureZhadaFrame = 101; %Number associated with frame at capture
ZhadaModelPrefix = 'PSZ_STDS_3Ma_231107_39'; %Model file prefix for model run

% Spiti Cap parameters
timeBetweenCaps = 3e6; %Interval between Spiti and Zhada captures
finalSpitiFrame = 752; %Number associated with final frame (present day in model)
SpitiI = 73; %Index of node of Spiti confluence in Sutlej reference frame
captureSpitiFrame = 501; %Number associated with frame at capture
SpitiModelPrefix = 'SpitiCap_ActiveSTDS_230307-39'; % Model file prefix for Spiti capture run

% Spiti Capture information

% Time before Zhada capture that needs to be accounted for (Pull from
% post cap Spiti frames)
tPreZhada = (deltaT - Tcap) .* ((deltaT-Tcap) > 0); %Evaluate as 0 when deltaT is less than Tcap, otherwise should be the amount of time to take from post Spiti capture frames

% Time before Spiti capture that needs to be accounted for (calculate
% assuming steady state uplift rate along Sutlej profile)
tPreSpiti = (tPreZhada - timeBetweenCaps) .* ((tPreZhada - timeBetweenCaps) > 0);  %Evaluate as 0 when tPostCap is less 
%than the time interval between captures, otherwise should be the amount of time to apply steady state uplift rate



% Define a structure that contains important variables from final profile
% of model run of interest
modelSutlejCurrentProfile = load(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Previous Versions\No Sed Transport\PSZ_STDS_NoSedModels_231107\PSZ_STDS_3Ma_231107\' ZhadaModelPrefix '\' ZhadaModelPrefix '_final_profile.mat'],...
    'uplift','tote','x');
modelSpitiSutlejPreZhadaProfile = load(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Previous Versions\No Sed Transport\SpitiCap_ActiveSTDS_NoSedModels_230307\' SpitiModelPrefix '\' SpitiModelPrefix 'final_spiti_profile.mat'],...
    'uplift');

% Initialize matrices to store average incision rate information and
% slope of incision rate curve
avgIncisionRate = zeros(length(deltaT), numNodes); %initialize avg_incision matrix with number of rows equal to number of averaged intervals and columns equal to number of model nodes
gradOfAvgIncisionRate = zeros(length(deltaT), numNodes);

% Loop to calculate average incision rate and slope of average incision rate
% curve

for i = 1:length(deltaT)
    
    %If statement that should run if the averaging interval is less than
    %the age of capture
    
    if deltaT(i) < Tcap %No need to consider Spiti Profile
        
        % Define structure that contains variables from profile at begining of
        % averaging interval

        startingModelFrame = captureZhadaFrame + ((finalZhadaFrame - captureZhadaFrame - 1) * (Tcap - deltaT(i)) / Tcap);
        modelInitialProfile = load(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Previous Versions\No Sed Transport\PSZ_STDS_NoSedModels_231107\PSZ_STDS_3Ma_231107\' ZhadaModelPrefix '\' ZhadaModelPrefix '_postcap_' num2str(startingModelFrame) '.mat'], 'tote');
        
        % Calculate the magnitude of incision (NOTE: this is not surface
        % lowering)
        incision = -(modelSutlejCurrentProfile.tote - modelInitialProfile.tote); %tote is negative and increases in magnitude toward the modern
       
    
    else  %Need to add the components of ZhadaCap incision, preZhada steadystate incision upstream of Spiticap, and SpitiCap incision plus any preSpiti steadystate incision 
        
        %ZhadaCap incision
        incisionPostZhada = -modelSutlejCurrentProfile.tote; %Should be numNodes long
        
        %Calculation of preZhada steady state incision upstream of SpitiCap 
        incisionSutlejSteadyState = modelSutlejCurrentProfile.uplift * tPreZhada(i); %Array containing steady state incision component along Sutlej profile
        incisionPreZhadaUpstream = incisionSutlejSteadyState(1:SpitiI); %Pre-Zhada component of incision upstream of Spiti. Should be SpitiI nodes long
        
        %Calculation of SpitiCap incision downstream of SpitiI
        %Determine the starting and ending model frame number for Spiti
        %capture model and save corresponding profiles
        endingModelFrame = captureSpitiFrame + timeBetweenCaps/tInt;
        startingModelFrame = endingModelFrame - ((endingModelFrame - captureSpitiFrame) * ((tPreZhada(i) - tPreSpiti(i)) ./ timeBetweenCaps));
        
        if timeBetweenCaps > 0
            
            if startingModelFrame == captureSpitiFrame
                
                modelFinalProfile = load(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Previous Versions\No Sed Transport\SpitiCap_ActiveSTDS_NoSedModels_230307\' SpitiModelPrefix '\' SpitiModelPrefix '_postcap_' num2str(endingModelFrame)]);
                incisionSpitiSutlej = -(modelFinalProfile.tote);
                incisionSpitiSutlejDownstream = incisionSpitiSutlej((end - (numNodes - SpitiI) + 1):end); % Pre-Zhada component of incision downstream of Spiti. Should be numNodes - SpitiI nodes long
                
            else
                
                modelInitialProfile = load(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Previous Versions\No Sed Transport\SpitiCap_ActiveSTDS_NoSedModels_230307\' SpitiModelPrefix '\' SpitiModelPrefix '_postcap_' num2str(startingModelFrame)]);
                modelFinalProfile = load(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Previous Versions\No Sed Transport\SpitiCap_ActiveSTDS_NoSedModels_230307\' SpitiModelPrefix '\' SpitiModelPrefix '_postcap_' num2str(endingModelFrame)]);
                incisionSpitiSutlej = -(modelFinalProfile.tote - modelInitialProfile.tote);
                incisionSpitiSutlejDownstream = incisionSpitiSutlej((end - (numNodes - SpitiI) + 1):end); % Pre-Zhada component of incision downstream of Spiti. Should be numNodes - SpitiI nodes long
            end
            
        else
            
            incisionSpitiSutlejDownstream = zeros(1, numNodes - SpitiI);
            
        end
        
        %Calculation of preSpiti steady state incision downstream of
        %Spiticap
        
        incisionSpitiSutlejSteadyState = modelSpitiSutlejPreZhadaProfile.uplift * tPreSpiti(i); %Array containing steady state incision component along Spiti profile
        incisionSpitiSutlejSteadyStateDownstream = incisionSpitiSutlejSteadyState((end - (numNodes - SpitiI) + 1):end);
        
        
        %Sum Components to get total incision over duration of deltaT
        incision = incisionPostZhada + [incisionPreZhadaUpstream (incisionSpitiSutlejDownstream + incisionSpitiSutlejSteadyStateDownstream)];
        
        
        
    end    

     avgIncisionRate(i,:) = (incision*1000) / deltaT(i); %Convert to mm/yr
     gradOfAvgIncisionRate(i,:) = [diff(incision / deltaT(i))./diff(modelSutlejCurrentProfile.x) 0]; %Keep incision in meters to allow units to cancel
    
    
end

% Load Exhumation Data
ExhumationData = load('F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Data for Exhumation Comparison\AHe_Exhumation_Results_221004.mat');
%SplineFit = load('F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Data for Exhumation Comparison\ExhumationRateSplineFitVars_092922.mat');

% Define datatable to plot as exhumation rate
datatable_new = ExhumationData.AHe_Exhumation_Results_OutliersRemoved_231107;
datatable_AHE01 = ExhumationData.AHE01_Exhumation_Results_231108;

%Initialize plots

figure(1);

%Set font size for tick labels
fontsize = 14;

px = gca;
px.FontSize = fontsize;

%Set figure background white, add grid, set y extent, x and y label size,
%and add a legend.

set(gcf,'color','w')
grid on
xlabel('Downstream Distance (km)','FontSize',fontsize);
ylabel('Average Incision Rate (mm/yr)','FontSize',fontsize);
xlim([385 450])
ylim([0 4])
legend('Location','northwest')
%colorbar(CM)
%Plot location of STDS
hold on
plot(ExhumationData.x_stds/1000,ExhumationData.y,'-.',...
        'LineWidth',1.5,'Color',[.7 .7 .7],...
        'DisplayName', 'Sangla Detachment')
hold off

figure(2);

%Set font size for tick labels
fontsize = 14;

px = gca;
px.FontSize = fontsize;

%Set figure background white, add grid, set y extent, x and y label size,
%and add a legend.

set(gcf,'color','w')
grid on
xlabel('Downstream Distance (km)','FontSize',fontsize);
ylabel('Gradient of Avg. Incision Rate','FontSize',fontsize);
xlim([380 450])
ylim([-2e-7 8e-7])
legend('Location','northwest')
%colorbar(CM)
%Plot location of STDS
% hold on
% plot(ExhumationData.x_stds/1000,ExhumationData.y,'-.',...
%         'LineWidth',1.5,'Color',[.7 .7 .7],...
%         'DisplayName', 'STDS')
% hold off

CM = flipud(jet(length(deltaT))); %Want to plot count # different avg incision rate profiles

%For loop to plot results
for i = 1:size(avgIncisionRate,1) 
    figure(1);
    hold on
    %Plot model results
    plot(modelSutlejCurrentProfile.x/1000,avgIncisionRate(i,:),'-','LineWidth',3,...
        'Color',CM(i,:),...
        'DisplayName', ['Erosion Avg. Over ' num2str(deltaT(i)/1e6) ' Myr'])
    hold off
    
    figure(2);
    hold on
    plot(modelSutlejCurrentProfile.x/1000,gradOfAvgIncisionRate(i,:),'-',...
        'LineWidth',3,'Color',CM(i,:),...
        'DisplayName', ['Erosion Avg. Over ' num2str(deltaT(i)/1e6) ' Myr'])
    hold off
end



% Overlay exhumation error bar plot and spline fit with envelope on Figure
% 1
figure(1)
hold on
    
% Plot sample exhumation rates
errorbar(datatable_new.L_m/1000, ...
    datatable_new.MeanEdot_3, ...
    datatable_new.MeanEdot_3 - datatable_new.HighEdot_3,...
    datatable_new.LowEdot_35 - datatable_new.MeanEdot_3,...
    'k.','MarkerSize',44,'LineWidth',2,...
    'DisplayName','AHe Exhumation Rate (35 C/km)');

% Plot sample exhumation rates (old samples, only to gray out AHE01)
errorbar(datatable_AHE01.L_m/1000, ...
    datatable_AHE01.MeanEdot_3, ...
    datatable_AHE01.MeanEdot_3 - datatable_AHE01.HighEdot_3,...
    datatable_AHE01.LowEdot_35 - datatable_AHE01.MeanEdot_3,...
    'LineStyle','none',...
    'Marker','.',...
    'Color',[0.7 0.7 0.7],...
    'MarkerSize',44,'LineWidth',2,...
    'DisplayName','AHE01');

% Plot spline fit through samples
% plot(SplineFit.xfit_35Ckm/1000,SplineFit.yfit_35Ckm*1000,'-',...
%         'LineWidth',1.5,'Color','k',...
%         'DisplayName', 'Spline Fit')

% Plot uplift field
plot(modelSutlejCurrentProfile.x/1000,modelSutlejCurrentProfile.uplift*1000,'-.',...
        'LineWidth',2,'Color','k',...
        'DisplayName', 'Uplift Field')
    
hold off

savefig(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\figures\' ZhadaModelPrefix '_AvgIncision_231107']);

%Overlay slope of spline fit with envelope on Figure 2

figure(2)
hold on
% Plot slope of spline fit through samples
% plot(SplineFit.xfit_35Ckm(1:end-1)/1000,SplineFit.slopefit_35Ckm,'-',...
%         'LineWidth',1.5,'Color','k',...
%         'DisplayName', 'Gradient of Spline Fit')
hold off

savefig(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\figures\' ZhadaModelPrefix '_GradientAvgIncision_231107']);

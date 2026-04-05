%Script to plot average incision rate over various averaging intervals
%(deltaT)
close all

% Define important parameters
deltaT = [1.0e6 1.5e6 2.0e6 2.5e6 3.0e6]'; %Vector of time interval lengths (time before present) in years
Tcap = 1.0e6; %Capture age (important to define when incision should be calculated by uplift, assuming steady state prior to capture)
tInt = 20000; %Interval between model frames in years
numNodes = 100; %Number of model nodes (used for setting dimension of avg_incision rate matrix)
finalFrame = 152; %Number associated with final frame (present day in model)
captureFrame = 101; %Number associated with frame at capture
modelPrefix = 'PSZCap_3Ma_231107_36'; %Model file prefix for model run

% Define a structure that contains important variables from final profile
% of model run of interest
modelCurrentProfile = load(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Current Working Models\NoSedTrans\Tcap_1000ka\PSZCap_3Ma_231107_36\' modelPrefix '_final_profile.mat'],...
    'uplift','tote','x');



% Initialize matrices to store average incision rate information and
% slope of incision rate curve
avgIncisionRate = zeros(length(deltaT), numNodes); %initialize avg_incision matrix with number of rows equal to number of averaged intervals and columns equal to number of model nodes
gradOfAvgIncisionRate = zeros(length(deltaT), numNodes);

% Loop to calculate average incision rate and slope of average incision rate
% curve

for i = 1:length(deltaT)
    
    %If statement that should run if the averaging interval is less than
    %the age of capture
    
    if deltaT(i) < Tcap
        
        % Define structure that contains variables from profile at begining of
        % averaging interval

        startingModelFrame = ((finalFrame - captureFrame - 1) * (Tcap - deltaT(i)) / Tcap) + captureFrame;
        modelInitialProfile = load(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Current Working Models\NoSedTrans\Tcap_1000ka\PSZCap_3Ma_231107_36\' modelPrefix  '_postcap_' num2str(startingModelFrame) '.mat'], 'tote');
        
        % Calculate the magnitude of incision (NOTE: this is not surface
        % lowering)
        incision = modelInitialProfile.tote - modelCurrentProfile.tote; %tote is negative and increases in magnitude toward the modern
        avgIncisionRate(i,:) = (incision*1000) / deltaT(i); %Convert to mm/yr
        gradOfAvgIncisionRate(i,:) = [diff(incision / deltaT(i))./diff(modelCurrentProfile.x) 0]; %Keep incision in meters to allow units to cancel
    
    else
        
        % Code should account for steady state incision prior to capture
        incision = -modelCurrentProfile.tote + modelCurrentProfile.uplift*(deltaT(i) - Tcap); %total incision is tote since capture, plus a term accounting for steady state incision prior to capture
        avgIncisionRate(i,:) = (incision*1000) / deltaT(i); %Convert to mm/yr
        gradOfAvgIncisionRate(i,:) = [diff(incision / deltaT(i))./diff(modelCurrentProfile.x) 0]; %Keep incision in meters to allow units to cancel
        
    end    

    
end

% Load Exhumation Data
ExhumationData = load('F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Data for Exhumation Comparison\AHe_Exhumation_Results_240119.mat');
% SplineFit = load('F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Data for Exhumation Comparison\ExhumationRateSplineFitVars_092922.mat');

% Define datatable to plot as exhumation rate
datatable_new = ExhumationData.AHe_Exhumation_Results_OutliersRemoved_240119;
%datatable_AHE01 = ExhumationData.AHE01_Exhumation_Results_231108;

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
xlim([380 450])
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


CM = flipud(jet(length(deltaT))); %Want to plot count # different avg incision rate profiles


%For loop to plot results
for i = 1:size(avgIncisionRate,1) 
    figure(1);
    hold on
    %Plot Model Results
    plot(modelCurrentProfile.x/1000,avgIncisionRate(i,:),'-','LineWidth',3,...
        'Color',CM(i,:),...
        'DisplayName', ['Erosion Avg. Over ' num2str(deltaT(i)/1e6) ' Myr'])
    hold off
    
    figure(2);
    hold on
    plot(modelCurrentProfile.x/1000,gradOfAvgIncisionRate(i,:),'-',...
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
% errorbar(datatable_AHE01.L_m/1000, ...
%     datatable_AHE01.MeanEdot_3, ...
%     datatable_AHE01.MeanEdot_3 - datatable_AHE01.HighEdot_3,...
%     datatable_AHE01.LowEdot_35 - datatable_AHE01.MeanEdot_3,...
%     'LineStyle','none',...
%     'Marker','.',...
%     'Color',[0.7 0.7 0.7],...
%     'MarkerSize',44,'LineWidth',2,...
%     'DisplayName','AHE01');

% Plot spline fit through samples
% plot(SplineFit.xfit_35Ckm/1000,SplineFit.yfit_35Ckm*1000,'-',...
%         'LineWidth',1.5,'Color','k',...
%         'DisplayName', 'Spline Fit')

% Plot uplift field
plot(modelCurrentProfile.x/1000,modelCurrentProfile.uplift*1000,'-.',...
        'LineWidth',2,'Color','k',...
        'DisplayName', 'Uplift Field')
    
hold off

savefig(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\figures\' modelPrefix '_1000k_AvgIncision_240120']);



%Overlay slope of spline fit without envelope on Figure 2

figure(2)
hold on
% Plot slope of spline fit through samples
% plot(SplineFit.xfit_35Ckm(1:end-1)/1000,SplineFit.slopefit_35Ckm,'-',...
%         'LineWidth',1.5,'Color','k',...
%         'DisplayName', 'Gradient of Spline Fit')
hold off

savefig(['F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\figures\' modelPrefix '_1000k_GradientAvgIncision_240120']);


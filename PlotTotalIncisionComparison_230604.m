% For plotting final profiles for different model scenarios along studied
% reach.

% Define variable containing the name of the folder containing all .mat
% files with final profile information 
foldername = 'F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\BestFittingModelsNOSed\Tcap_1000ka\'; % full name of directory with final_profile.mat files


%Define a structure of all model result final profiles, with order being
%drawing order
Scenario = {'baseline_231107-45_final_profile.mat' 
    'activeSTDS_231107-45_final_profile.mat' 
    'PSZCap_0Ma_231107_39_final_profile.mat' 
    'PSZCap_3Ma_231107_36_final_profile.mat' 
    'PSZ_STDS_0Ma_231107_39_final_profile.mat' 
    'PSZ_STDS_2Ma_231107_36_final_profile.mat'};

load([foldername Scenario{1}])

% Load data to draw a dashed line and label with STDS location
load('F:\PhD\Research Files\Himalaya\Him_Matlab\VariableFiles\ErosionExhumation\StructureLocationsForPlotting.mat','x_stds') %Load .mat file with downstream locations of structures

%Want to define range of analyzed reach (in downstream distance values in
%m)
upstream_extent = 380000;
downstream_extent = 450000;
reach_indices = find(L_subsamp >= upstream_extent & L_subsamp <= downstream_extent);


% Create figure frame and set axis font and font sizes
figure('color','w')
hold on
grid on
xlim([upstream_extent/1000 downstream_extent/1000])
ylim([0 3000])
Font = 'Verdana';
AxisFontSize = 18; 

% Plot actual profile and STDS
%plot(x./1000, z_actual,'-','Color',[0 0 0], 'LineWidth', 2)
plot(x_stds/1000,linspace(0,max(zcap(reach_indices))*1.1,length(x_stds)),'k--','Color',[0.5 0.5 0.5],'LineWidth',2.5)
ax = gca;
ax.FontSize = AxisFontSize;
ax.FontName = Font;
xlabel('Downstream Distance (km)');
ylabel('Total Incision Since Capture (m)');



% Iterate over all scenarios and plot final model profiles

%Scenario 1: Autogenic (Baseline)
load([foldername Scenario{1}])
plot(x./1000, -tote,'-','Color',[0 0.4470 0.7410], 'LineWidth', 3) 

%Scenario 2: Active Fault (ActiveSTDS)
load([foldername Scenario{2}])
plot(x./1000, -tote,'-','Color',[0.6350 0.0780 0.1840], 'LineWidth', 3)
    
%Scenario 3A: Two-Stage Capture, Autogenic, 0 Ma between Captures
load([foldername Scenario{3}])
plot(x./1000, -tote,'-.','Color',[0.4660 0.6740 0.1880], 'LineWidth', 3)

% %Scenario 3B: Two-Stage Capture, Autogenic, 1 Ma between Captures
% load([foldername Scenario{4}])
% plot(x./1000, -tote,'--','Color',[0.4660 0.6740 0.1880], 'LineWidth', 2)

%Scenario 3C: Two-Stage Capture, Autogenic, 2 Ma between Captures
load([foldername Scenario{4}])
plot(x./1000, -tote,'-','Color',[0.4660 0.6740 0.1880], 'LineWidth', 3)

%Scenario 4A: Two-Stage Capture, Active Fault, 0 Ma between Captures
load([foldername Scenario{5}])
plot(x./1000, -tote,'-.','Color',[0.8500 0.3250 0.0980], 'LineWidth', 3)

% %Scenario 4B: Two-Stage Capture, Active Fault, 1 Ma between Captures
% load([foldername Scenario{7}])
% plot(x./1000, -tote,'--','Color',[0.8500 0.3250 0.0980], 'LineWidth', 2)

%Scenario 4C: Two-Stage Capture, Active Fault, 2 Ma between Captures
load([foldername Scenario{6}])
plot(x./1000, -tote,'-','Color',[0.8500 0.3250 0.0980], 'LineWidth', 3)

legend('Sangla', 'Scenario 1', 'Scenario 2', 'Scenario 3 (0Ma)',...%'Scenario 3 (1Ma)', 
    'Scenario 3 (3Ma)', 'Scenario 4 (0Ma)',...%'Scenario 4 (1Ma)',
    'Scenario 4 (2Ma)',...
    'Location','northeast',...
    'FontSize', 18,...
    'FontName', Font);











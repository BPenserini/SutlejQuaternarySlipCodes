%For plotting evolution of model for variables z, -dz_b, tote, and sed_depth (not for comparing model results)

foldername = 'F:\PhD\Matlab_Codes\Capture_code_YanitesModel\Capture_code\Sutlej_working\Current Working Models\NoSedTrans\Tcap_1000ka\PSZ_STDS_2Ma_231107_36\'; % full name of directory with model .mat files
prefix = 'PSZ_STDS_2Ma_231107_36_postcap_'; % This is the file name prefix for postcap .mat files that will be accessed to get values in each loop
filename = 'PSZ_STDS_2Ma_231107_36_final_profile.mat'; % file name for final profile .mat file saved for each run
ModelName = 'Scenario 4: Two Capture, Active Fault (2Ma)';

timestep = 20000; % Duration in model years between each .mat output (will be difference in i between consecutive postcap .mat files, multiplied by dt of the model)
initial = 102; % # corresponding to first postcap frame
final = 152; % # corresponding to final postcap frame

load([foldername filename])
close all

%Add data to draw a dashed line and label with STDS location
load('F:\PhD\Research Files\Himalaya\Him_Matlab\VariableFiles\ErosionExhumation\StructureLocationsForPlotting.mat','x_stds') %Load .mat file with downstream locations of structures
%y_stds = linspace(0,max(z)*1.1,length(x_stds));

%Want to define range of analyzed reach (in downstream distance values in
%m)
upstream_extent = 380000;
downstream_extent = 450000;
reach_indices = find(L_subsamp >= upstream_extent & L_subsamp <= downstream_extent);

%Initialize plot

figure('color','w')
hold on
grid on
xlim([upstream_extent/1000 downstream_extent/1000])
ylim([0 3])
Font = 'Verdana';
AxisFontSize = 14; 
ax = gca;
ax.FontSize = AxisFontSize;
ax.FontName = Font;
title(ModelName);
xlabel('Downstream Distance (km)');
ylabel('Incision Rate (mm/yr)'); % This is the average erosion rate over the most recent timestep

duration = final - initial;
count = 1;
plot_frequency = 2; % Sets how often a line is plotted. 1 implies every line is plotted, 2 implies every other line is plotted (see loop for how it executes the if statement depending on this value)
CM = flipud(jet(duration));
legend_entries = cell(round(duration/plot_frequency)-1, 1);

plot(x_stds/1000,linspace(0,max(zcap(reach_indices))*1.1,length(x_stds)),'--', 'Color', [0.5 0.5 0.5],'LineWidth',1.75)

for k = 1:duration
    
    %WANT to add legend with color ramp labeled time since capture and
    %initial and final profiles
    
    if mod(k,plot_frequency)==0
        load([foldername prefix num2str(k+initial-1) '.mat'])
        
        legend_entries{count} = strcat(num2str(timestep*k/1000), 'kyr');

        plot(x./1000,-dz_b./dt.*1000,'-','LineWidth',1.5,'Color',CM(k,:))
        xlim([upstream_extent/1000 downstream_extent/1000]) % Extent of reach with exhumation rates in km
       
        count = count + 1; %Increase index for legend_entries
        
    end
    
end


%Add final values as black line on all plots
plot(x./1000,-dz_b./dt.*1000,'-k','LineWidth',2)
plot(x./1000,uplift.*1000,'-.k','LineWidth',2)
% axis manual
legend('Sangla', legend_entries{:}, '1000kyr','Uplift Rate', 'Location','eastoutside')

%legend('Initial Profile', legend_entries{:}, 'Final Profile', 'STDS','Location','bestoutside')



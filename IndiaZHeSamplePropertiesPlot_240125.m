close all

load('IndiaZHeSampleProperties_240125.mat')

fontsize = 20;

% subplot(2,2,1)
% p1 = gscatter(T_no_5_7_9.CorrectedDate_It__Ma_,T_no_5_7_9.Elevation_m_,...
%     T_no_5_7_9.FullSampleName,[],'s',12);
% 
% ylabel('Elevation (m)','FontSize',fontsize)
% xlabel('AHe Closure Age (Ma)','FontSize',fontsize)
% legend('off')
% set(gca,'FontSize',fontsize)
% grid on

subplot(1,2,1)
hold on
p2 = gscatter(ZHe.eU,ZHe.CorrectedDate_It__Ma_,...
    ZHe.FullSampleName,[],'s',12);
    
%T.STDS,[],'s',12);
    

% plot(x_eU_linfit, AHeMeanAge,...
%     'Color', [0.5 0.5 0.5],...
%     'LineStyle','-',...
%     'LineWidth',2.5);

ylabel('ZHe Date (Ma)','FontSize',fontsize)
xlabel('eU (ppm)','FontSize',fontsize)
ylim([0 10])
legend('FontSize',fontsize,'NumColumns',2)
set(gca,'FontSize',fontsize)
grid on
hold off

% subplot(2,2,3)
% p3 = gscatter(T.CorrectedDate_It__Ma_,T.Th_U,T.STDS,[],'s',12);
% ylabel('Th/U','FontSize',fontsize)
% xlabel('Corrected Age (Ma)','FontSize',fontsize)
% legend('off')
% set(gca,'FontSize',fontsize)
% grid on

subplot(1,2,2)
hold on
p4 = gscatter(ZHe.rs_mm_,ZHe.CorrectedDate_It__Ma_,...
    ZHe.FullSampleName,[],'s',12);
    
%T.STDS,[],'s',12);

% plot(x_rs_linfit, AHeMeanAge,...
%     'Color', [0.5 0.5 0.5],...
%     'LineStyle','-',...
%     'LineWidth',2.5);

xlabel('Spherical Radius (\mum)','FontSize',fontsize)
ylabel('ZHe Date (Ma)','FontSize',fontsize)
legend('off')
ylim([0 10])
set(gca,'FontSize',fontsize)
grid on
hold off

for i = 1:2
    %p1(i).LineWidth = 1.5;
    p2(i).LineWidth = 1.5;
    %p3(i).LineWidth = 1.5;
    p4(i).LineWidth = 1.5;
end

set(gcf,'color','w')
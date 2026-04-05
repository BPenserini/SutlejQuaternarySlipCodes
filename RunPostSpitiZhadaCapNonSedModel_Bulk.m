
%Need to read in files from Spiti Cap runs and then simulate Zhada capture
%for 0-5 Ma, with 1Ma increments


kf = linspace(-3.0e-6, -4.5e-6, 16); %Set vector for kf, needs to be negative
kf_Zhada = -1.5e-5;




for i = -kf(1)*10000000:-kf(end)*10000000
    
    [x_actual, z_actual, z_modeled,x] = sutlej_Zhada_postSpiti_capture_NOsed_trans(['PSZCap_0Ma_231107_' num2str(i)], -i/1e7, kf_Zhada, ['.\Previous Versions\No Sed Transport\SpitiCap_NoSedModels_230307\SpitiCap_230307-' num2str(i) '\SpitiCap_230307-' num2str(i) '_n_501.mat']);
    [x_actual, z_actual, z_modeled,x] = sutlej_Zhada_postSpiti_capture_NOsed_trans(['PSZCap_1Ma_231107_' num2str(i)], -i/1e7, kf_Zhada, ['.\Previous Versions\No Sed Transport\SpitiCap_NoSedModels_230307\SpitiCap_230307-' num2str(i) '\SpitiCap_230307-' num2str(i) '_postcap_551.mat']);
    [x_actual, z_actual, z_modeled,x] = sutlej_Zhada_postSpiti_capture_NOsed_trans(['PSZCap_2Ma_231107_' num2str(i)], -i/1e7, kf_Zhada, ['.\Previous Versions\No Sed Transport\SpitiCap_NoSedModels_230307\SpitiCap_230307-' num2str(i) '\SpitiCap_230307-' num2str(i) '_postcap_601.mat']);
    [x_actual, z_actual, z_modeled,x] = sutlej_Zhada_postSpiti_capture_NOsed_trans(['PSZCap_3Ma_231107_' num2str(i)], -i/1e7, kf_Zhada, ['.\Previous Versions\No Sed Transport\SpitiCap_NoSedModels_230307\SpitiCap_230307-' num2str(i) '\SpitiCap_230307-' num2str(i) '_postcap_651.mat']);
    [x_actual, z_actual, z_modeled,x] = sutlej_Zhada_postSpiti_capture_NOsed_trans(['PSZCap_4Ma_231107_' num2str(i)], -i/1e7, kf_Zhada, ['.\Previous Versions\No Sed Transport\SpitiCap_NoSedModels_230307\SpitiCap_230307-' num2str(i) '\SpitiCap_230307-' num2str(i) '_postcap_701.mat']);
    [x_actual, z_actual, z_modeled,x] = sutlej_Zhada_postSpiti_capture_NOsed_trans(['PSZCap_5Ma_231107_' num2str(i)], -i/1e7, kf_Zhada, ['.\Previous Versions\No Sed Transport\SpitiCap_NoSedModels_230307\SpitiCap_230307-' num2str(i) '\SpitiCap_230307-' num2str(i) '_postcap_751.mat']);
    
end
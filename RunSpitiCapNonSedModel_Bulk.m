% Create vectors for: filenames, kf, 

kf = linspace(-3.5e-6,-5e-6,16);



for i = 1:length(kf)
    
    [z_actual,z_modeled,x] = sutlej_spiti_capture_NOsed_trans(...
        ['SpitiCap_230307' num2str(kf(i)*10000000)],kf(i)); %,kf_Zhada);
    
end
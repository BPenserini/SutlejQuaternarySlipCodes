% Create vectors for: filenames, kf, 

kf = linspace(-3e-6,-5e-6,21);



for i = 1:length(kf)
    
    [z_actual,z_modeled,x] = sutlej_spiti_activeSTDS_capture_NOsed_trans(...
        ['SpitiCap_ActiveSTDS_230307' num2str(kf(i)*10000000)],kf(i)); %,kf_Zhada);
    
end
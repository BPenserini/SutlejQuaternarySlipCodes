% Create vectors for: filenames, kf, 

kf = linspace(-5.0e-6,-4.0e-6,11);
kf_Zhada = -1.5e-5;


for i = 1:length(kf)
    
    [z_actual,z_modeled,x] = sutlej_baseline_capture_NOsed_trans(...
        ['baseline_231107' num2str(kf(i)*10000000)],kf(i),-1.5e-5);
    
end
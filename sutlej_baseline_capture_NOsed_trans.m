function [z_actual, z_modeled,x] = sutlej_baseline_capture_NOsed_trans(model_name, kf_input, kf_Zhada_input)
%% Input Variables
tic
close all

load('SubsampSutlejInputs_100node.mat');
%Above file should contain all the information from the extracted river
%profile in the modern system: X, Y, Z, L, and A.

%% begin image
% this sets a figure to watch model output

scrsz =[1           1        2560        1578];
figure('Position',[1 scrsz(4)/8 8*scrsz(3)/16 21.5*scrsz(4)/40],'PaperPositionMode','auto');

%% Modify inputs and define model parameters
%Subsamp is currently set so input vectors are 250 cells in length. Area is
%already in m^2.

x=L_subsamp; % Input, will need to change if input names change
X=X_subsamp; % This is for plotting purposes
Y=Y_subsamp; % This is for plotting purposes
D_MFT = D_MFT_subsamp; % For defining spatially variable uplift
z_actual = Z_subsamp; % For output and comparison with the modelled profile. Needs to be defined before imposing elevation constraint in pre-capture loop.

Acrit=10^6;
Ah=A_subsamp;  % Areas in m^2

%hack's law values calculated by power law regression of Sutlej, L vs. A (both in m)
% Hc=3.556e4; 
% He=1.053;
% Ah=Hc.*(x.^(He));


% initialize variables

g=9.8;
rhow=1000;
rhos=2650;
n=0.04; %Manning's n
kf = kf_input; %Bedrock erodibility

% %sediment parameters (if using)
% R=(rhos./rhow)-1;
% D0=0.05; %Headwater D50 (in m). Treat D50 as 5cm for now, see Scherler et al. 2017.
% lambda=0.2; %sediment porosity. Carling, 1989
% tau_crit=0.0495; %Critical Shield's stress from Wong and Parker 2006

%% Along-stream divisions and capture location setup

%Below are locations in downstream length (m) of intersections with major tectonic
%features (i.e. for defining tectonostratigraphic changes). Fault traces
%from Webb et al. 2011 with below unit descriptions from Vannay et al.
%2004.
%   Headwaters -> STDS - Tethyan Himalaya
%   STDS -> MCT1 - Higher Himalayan Crystalline
%   MCT1 -> Munsiari - Lesser Himalayan Crystalline
%   Munsiari -> - MCT2 - Lesser Himalayan
%   MCT2 -> MCT3 - Higher Himalayan Crystalline
%   MCT3 -> Outlet - Lesser Himalayan

% Major Faults
L_LP1 = 353500; % Upstream extent of Leo Pargil gneiss dome (location coincides with knickpoint in Sutlej profile
L_LP2 = 383297.9632; % Downstream extent of Leo Pargil gneiss dome
L_STDS = 429498.9432; % Intersection with STDS
L_MCT1 = 459088.5233; % Most upstream intersection with MCT, near Karcham (downstream from Reckong Peo)
L_Munsiari = 519520.3117; 
L_MCT2 = 546145.8922;
L_MCT3 = 576031.4124; % Most downstream intersection with MCT, near Tundal

% Physiographic transitions
L_PT1 = 426111.5834; % Eyeballed trace of PT1
L_PT2 = 533089.9133; % Eyeballed trace of PT2

% Capture locations
L_Zhada_cap = 368740; % Capture point location from Zhada capture paper. BP added, use index to find X, Y, A, Z.

%L_Spiti_cap = 378730.2043;

%Spiti = find(x<L_Spiti_cap);
%OrogenSpiti = find(x>=L_Spiti_cap);

Zhada_capI = find(x<=(L_Zhada_cap),1,'last'); %Uses 'last' optional argument in 'find'
X_Zhada_cap = X_subsamp(Zhada_capI);
Y_Zhada_cap = Y_subsamp(Zhada_capI);
A_Zhada_cap = A_subsamp(Zhada_capI);

% Spiti_capI = min(find(x>(L_Spiti_cap)));
% X_Spiti_cap = X_subsamp(Spiti_capI);
% Y_Spiti_cap = Y_subsamp(Spiti_capI);
% A_Spiti_cap = A_subsamp(Spiti_capI);


% Define kf transition location
% L_kf = L_kf_input; % Estimated location of transition from Himalaya to Tethyan/Trans-Himalaya based on kf contrast.
% L_Tethyan = L_LP1; %Define the transition to Tethyan/Tibetan Plateau at the upstream intersection with the LP dome.

% Define regions based on kf zonation.
% Tethyan = find(x<=L_kf);
% Himalayan = find(x>L_kf);
% Tethyan = find(x<=L_LP1); %Note, as defined same as Zhada.
Himalayan = find(x>L_LP2);

% Define regions into tectonostratigraphic units based on locations of major faults.
Zhada = (x<=L_Zhada_cap); %Used in kf segmentation too
LeoPargil = (x>L_LP1 & x<=L_LP2); %Used in kf segmentation too
Him_Teth = (x>L_LP2 & x<=L_STDS);
HighHim_Xtal = (x>L_STDS & x<=L_MCT1);
LessHim_Xtal = (x>L_MCT1 & x<=L_Munsiari);
LessHim_1 = (x>L_Munsiari & x<=L_MCT2);
HighHim_Klippe = (x>L_MCT2 & x<=L_MCT3);
LessHim_2 = (x>L_MCT3);

% Define additional regions for uplift field, used later in code.

OrogenCoreUp = (x>L_LP1 & x<=L_MCT1); %Portion of orogen that appears to have linear uplift gradient upstream of STDS. Redefined on 10/04/22 to go from LP1 to MCT1 to match CRN rates better. removed OrogenCoreUniform to accommodate this
% OrogenCoreUp = (x>L_LP1 & x<=L_STDS); %Portion of orogen that appears to have linear uplift gradient upstream of STDS. Redefined on 05/04/21 to go from STDS to LP1, not LP2
% OrogenCoreUniform = (x>L_STDS & x<=L_MCT1); %Portion of orogen interpreted to have consistent uplift between MCT and STDS.
OrogenCoreDown = (x>L_MCT1 & x<=L_Munsiari); %Portion of orogen that appears to have a linear uplift gradient downstream from MCT1. Downstream end of zone coincides with Munsiari Thrust (from CRN and thermochron)
OrogenUniform = (x>L_Munsiari); %Portion of orogen that appears to have a uniform uplift rate, downstream from LKR Window and Munsiari Thrust (from CRN)


%% Model time setup
% This is the timing of the capture event after the start of the model run
% (model build-up). This isn't necessarily the real world time.
t_warmup=10e6; % Units: years
age_cap_input = 1.0e6; % Duration of post-capture model (i.e. age of capture event). Units: years


%% Subdivision of pre-capture profiles based on area

%ok, this is where the code finds the 'break point' of the river profile
%and splits it into two pre-capture rivers. Adds discharge corresponding to
%minimum drainage area to avoid unreasonably high divides due to 0
%discharge at downstream segment channel head.

Ah(Zhada_capI+1:end) = Ah(Zhada_capI+1:end)-Ah(Zhada_capI)+Ah(1);

%% Water disharge scaling

%%% Power law scaling, parameters from Bookhagen and Burbank (2010)

% Summer Rainfall
kQ=1.4.*10^(-8);
eQ=1.06;
Qw=kQ.*(Ah.^eQ); %Units: m^3/s

%% Channel width scaling/assignment

%%% Power law scaling relationship from Craddock et al. (2007), Marsyandi
%%% River of Nepal
kw=6.2;
ew=0.4;
W=kw.*(Qw.^ew); %Units: m

%% Uplift set-up
%Rates of different sections. Hardwired values are from CRN data (AFT for
%Leo Pargil and paleoaltimetry for Zhada). Units: m/yr
ZhadaRate = 0; %Should be zero until capture, as the incision model will not equilibrate if consistently subsiding without sediment transport.
LeoPargilRate = 0.6e-3; %Thiede et al. 2006, faster exhumation rates from 4-2Ma based on AFT
OrogenMin = 0.3e-3; %Sets the baseline uplift at 0.3 mm/yr. This matches the uniform uplift estimates downstream of the LKR Window and projected approx. min uplift upstream of MCT.
OrogenMax = 2.0e-3; %Sets the max uplift downstream of MCT at 2 mm/yr

%Arrays of distances from MFT to calculate uplift at each point within the
%different sections.
OrogenUpD_MFT = D_MFT(OrogenCoreUp);
OrogenDownD_MFT = D_MFT(OrogenCoreDown);

%Uplift rate calculations
OrogenCoreUpRate = OrogenMax - ((OrogenMax - ZhadaRate).*(min(OrogenUpD_MFT)-OrogenUpD_MFT)./(min(OrogenUpD_MFT)-max(OrogenUpD_MFT))); 
OrogenCoreDownRate = OrogenMax - ((OrogenMax - OrogenMin).*(max(OrogenDownD_MFT)-OrogenDownD_MFT)./(max(OrogenDownD_MFT)-min(OrogenDownD_MFT)));

uplift=zeros(1,length(x));
uplift(Zhada) = ZhadaRate;
%uplift(LeoPargil) = LeoPargilRate; %Commented out on 05/04/21 to account
%for eliminating Leo Pargil uplift from profile
uplift(OrogenCoreUp) = OrogenCoreUpRate;
%uplift(OrogenCoreUniform) = OrogenMax;
uplift(OrogenCoreDown) = OrogenCoreDownRate;
uplift(OrogenUniform) = OrogenMin;

% %% Sediment transport parameter set up
% beta = 0.33; % Wulf et al. 2010 use a 2:1 suspended load to bedload ratio, implying a beta of 0.33 for the Sutlej. (Unitless) Change usage in loops to be indexed 'beta(j)' if not constant value.
% eroded_sedsupply=uplift; % eroded_sedsupply is the same as 'uplift' for steady state incision. Used in calculating local bedload input (equivalent to local erosion rate in Eq. 3)
% Qs_loc=beta.*[eroded_sedsupply(1).*(Ah(1)) eroded_sedsupply(2:end).*diff(Ah)]; %local component of sediment supply. Q_s = Q_fromupstream + Q_local (Units: m^3/year)
% 
% %Initialize sediment variables
% Qs_down=0; % Variable containing the sediment supply leaving a cell and transported to the downstream cell. Iterated in precap and post cap loops (Units: m^3/year)
% dz_s=zeros(1,length(x)); % Change in sediment thickness (Units: m)
% qs=zeros(1,length(x)); % Array of specific total input sediment supply to each cell (upstream contribution plus local contribution) (Units: m^2/year)

%% Grainsize Calculation

% % Uniform D50 (equal to D0)
% D = D0; % Treats median grainsize as constant over profile (see Attal and Lave, 2006 and Scherler et al. 2017 for info regarding treatment)

%% Incision set-up
%erodibility values for tectonostratigraphic units

kf = ones(1,length(x)).*kf_input; % Bedrock erodibility. Units: m/yr/Pa
kf(Zhada) = kf_Zhada_input; % Erodibility of Zhada Fm. Units: m/yr/Pa
dz_b=zeros(1,length(x));


%% Initial topography set up
z=Z_simple; % 'z' defines bedrock elevation (Units: m)
% sed_depth=zeros(1,length(x))+(.00001.*(max(x)-x)); % Sets initial sediment thickness. (Units: m)
topo=z;%+sed_depth; % 'topo' defines the channel surface elevation. (Units: m)

% Initialize constant elevation Zhada Basin. Initial Z_Zhada selected to
% ensure unincised Zhada does not lower below maximum stream elevation from
% DEM.

Z_Zhada_top = 4590; 
Z_Zhada_base = Z_Zhada_top - 800;


%% Time set up
time = t_warmup + age_cap_input; % Total model run time, unless equilibration block requires additional warmup. (Units: years)
dt = 100; %0.5; %for sediment transport (Units: years)
precapt = 1:dt:t_warmup;
postcapt = t_warmup:dt:time;
warmup = 1; %Variable that is 1 until the precapture profiles are in equilibrium. See conditional in precapture loop to test if profiles are equilibrated.

% Additional variable initialization and allocation
dz_b_t=zeros(10000/dt,length(dz_b)); %Used for calculating average incision over past 10ka when calculating eroded_sedsupply
tote=zeros(1,length(x)); %Used for plotting
zcap=zeros(1,length(x)); %Used for plotting
topocap = zcap;
% sedcap=zcap;
% depth_threshold=0; %Depth threshold of 0, as described in the paper. Determines when bedrock incision occurs.

k=0; %Used for plotting
tlast=0; %Used for plotting
zlast=zeros(1,length(x)); %Used for plotting
% sdlast=zeros(1,length(x)); %Used for plotting
topolast = zeros(1,length(x)); %Used for calculating %change in surface elevation.

% Hillshade variables for figures
%scale H1-3
% H=H.*3;%.*0.001;
% H2=(H).*1000;
% H3=(H).*4000;

%% Pre-capture loop

for i=1:length(precapt)

    %% Topography Setup

    % Pin capture elevation topography and sed_depth

    z(Zhada_capI) = z(Zhada_capI + 1);
%     sed_depth(Zhada_capI)=sed_depth(Zhada_capI - 1);

    % Retain Zhada topography
    if Z_Zhada_top < z(Zhada_capI) % Conditional to redefine the initial Zhada elevation if the downstream profile is greater than the initially assigned Z_Zhada_top value.
        Z_Zhada_top = z(Zhada_capI);
    end

    z(Zhada) = Z_Zhada_top;

    % Impose rock uplift

    z=z+(uplift.*dt);

    % Pin z and sed_depth at outlet 

    z(end) = 904; %pinning bottom of profile to local baselevel
%     sed_depth(end) = 0; %pin sed depth at end to zero

    % Update topo (surface elevation) based on imposed uplift 

    topo = z; %+ sed_depth;
%     topo(Zhada_capI) = topo(Zhada_capI+1); % Commented out since z and
%     sed_depth pinned and this creates weird situation where z>topo.

    % Calculate channel slope
    slope = [diff(topo)./diff(x) 0]; 

    %% Boundary Shear Stress Calculation

    % calc shear stress
    tau_b=rhow.*g.*((n*Qw./W).^0.6).*((-1.*slope).^0.7); %Units: Pa, standard units of shear stress. Eq. 6 of Yanites et al. 2013
    tau_b(tau_b<0)=0; % Redefine negative shear as 0.

    %% Transport Capacity Calculation
    % Calculate transport capacity, component by component, Eq. 5 in
    % Yanites et al. 2013 from Wong and Parker, 2006

%     tau_s=tau_b./(rhow.*R.*g.*D); % Array of Shield's stress at each node along the profile. Unitless
%     xcess_cap=(tau_s-tau_crit); % Shear that is able to transport bedload. Unitless
%     xcess_cap(xcess_cap<0)=0; % Sets xcess_cap to 0 if negative (cannot have negative excess capacity)
%     qc_s=3.97.*(xcess_cap.^(1.5)); % Intermediate step in transport capacity calculation. Unitless
%     qc_s(tau_s<=0)=0;
%     qt=qc_s.*D.*((D.*g.*R).^0.5); %Specific transport capacity (m^2/s)
%     qt_annual=qt.*(3.1536e7); % Conversion of specific transport capacity from per second to per year. Units: (m^2/year)

    % No need for upstream loop if keeping fixed elevation
    % (Z_Zhada_top), since hydraulically uncoupled.

%         %% Sediment Transportation Calculation Loop (Upstream of Capture Point)
%         % Loop for modeling sediment transport and change in bed elevation
%         % in the upstream segment.
%         
%         for j=2:Zhada_capI
%             
%             Qs_loc(j)= beta.*eroded_sedsupply(j).*(Ah(j)-Ah(j-1)); %Calc. local bedload sediment supply (via erosion from tributaries and hillslopes along reach). Units:(m^3/yr)
%             Qs_n=Qs_down+Qs_loc(j); %Calc. total bedload sediment supply into reach (node): supply from upstream reach plus local supply. Does not include previous bedload deposit (i.e. sed_depth) Units: (m^3/yr)
%             qs(j)=Qs_n./W(j); % Convert to specific bedload sediment supply to cell. Units: m^2/year
%             dz_s(j)=(1/(1-lambda)).*dt.*(qt_annual(j)-qs(j))./(x(j)-x(j-1)); % Calc. change in sediment thickness using Eq. 2 of Yanites et al. 2013 (Exner Equation). Positive dz_s implies removal of sediment from storage in the bed. Units: m
%             Qs_pass=qt_annual(j).*W(j).*dt; % Dummy variable defined as maximum potential sediment supplied to downstream reach using transport capacity. Units: (m^3/yr)
%             
%             if dz_s(j)>sed_depth(j) && sed_depth(j)>=0 % Condition passes if flow conditions result in removal of all sediment from bed at reach. 
%                 dz_s(j)=sed_depth(j); % Redefine change in sediment thickness as the entire sed_depth as all sediment is removed from reach.
%                 Qs_pass=Qs_n; % Redefine Q_pass as sediment supply at reach. Units: (m^3/yr)
%             end
%             
%             Qs_down=(dz_s(j).*W(j).*(x(j)-x(j-1)))+(Qs_pass); %Redefine the sediment output from the reach. Consists of sediment passing through reach and/or locally generated (Q_pass) and sediment removed from storage on the bed. Units: (m^3/yr)
%         
%             if Qs_down < 0 % Condition that ensures minimum sediment output from reach is 0.
%                 Qs_down = 0;
%             end       
%         end

    %% Redefine/Setup Variables for Downstream Loop

    captureA=Ah(Zhada_capI); %Dummy variable to remember capture area

    Ah(Zhada_capI)=0; % Set downstream area to zero (to avoid a negative result in the first iteration)
%     Qs_down=0; % No sediment supply from reach upstream of capture location. Hydraulically disconnected.

    %% Sediment Transportation Calculation Loop (Downstream of Capture Point)
    % Loop for modeling sediment transport and change in bed elevation
    % in the downstream segment. See upstream loop for comments.

%     for j=(Zhada_capI+1):length(x)
% 
%         Qs_loc(j)= beta.*eroded_sedsupply(j).*(Ah(j)-Ah(j-1));
%         Qs_n=Qs_down+Qs_loc(j);
%         qs(j)=Qs_n./W(j);
%         dz_s(j)=(1/(1-lambda)).*dt.*(qt_annual(j)-qs(j))./(x(j)-x(j-1));
%         Qs_pass=qt_annual(j).*W(j).*dt;
% 
%         if dz_s(j)>sed_depth(j) && sed_depth(j)>=0
%             dz_s(j)=sed_depth(j);
%             Qs_pass=Qs_n;
%         end
% 
%         Qs_down=(dz_s(j).*W(j).*(x(j)-x(j-1)))+(Qs_pass);
% 
%             if Qs_down < 0
%                 Qs_down = 0;
%             end
%     end

    %% Update variables and quality control

    % Restore area to capture location
    Ah(Zhada_capI)=captureA;

    % Look for hills and deposit:
%     dz_s(tau_s==0)=(1/(1-lambda)).*dt.*(0-qs(tau_s==0))./(mean(diff(L_subsamp))); %Finds each node where boundary shear stress is 0 and deposits the appropriate sediment supply transported into each node. Units: m

    %Adjust the sediment depth array to account for changes in sediment thickness. Sed_depth goes to zero if dz_s is greater than sed_depth
%     sed_depth=sed_depth-dz_s; 

    % Calculation of bedrock incision over interval dt. Units: (m);
    dz_b=kf.*tau_b.*dt;
%     dz_b(sed_depth>depth_threshold)=0; % No change in bedrock elevation if sediment thickness is greater than depth_threshold.

    % Update bedrock elevation to account for bedrock incision.  
%     z(sed_depth<=depth_threshold)=z(sed_depth<=depth_threshold)+dz_b(sed_depth<=depth_threshold); %If sed_depth at or below threshold, bedrock is removed.

    z = z + dz_b; %Version for no sed transport

%         % Update surface elevation.
%         topo = z + sed_depth;
%         
    % Update total bedrock incision.
%    tote(sed_depth<=depth_threshold)=tote(sed_depth<=depth_threshold)+dz_b(sed_depth<=depth_threshold); %Update total bedrock erosion.

    tote = tote + dz_b; %Version for no sed transport

    %Fill or update matrix to calculate average incision over past 10ka
%     if i<10000/dt
%         
%         dz_b_t(i,:)=dz_b./dt;
% 
%     elseif i>=10000/dt
%         
%         ff=mod(i,10000/dt)+1;
%         dz_b_t(ff,:)=dz_b./dt;
% 
%     end
% 
%     % Update average erosion for local sed supply calculation (only for
%     % t > 10000 yr)
%     if (i*dt)>10000
% 
%         eroded_sedsupply= -1.*mean(dz_b_t);
% 
%         %Set minimum eroded_sedsupply to 0.0001 mm/yr
%         %eroded_sedsupply(eroded_sedsupply<(1*10^-7))=(1*10^-7);
% 
%     end
    
    %% Plotting Routine

    if mod(i*dt,50000)==0 || i==1 % Change to adjust plotting frequency.
        
        % Pin z and sed_depth at outlet for plotting purposes.

        z(end) = 904; %pinning bottom of profile to local baselevel
%         sed_depth(end) = 0; %pin sed depth at end to zero

        k=k+1;
        close all
        
        % Calculate %change in surface elevation since last plotting step
        % (currently set to 50 kyr).
        
        pct_topo_diff = (topo-topolast)./topolast; % Percent change in surface elevation relative to the previous plotting step's surface elevation
        

        %average erosion rate since last time step

        DZ=uplift+((zlast-z)./((i.*dt)-tlast));
%         DS=(sed_depth-sdlast)./((i.*dt)-tlast);
%         figure2 =figure('Position',[1 scrsz(4)/8 8*scrsz(3)/16 21.5*scrsz(4)/40],'PaperPositionMode','auto');
% 
%         subplot1=subplot(2,3,1,'Position',[.05 .50 .3 .4]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015]);%,'hold','all')
%         axis(subplot1,'equal')
%         box(subplot1,'on')
%         hold(subplot1,'all')
% %         imagesc(XX(1,:),YY(:,2),H,'Parent',subplot1)%,);
%         axis xy
%         colormap(subplot1,'gray')
% 
%         freezeColors
%         scatter(X,Y,30,(DZ).*1000,'o','Parent',subplot1,'filled')%,'Parent',axes1);
%         caxis(subplot1,[0 3]);
%         colormap(subplot1,'jet')
%         colorbar
%         scatter(X_Zhada_cap,Y_Zhada_cap,130,[1 0 0],'linewidth',3.0)
%         title('Erosion Rate (mm/yr)','fontsize',14)
%         xlim([8E4 6.4E5]);
%         ylim([3.35E6 3.68E6]);
% 
%         subplot2= subplot(2,3,2,'Position',[.35 .50 .3 .4]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015]);
%         axis(subplot2,'equal')
%         box(subplot2,'on')
%         hold(subplot2,'all')
% 
% %         imagesc(XX(1,:),YY(:,2),H2,'Parent',subplot2)%,);
%         axis xy
%         colormap(subplot2,'gray')
% 
%         scatter(X,Y,30,[0 0 1],'o','Parent',subplot2,'filled')
% 
%         caxis(subplot2,[0 1000]);
%         colormap(subplot2,'jet')
%         colorbar
%         scatter(X_Zhada_cap,Y_Zhada_cap,130,'rx','linewidth',3.0)
% 
%         title('Elevation change (m)','fontsize',14)
% 
%         xlim([8E4 6.4E5]);
%         ylim([3.35E6 3.68E6]);
% 
%         subplot3= subplot(2,3,6,'Position',[.71 .05 .25 .4]);%,'xlim',[0 1500],'ylim',[0 1500]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015])
%         box(subplot3,'on')
%         hold(subplot3,'all')
% 
%         plot(x./1000,z+sed_depth,x./1000,z,'Parent',subplot3,'linewidth',2.0)
%         scatter(x(Zhada_capI)./1000,z(Zhada_capI)+sed_depth(Zhada_capI),140,'rx','linewidth',3.0)
% 
%         title([num2str(i.*dt./1000000,'%4.2f\n') ' My'],'fontsize',14)
%         xlabel('Distance downstream (km)','fontsize',14)
%         ylabel('Elevation (m)','fontsize',14)
%         xlim([0 800]);
%         ylim([0 8000]);
% 
%         subplot4=subplot(2,3,5,'Position',[.35 .05 .3 .4]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015]);%,'hold','all')
% 
%         axis(subplot4,'equal')
%         box(subplot4,'on')
%         hold(subplot4,'all')
% 
% %         imagesc(XX(1,:),YY(:,2),H3,'Parent',subplot4)%,);
%         axis xy
%         colormap(subplot4,'gray')
% 
%         freezeColors
% 
%         scatter(X,Y,30,-1.*tote,'o','Parent',subplot4,'filled')%
%         caxis(subplot4,[0 4000]);
% 
%         colormap(subplot4,'jet')
%         colorbar
%         scatter(X_Zhada_cap,Y_Zhada_cap,130,'rx','linewidth',3.0)
% 
%         xlim([8E4 6.4E5]);
%         ylim([3.35E6 3.68E6]);
%         title('Total erosion (m)','fontsize',14)
% 
%         subplot6=subplot(2,3,4,'Position',[.05 .05 .3 .4]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015]);%,'hold','all')
% 
%         axis(subplot6,'equal')
%         box(subplot6,'on')
%         hold(subplot6,'all')
% 
% %         imagesc(XX(1,:),YY(:,2),H,'Parent',subplot6)%,);
%         axis xy
%         colormap(subplot6,'gray')
% 
%         freezeColors
% 
%         scatter(X,Y,30,1000.*DS,'o','Parent',subplot6,'filled')%
%         caxis(subplot6,[-1 1]);
% 
%         colormap(subplot6,'jet')
%         colorbar
%         xlim([8E4 6.4E5]);
%         ylim([3.35E6 3.68E6]);
%         scatter(X_Zhada_cap,Y_Zhada_cap,130,'rx','linewidth',3.0)
% 
%         title('Sedimentation rate (mm/yr)','fontsize',14)
%         annotation(figure2,'textbox',...
%             [0.69 0.50 0.35 0.4],...
%             'String',{model_name,...%['Bedrock Erodability K_f= ' num2str(kf)],... %num2str(kf_Zhada) ' to ' num2str(kf_Orogen)],...
%             ['Rock Uplift = ' num2str(min(uplift).*1000) ' to ' num2str(max(uplift).*1000) 'mm/yr'],...%['URG subsidence= ' num2str(uplift(1).*1000) 'mm/yr'],... %Changed values to make sure code ran (check with previous version of Alps code)
%             ['Capture location = '  num2str(L_Zhada_cap./1000) ' km'],['Time of capture= ' num2str(t_warmup./1000000) ' My']},...
%             'FitHeightToText','on','FontSize',14,'linestyle','none');
%         drawnow
%         print('-dpng',['./moviefiles/' model_name '_n_' num2str(k)])
%         savefig(figure2, ['./output/' model_name '_n_' num2str(k)],'compact')
%         cla(subplot1)
%         cla(subplot2)
%         cla(subplot3)
%         cla(subplot4)
%         cla(subplot6)

        save(['./output/' model_name '_n_' num2str(k)],'pct_topo_diff', 'tau_b','uplift', 'Qw', 'W', 'Ah','x','z','kf','Z_Zhada_top','L_Zhada_cap','age_cap_input','i','dz_b','tote','zcap','DZ','dt')
        tlast=dt.*i;
        zlast=z;
%         sdlast=sed_depth;
        topolast = topo;
        toc
    end

%reset variables for next timestep
% Qs_down=0;
% dz_s(1:end)=0; 

end

%% Reset variables to run post-capture model

tote(1:end)=0; % Reset total erosion.

% Adding drainage capture area to profile and updating water, width, and sediment variables to reflect.
Ah(Zhada_capI+1:end)=Ah(Zhada_capI+1:end)+Ah(Zhada_capI)-Ah(1);
Qw=kQ.*(Ah.^eQ);
W=kw.*(Qw.^ew);

%Redefine Z_Zhada_base in case different from initially defined elevation.
%Z_Zhada_top = topo(1);
Z_Zhada_base = Z_Zhada_top - 800; % Subsequently ensure Zhada Fm. is 800m thick.

%Redefine local sediment supply
% Qs_loc=beta.*[eroded_sedsupply(1).*(Ah(1)) eroded_sedsupply(2:end).*diff(Ah)]; 

%Store variables at time of capture
zcap=z; % Bedrock elevations at capture
% sedcap=sed_depth; % Sediment thicknesses at capture
topocap=zcap; %+sedcap; % Surface elevations at capture

%% Post-capture loop

for i=1:length(postcapt)
    
    %% Topography and Lithology Setup
    
    ToBasement = z(Zhada)<=Z_Zhada_base; %Logical index to find where it has eroded to basement in the Zhada.
    kf(ToBasement) = kf_input; %Redefine the erodibility where basement is exposed in the Zhada.
    
    % Impose rock uplift
    
    z=z+(uplift.*dt);
    
    % Pin z and sed_depth at outlet
    
    z(end) = 904; % pinning outlet to local baselevel
%     sed_depth(end)=0;
    
    % Update topo based on imposed uplift
    
    topo=z; %+sed_depth;
    
    %Calculate channel slope
    
    slope=[diff(topo)./diff(x) 0];
    
    %% Boundary Shear Stress Calculation
    
    % calc shear stress
    tau_b=rhow.*g.*((n*Qw./W).^0.6).*((-1.*slope).^0.7);
    tau_b(tau_b<0)=0;
    
      
    %% Transport Capacity Calculation (same as in precap loop)
%     tau_s=tau_b./(rhow.*R.*g.*D);
%     xcess_cap=(tau_s-tau_crit);
%     xcess_cap(xcess_cap<0)=0;
%     qc_s=3.97.*(xcess_cap.^(1.5)); 
%     qc_s(tau_s<=0)=0;
%     qt=qc_s.*D.*((D.*g.*R).^0.5);
%     qt_annual=qt.*(3.1536e7);
% 
%     %% Sediment Transportation Calculation Loop
%     
%     for j=2:length(x)
%         Qs_loc(j)= beta.*eroded_sedsupply(j).*(Ah(j)-Ah(j-1));
%         Qs_n=Qs_down+Qs_loc(j);
%         qs(j)=Qs_n./W(j);
%         dz_s(j)=(1/(1-lambda)).*dt.*(qt_annual(j)-qs(j))./((x(j)-x(j-1)));
%         Qs_pass=qt_annual(j).*W(j).*dt;
%         
%         if dz_s(j)>sed_depth(j) && sed_depth(j)>=0
%             dz_s(j)=sed_depth(j);
%             Qs_pass=Qs_n;
%         end
%         
%         Qs_down=(dz_s(j).*W(j).*(x(j)-x(j-1)))+(Qs_pass);
% 
%         if Qs_down < 0
%                 Qs_down = 0;
%         end
%         
%     end
    
    %% Update variables and quality control
    
    %Adjust the sediment depth array to account for changes in sediment thickness. Sed_depth goes to zero if dz_s is greater than sed_depth
%     sed_depth=sed_depth-dz_s;
    
    % Calculation of bedrock incision over interval dt. Units: (m);
    dz_b=kf.*tau_b.*dt;
%     dz_b(sed_depth>depth_threshold)=0; % No change in bedrock elevation if sediment thickness is greater than depth_threshold.
    
    % Update bedrock elevation to account for bedrock incision. 
%     z(sed_depth<=depth_threshold)=z(sed_depth<=depth_threshold)+dz_b(sed_depth<=depth_threshold);
    
    z = z + dz_b; %Calculation for no sed trans
    tote = tote + dz_b; %Calculation for no sed trans
    % Update total bedrock incision
%     tote(sed_depth<=depth_threshold)=tote(sed_depth<=depth_threshold)+dz_b(sed_depth<=depth_threshold);
    
       
    %Keep track of incision to calculate average incision over past 10ka
%     ff=mod(i,10000/dt)+1;
%     dz_b_t(ff,:)=dz_b./dt;
    
    %Calculate eroded_sedsupply using average incision over past 10ka
%     eroded_sedsupply= -1.*mean(dz_b_t);
    
    %Set minimum eroded_sedsupply to 0.0001 mm/yr
    %eroded_sedsupply(eroded_sedsupply<(1*10^-7))=(1*10^-7);
         
    %% Plotting Routine
    
    if mod(i*dt,20000)==0 || i==length(postcapt)
        
        % Pin z and sed_depth at outlet 

        z(end) = 904; %pinning bottom of profile to local baselevel
%         sed_depth(end) = 0; %pin sed depth at end to zero
        
        k=k+1;
        
        hold off
        close all
        DZ=uplift+((zlast-z)./((i.*dt)-tlast));
%         DS=(sed_depth-sdlast)./((i.*dt)-tlast);
        
%         figure2 =figure('Position',[1 scrsz(4)/8 8*scrsz(3)/16 21.5*scrsz(4)/40],'PaperPositionMode','auto');
%         subplot1=subplot(2,3,1,'Position',[.05 .50 .3 .4]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015]);%,'hold','all')
%         axis(subplot1,'equal')
%         box(subplot1,'on')
%         hold(subplot1,'all')
% %         imagesc(XX(1,:),YY(:,2),H,'Parent',subplot1)%,);
%         axis xy
%         colormap(subplot1,'gray')
%         
%         freezeColors
%         scatter(X,Y,30,(DZ).*1000,'o','Parent',subplot1,'filled')%,'Parent',axes1);
%         caxis(subplot1,[0 3]);
%         colormap(subplot1,'jet')
%         colorbar
%         title('Erosion Rate (mm/yr)','fontsize',14)
%         xlim([8E4 6.4E5]);
%         ylim([3.35E6 3.68E6]);
%         
%         subplot2= subplot(2,3,2,'Position',[.35 .50 .3 .4]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015]);
%         axis(subplot2,'equal')
%         box(subplot2,'on')
%         hold(subplot2,'all')
%         
% %         imagesc(XX(1,:),YY(:,2),H2,'Parent',subplot2)%,);
%         axis xy
%         colormap(subplot2,'gray')
%         
%         freezeColors
%         scatter(X,Y,30,topocap-(z+sed_depth),'o','Parent',subplot2,'filled')
%         caxis(subplot2,[0 1000]);
%         colormap(subplot2,'jet')
%         colorbar
%         xlim([8E4 6.4E5]);
%         ylim([3.35E6 3.68E6]);
%         title('Elevation change since capture (m)','fontsize',14)
%         
%         subplot3= subplot(2,3,6,'Position',[.71 .05 .25 .4]);%,'xlim',[0 1500],'ylim',[0 1500]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015])
%         %  axis(subplot3,'equal')
%         box(subplot3,'on')
%         hold(subplot3,'all')
%         
%         plot(x./1000,z+sed_depth,x./1000,z,'Parent',subplot3,'linewidth',2.0)
%         plot(x./1000,topocap,'k--','Parent',subplot3,'linewidth',2.0)
%         hold on
%         title([num2str(i.*dt./1000000,'%4.2f\n') ' My'],'fontsize',14)
%         xlabel('Distance downstream (km)','fontsize',14)
%         ylabel('Elevation (m)','fontsize',14)
%         xlim([0 800]);
%         ylim([0 8000]);
%         
%         
%         subplot4=subplot(2,3,5,'Position',[.35 .05 .3 .4]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015]);%,'hold','all')
%         
%         axis(subplot4,'equal')
%         box(subplot4,'on')
%         hold(subplot4,'all')
%         
% %         imagesc(XX(1,:),YY(:,2),H3,'Parent',subplot4)%,);
%         axis xy
%         colormap(subplot4,'gray')
%         
%         freezeColors
%         
%         scatter(X,Y,30,-1.*tote,'o','Parent',subplot4,'filled')%
%         caxis(subplot4,[0 4000]);
%         
%         colormap(subplot4,'jet')
%         colorbar
%         xlim([8E4 6.4E5]);
%         ylim([3.35E6 3.68E6]);
%         title('Total Erosion since capture (m)','fontsize',14)
%         
%         
%         subplot6=subplot(2,3,4,'Position',[.05 .05 .3 .4]);%,'xlim',[5.05705195739193 9.75484761581863],'ylim',[46.1690721874882 52.2956536862015]);%,'hold','all')
%         
%         axis(subplot6,'equal')
%         box(subplot6,'on')
%         hold(subplot6,'all')
%         
% %         imagesc(XX(1,:),YY(:,2),H,'Parent',subplot6)%,);
%         axis xy
%         colormap(subplot6,'gray')
%         
%         freezeColors
%         
%         scatter(X,Y,30,DS.*1000,'o','Parent',subplot6,'filled')%
%         caxis(subplot6,[-.5 .5]);
%         
%         colormap(subplot6,'jet')
%         colorbar
%         xlim([8E4 6.4E5]);
%         ylim([3.35E6 3.68E6]);
%         title('Sedimentation rate (mm/yr)','fontsize',14)
%         annotation(figure2,'textbox',...
%             [0.69 0.50 0.35 0.4],...
%             'String',{model_name,...%['Bedrock erodability K_f= '  num2str(kf)],...%num2str(kf_Zhada) ' to ' num2str(kf_Orogen)],...
%             ['Rock Uplift = ' num2str(min(uplift).*1000) ' to ' num2str(max(uplift).*1000) 'mm/yr']%,...%['URG subsidence= ' num2str(uplift(1).*1000) 'mm/yr'],... %Changed values to make sure code ran (check with previous version of Alps code)
%             ['Capture location = '  num2str(L_Zhada_cap./1000) ' km downstream'],['Time of capture= ' num2str(t_warmup./1000000) ' My']
%             },...
%             'FitHeightToText','on','FontSize',14,'linestyle','none');
%         drawnow
%         print('-dpng',['./moviefiles/' model_name 'postcap_n_' num2str(k)])
%         savefig(figure2, ['./output/' model_name 'postcap_n_' num2str(k)],'compact')
        save(['./output/' model_name '_postcap_' num2str(k)],'tau_b','uplift', 'Qw', 'W', 'Ah','x','z','kf','Z_Zhada_top','L_Zhada_cap','age_cap_input','i','dz_b','tote','zcap','DZ','dt')
%         cla(subplot1)
%         cla(subplot2)
%         cla(subplot3)
%         cla(subplot4)
        tlast=dt.*i;
        zlast=z;
%         sdlast=sed_depth;
        
        toc
    end
    
    %reset variables
%     Qs_down=0;
%     dz_s=0;

end

z_modeled = z;
save(['./output/' model_name '_final_profile.mat'],'-v7.3')
toc
end

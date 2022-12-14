%% 16.11.22 - Connor Tynan - Parameter fitting - Stefano data - MATLAB
%
% Description: First attempt at fitting bacterial growth data to gLV equations
%
% Want to quantify:
%
% - Interactivity parameters: m_{ij} - m_{ii} describes how species interact
%   with one-self.
% - Per-species growth rate.
%
% Assumuptions:
%
% - Self-interactivity parameters evolve with introduction of new species (in higher-dimensional systems).
% - For simplicity, currently assume that growth rate is universal between dimensions and static.
%
% Optimal solution requires a good level of exploration, parameter bounds
% are very sensitive to change along with modification to nsteps.

clc; clf; close all; clear;

% Importing the data - See importfile.m function file for details

% Importing data

sheet1 = importfile("ROOT_HERE","S. aureus mono-culture","A3:G16");
sheet2 = importfile("ROOT_HERE","P. aeruginosa mono-culture","A3:G16");
sheet3 = importfile("ROOT_HERE","S. aureus co-culture","A3:G16");
sheet4 = importfile("ROOT_HERE","P. aeruginosa co-culture","A3:G16");

% Creating matrices to work with from data

sh1 = table2array(sheet1);
sh2 = table2array(sheet2);
sh3 = table2array(sheet3);
sh4 = table2array(sheet4);

% Housekeeping

clear sheet1 sheet2 sheet3 sheet4

% Calculating standard deviation - sd = standard deviation

sd.sh1 = zeros(length(sh1),1); sd.sh2 = zeros(length(sh2),1);
sd.sh3 = zeros(length(sh3),1); sd.sh4 = zeros(length(sh4),1);

% Averaging using standard deviation - Omitting N/A & NANs

for i = 1:14
    sd.sh1(i) = std(rmmissing(sh1(i,2:7)));
    sd.sh2(i) = std(rmmissing(sh2(i,2:7)));
    sd.sh3(i) = std(rmmissing(sh3(i,2:7)));
    sd.sh4(i) = std(rmmissing(sh4(i,2:7)));
end

% General parameters

t0 = 0; dt = 0.01; h = dt/2; t1 = length(sh1); t = t0:dt:t1; % Time parameters
nsteps = 25; % Number of spacial steps - lb, ...nsteps... , ub

% 1D-Variables - Variables for mono-culture

mu1 = linspace(0.97,1.25,nsteps);      mu2 = linspace(0.95,1,nsteps);
m11 = linspace(-7e-11,-2e-11,nsteps);   m22 = linspace(-1e-10,-6e-11,nsteps);

%% 1D Computations - Parameter estimation for mono-cultures

% Logic: Vary 2 parameters simultaneously, taking a measure of distance each time.

% Least squares arrays - Will hold distances for each pair of parameters
ls_yd1 = zeros(nsteps,nsteps);
ls_yd2 = zeros(nsteps,nsteps);

% Functions for extended Euler method / RK2
fyd = @(t,y,mu,m) y*mu + m*y.^2;

for k = 1:nsteps
    for j = 1:nsteps
        % Initialisation

        % Solution arrays
        yd1 = zeros(round(t1/dt),1);   % dummy array to hold solution
        yd2 = zeros(round(t1/dt),1);   % ' ' '
        
        % Initial condition
        yd1(1) = sd.sh1(1);
        yd2(1) = sd.sh2(1);

        % RSS (Residual sum of squares) parameters
        rss_yd1 = sd.sh1(1);
        rss_yd2 = sd.sh2(1);
        
        for i = 1:(numel(t)-1)
            % Solving ODEs using Extended Euler method
            yd1(i+1) = yd1(i) + dt*fyd(t(i) + h, yd1(i) + h*fyd(t(i),yd1(i),mu1(j),m11(k)),mu1(j),m11(k));
            yd2(i+1) = yd2(i) + dt*fyd(t(i) + h, yd2(i) + h*fyd(t(i),yd2(i),mu2(j),m22(k)),mu2(j),m22(k));
            
            % Calculating difference using least squares method
            if i*dt > 0 
               if floor(i*dt) == i*dt
                   b = i*dt;
                   rss_yd1 = rss_yd1 + (sd.sh1(i*dt) - yd1(i))^2;
                   rss_yd2 = rss_yd2 + (sd.sh2(i*dt) - yd2(i))^2;
               end
            end
        end
        % Storing distance for each parameter pair
        ls_yd1(k,j) = rss_yd1;
        ls_yd2(k,j) = rss_yd2;
    end
end

% Finding optimum parameter pairings
[j1, k1] = find(abs(ls_yd1)==min(abs(ls_yd1(:)))); mu1 = mu1(j1); m11 = m11(k1);
[j2, k2] = find(abs(ls_yd2)==min(abs(ls_yd2(:)))); mu2 = mu2(j2); m22 = m22(k2);

disp(['Optimum parameters for species 1: ' 'mu1 = ' num2str(mu1) ' & ' 'm11 = ' num2str(m11)])
disp(['Optimum parameters for species 2: ' 'mu2 = ' num2str(mu2) ' & ' 'm22 = ' num2str(m22)])

%% Post calculations - Step forward using optimum parameters

% Updating time parameters
dt = 0.001; t1 = 25; t=t0:dt:t1; 

% Initialising new solution vectors
y.s1 = zeros(round(t1/dt),1); y.s1(1) = sd.sh1(1);
y.s2 = zeros(round(t1/dt),1); y.s2(1) = sd.sh2(1);

% Solving using optimum parameter pairings
for i = 1:(numel(t)-1)
    y.s1(i+1) = y.s1(i) + dt*fyd(t(i) + h, y.s1(i) + h*fyd(t(i),y.s1(i),mu1,m11),mu1,m11);
    y.s2(i+1) = y.s2(i) + dt*fyd(t(i) + h, y.s2(i) + h*fyd(t(i),y.s2(i),mu2,m22),mu2,m22);
end

%% Plots & Evaluation - Visualising results / appropriateness of fit - Logarithmic graphs

clf; close all; % Figure 1 - Species 1 (S.aureus) - Logarithmic y-axis

grid minor; hold on; grid; box on; 

plot(0:1:13,sd.sh1,'r.', 'MarkerSize', 15); plot(t,y.s1,'b-')

xlabel('Time')
ylabel('Bacteria count (ml-1)')
title('Species 1 - S. aureus - 1D Standard deviation data parameter estimation')

xlim([0 t1+1]); ylim([y.s1(1) y.s1(end)+5e10]); set(gca, 'YScale', 'log')

figure % Figure 2 - Species 2 (P.aeruginosa) - Logarithmic y-axis

grid minor; hold on; grid; box on; 

plot(0:1:13,sd.sh2,'r.', 'MarkerSize', 15); plot(t,y.s2,'b-')

xlabel('Time')
ylabel('Bacteria count (ml-1)')
title('Species 2 - P.Aeruginosa - 1D Standard deviation data parameter estimation')

xlim([0 t1+1]); ylim([y.s2(1) y.s2(end)+5e10]); set(gca, 'YScale', 'log')

%% Part 2 - 2D Computations - Parameter estimation for interacting cultures
% 
% - Equations are now non-linear and our parameters of interest are m12 and
%   m21. Proceed as above, varying parameters simultaneously and exploring
%   optimal parameters by varying upper and lower bounds.

% 2D-Variables - Variables for dual-culture - Interactivity parameters

m11 = linspace(-5e-8,-2e-9,nsteps); m12 = linspace(-3e-10,-1e-11,nsteps);
m21 = linspace(1e-9,1.5e-9,nsteps); m22 = linspace(-1e-10,-9e-13,nsteps);

t0 = 0; dt = 0.1; h = dt/2; t1 = length(sh3); t = t0:dt:t1; % Time parameters

% % Least squares arrays - Will hold distances for each pair of parameters
% ls_yd3 = zeros(1,1);
% ls_yd4 = zeros(1,1);

% Functions for extended Euler method / RK2
fyd2 = @(t,y,x,mu,m,m2) y*mu + m*y.^2 + m2*x*y;

dummy = inf;

for n = 1:nsteps
    for l = 1:nsteps
        for k = 1:nsteps
            for j = 1:nsteps
                % Initialisation
        
                % Solution arrays
                yd3 = zeros(round(t1/dt),1);   % dummy array to hold solution
                yd4 = zeros(round(t1/dt),1);   % ' ' '
                
                % Initial condition
                yd3(1) = sd.sh3(1);
                yd4(1) = sd.sh4(1);
        
                % RSS (Residual sum of squares) parameters
                rss_yd3 = sd.sh3(1);
                rss_yd4 = sd.sh4(1);
                
                for i = 1:(numel(t)-1)
                    % Solving ODEs using Extended Euler method
                    yd3(i+1) = yd3(i) + dt*fyd2(t(i) + h, yd3(i) + h*fyd2(t(i),yd3(i),yd4(i),mu1,m11(n),m12(l)), ...
                        yd4(i) + h*fyd2(t(i),yd4(i),yd3(i),mu2,m22(j),m21(k)),mu1,m11(n),m12(l));
                    yd4(i+1) = yd4(i) + dt*fyd2(t(i) + h, yd4(i) + h*fyd2(t(i),yd4(i),yd3(i),mu2,m22(j),m21(k)), ...
                        yd3(i) + h*fyd2(t(i),yd3(i),yd4(i),mu1,m11(n),m12(l)),mu2,m22(j),m21(k));
                    
                    % Calculating difference using least squares method
                    if i*dt > 0 
                       if floor(i*dt) == i*dt
                           b = i*dt;
                           rss_yd3 = rss_yd3 + (sd.sh3(i*dt) - yd3(i))^2;
                           rss_yd4 = rss_yd4 + (sd.sh4(i*dt) - yd4(i))^2;
                       end
                    end
                end
                % Storing distance for each parameter combination
                ls_yd = rss_yd3 + rss_yd3;
                if ls_yd < dummy
                    dummy = ls_yd;
                    res = [n, l; k, j];
                else
                    continue
                end
            end
        end
    end
end

%%

% Identifying parameter estimates
m11 = m11(n); m12 = m12(l); m21 = m21(k); m22 = m22(j);

disp(['Parameter estimates: ' 'm11 = ' num2str(m11) ' | m12 = ' num2str(m12) ' | m21 = ' num2str(m21) ' | m22 = ' num2str(m22)])

%% 2D - Post calculations - Step forward using optimum parameters

% Updating time parameters
dt = 0.0001; t1 = 14; t=t0:dt:t1; 

% Initialising new solution vectors
y.s3 = zeros(round(t1/dt),1); y.s3(1) = sd.sh3(1);
y.s4 = zeros(round(t1/dt),1); y.s4(1) = sd.sh4(1);

% Solving using optimum parameter pairings
for i = 1:(numel(t)-1)
            y.s3(i+1) = y.s3(i) + dt*fyd2(t(i) + h, y.s3(i) + h*fyd2(t(i),y.s3(i),y.s4(i),mu1,m11,m12), ...
                y.s4(i) + h*fyd2(t(i),y.s4(i),y.s3(i),mu2,m22,m21),mu1,m11,m12);
            y.s4(i+1) = y.s4(i) + dt*fyd2(t(i) + h, y.s4(i) + h*fyd2(t(i),y.s4(i),y.s3(i),mu2,m22,m21), ...
                y.s3(i) + h*fyd2(t(i),y.s3(i),y.s4(i),mu1,m11,m12),mu2,m22,m21);
end

%% 2D - Plots & Evaluation - Visualising results / appropriateness of fit - Logarithmic graphs

clf; close all; % Figure 1 - Species 1 (S.aureus) - Logarithmic y-axis

grid minor; hold on; grid; box on; 

plot(0:1:13,sd.sh3,'r.', 'MarkerSize', 15); plot(t,y.s3,'b-')

xlabel('Time')
ylabel('Bacteria count (ml-1)')
title('Species 1 - S. aureus - 2D Standard deviation data parameter estimation')

% xlim([0 t1+1]); ylim([y.s3(1) y.s3(end)+5e10]); 
set(gca, 'YScale', 'log')

figure % Figure 2 - Species 2 (P.aeruginosa) - Logarithmic y-axis

grid minor; hold on; grid; box on; 

plot(0:1:13,sd.sh4,'r.', 'MarkerSize', 15); plot(t,y.s4,'b-')

xlabel('Time')
ylabel('Bacteria count (ml-1)')
title('Species 2 - P.Aeruginosa - 2D Standard deviation data parameter estimation')

% xlim([0 t1+1]); ylim([y.s4(1) y.s4(end)+5e10]); 
set(gca, 'YScale', 'log')

%% End 

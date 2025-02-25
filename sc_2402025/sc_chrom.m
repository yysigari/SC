% Chromaticity Optimization by Adjusting Sextupoles
% Clear workspace and figures
%clear; close all; clc;
%% %%  Energy Deviation Analysis:
runParallel = true;
dE_values = [-0.015, -0.01, 0, 0.01, 0.015]; % 2% energy deviation
figure;
for dE = dE_values
    [DA, RMAX, theta] = SCdynamicAperture(RING, dE, ...
              'nturns', 1000, ...
              'thetas', linspace(0, 2*pi, 18), ...
              'accuracy', 1e-5, 'launchOnOrbit',1, 'useOrbit6',1);
    
    polarplot([theta, theta(1)], [RMAX; RMAX(1)],'-o', 'MarkerSize', 4, 'LineWidth', 2);
    hold on;
end
hold off;
title('Dynamic Aperture for Different dE');

legend(arrayfun(@num2str, dE_values, 'UniformOutput', false));
% Save the figure as a PNG file
saveas(gcf, 'DynamicAperture_before_de.png');
%% 
% Define target chromaticities
targetChromX = 1.5;  % Horizontal target chromaticity
targetChromY = 1.2;  % Vertical target chromaticity

% Get the indices of the sextupoles
SF_idx = findcells(SC.RING, 'FamName', 'SF');
SD_idx = findcells(SC.RING, 'FamName', 'SD');

% Set initial sextupole strengths (tune these as needed)
K2_init = [-0.0005, -0.0005]; %

% Assign initial strengths
RING = setcellstruct(SC.RING, 'PolynomB', SF_idx, K2_init(1), 3);
RING = setcellstruct(SC.RING, 'PolynomB', SD_idx, K2_init(2), 3);

% Calculate initial chromaticity
[~, ~, chrom] = atlinopt(RING, 0, 1:length(SC.RING));
disp(['Initial Chromaticity: ', num2str(chrom)]);

runParallel = true;
dE_values = [-0.015, -0.01, 0, 0.01, 0.015]; % 2% energy deviation
figure;
for dE = dE_values
    [DA, RMAX, theta] = SCdynamicAperture(RING, dE, ...
              'nturns', 1000, ...
              'thetas', linspace(0, 2*pi, 18), ...
              'accuracy', 1e-5, 'launchOnOrbit',1, 'useOrbit6',1);
    
    polarplot([theta, theta(1)], [RMAX; RMAX(1)],'-o', 'MarkerSize', 4, 'LineWidth', 2);
    hold on;
end
hold off;
title('Dynamic Aperture for Different dE before optimization');

legend(arrayfun(@num2str, dE_values, 'UniformOutput', false));

%% 

% Objective function to minimiz
function err = chromaticityObjective(K2, RING, targetChromX, targetChromY, SF_idx, SD_idx)
    % Update sextupole strengths
    RING = setcellstruct(RING, 'PolynomB', SF_idx, K2(1), 3);
    RING = setcellstruct(RING, 'PolynomB', SD_idx, K2(2), 3);
    
    % Calculate chromaticity
    [~, ~, chrom] = atlinopt(RING, 0, 1:length(RING));
    
    % Error: Difference from target chromaticities
    err = sum((chrom - [targetChromX, targetChromY]).^2);
end

% Optimize sextupole strengths using fminsearch
options = optimset('Display', 'iter', 'TolX', 1e-6);
[K2_opt, fval] = fminsearch(@(K2) chromaticityObjective(K2, RING, targetChromX, targetChromY, SF_idx, SD_idx), K2_init, options);
disp(['Initial Chromaticity: ', num2str(k2)]);
%% 

% Apply the optimized strengths to the lattice
RING = setcellstruct(RING, 'PolynomB', SF_idx, K2_opt(1), 3);
RING = setcellstruct(RING, 'PolynomB', SD_idx, K2_opt(2), 3);

% Calculate and display optimized chromaticity
[~, ~, chromOpt] = atlinopt(RING, 0, 1:length(RING));
disp(['Optimized Chromaticity: ', chromOpt]);

% Plot the dynamic aperture to evaluate the effect
%figure;
%[DAs, RMAXs, thetas] = SCdynamicAperture(RING, 0);
%polarplot(thetas, RMAXs, '-o', 'LineWidth', 2);
%title('Dynamic Aperture after Chromaticity Optimization');
%%  Energy Deviation Analysis:
runParallel = true;
dE_values = [-0.015, -0.01, 0, 0.01, 0.015]; % 2% energy deviation
figure;
for dE = dE_values
    [DA_opt, RMAX_opt, theta_opt] = SCdynamicAperture(RING, dE, ...
              'nturns', 1000, ...
              'thetas', linspace(0, 2*pi, 18), ...
              'accuracy', 1e-5, 'launchOnOrbit',1, 'useOrbit6',1);
    
    polarplot([theta_opt, theta_opt(1)], [RMAX_opt; RMAX_opt(1)],'-o', 'MarkerSize', 4, 'LineWidth', 2);
    hold on;
end
hold off;
title('Dynamic Aperture for Different dE after optimization');
legend(arrayfun(@num2str, dE_values, 'UniformOutput', false));
% Save the figure as a PNG file
saveas(gcf, 'DynamicAperture_afteropt_de.png');

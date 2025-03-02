% Chromaticity Optimization by Adjusting Sextupoles
% Clear workspace and figures
%clear; close all; clc;
%% 

% Define target chromaticities
targetChromX = 0.95;  % Horizontal target chromaticity
targetChromY = 0.2;  % Vertical target chromaticity

% Get the indices of the sextupoles
SF_idx = findcells(SC.RING, 'FamName', 'SF');
SD_idx = findcells(SC.RING, 'FamName', 'SD');

% Check if indices are found
if isempty(SF_idx) || isempty(SD_idx)
    error('Sextupole indices not found. Check FamName in RING.');
end
%% 

% Set initial sextupole strengths (tune these as needed)
K2_init = [0.05, 0.05];

% Assign initial strengths
RING = setcellstruct(SC.RING, 'PolynomB', SF_idx, K2_init(1), 3);
RING = setcellstruct(SC.RING, 'PolynomB', SD_idx, K2_init(2), 3);

% Calculate initial chromaticity
try
    dP = 1e-6;
    [~, ~, chrom] = atlinopt(SC.RING, dP, 1:length(RING));
    if any(isnan(chrom) | isinf(chrom))
        error('Chromaticity calculation returned NaN or Inf.');
    end
catch ME
    warning('Failed to calculate chromaticity: %s', ME.message);
    chrom = [0.001, -0.001];  % Default to zero to avoid crashing
end
%% 
runParallel = true;
% Energy Deviation Analysis before optimization
dE_values = [-0.015, -0.01, 0, 0.01, 0.015];
figure;
for dE = dE_values
    [DA, RMAX, theta] = SCdynamicAperture(RING, dE, ...
        'nturns', 100, ...
        'thetas', linspace(0, 2*pi, 18), ...
        'accuracy', 1e-5, 'launchOnOrbit', 1, 'useOrbit6', 1);
    
    polarplot([theta, theta(1)], [RMAX; RMAX(1)],'-o', 'MarkerSize', 4, 'LineWidth', 2);
    hold on;
end
hold off;
title('Dynamic Aperture before Optimization');
legend(arrayfun(@num2str, dE_values, 'UniformOutput', false));
saveas(gcf, 'DynamicAperture_before_optimization.png');
%% 

% Optimize sextupole strengths using fminsearch
options = optimset('Display', 'iter', 'TolX', 1e-6);
[K2_opt, fval] = fminsearch(@(K2) chromaticityObjective(K2, RING, targetChromX, targetChromY, SF_idx, SD_idx), K2_init, options);

disp(['Optimized K2 Values: SF = ', num2str(K2_opt(1)), ', SD = ', num2str(K2_opt(2))]);

% Apply the optimized strengths to the lattice
RING = setcellstruct(RING, 'PolynomB', SF_idx, K2_opt(1), 1);
RING = setcellstruct(RING, 'PolynomB', SD_idx, K2_opt(2), 1);

% Calculate and display optimized chromaticity
[~, ~, chromop] = atlinopt(RING, 0, 1:length(RING));
disp(['Optimized Chromaticity: ', num2str(chromop)]);
%% 
runParallel = true;
dE_values = [-0.02, -0.01, 0, 0.01, 0.02]; % 2% energy deviation

% Energy Deviation Analysis after optimization
figure;
for dE = dE_values
    [DA_opt, RMAX_opt, theta_opt] = SCdynamicAperture(RING, dE, ...
        'nturns', 1000, ...
        'thetas', linspace(0, 2*pi, 18), ...
        'accuracy', 1e-5, 'launchOnOrbit', 1, 'useOrbit6', 1);
    
    polarplot([theta_opt, theta_opt(1)], [RMAX_opt; RMAX_opt(1)],'-o', 'MarkerSize', 4, 'LineWidth', 2);
    hold on;
end
hold off;
title('Dynamic Aperture after Optimization');
legend(arrayfun(@num2str, dE_values, 'UniformOutput', false));
saveas(gcf, 'DynamicAperture_after_optimization.png');


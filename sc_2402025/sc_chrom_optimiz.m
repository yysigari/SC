function F = chromaticityDAcost(k, RING, sext_indexes)
    % Update sextupole strengths
    RING = setcellstruct(RING, 'PolynomB', sext_indexes, k, 3);

    % Calculate chromaticity
    % Calculate and display optimized chromaticity
    [~, ~, chromOpt] = atlinopt(RING, 0, 1:length(RING));
    chromx = chromOpt(1);
    chromy = chromOpt(2);
    J1 = chromx^2 + chromy^2;  % Objective 1: Minimize chromaticity

    % Calculate Dynamic Aperture
    [~, RMAXs, thetas] = SCdynamicAperture(RING, 0);
    DA = polyarea(cos(thetas)'.*RMAXs, sin(thetas)'.*RMAXs);
    J2 = -DA;  % Objective 2: Maximize dynamic aperture

    % Return objective vector
    F = [J1, J2];
end
%% 
% Define sextupole indices
sext_indexes = findcells(RING, 'PolynomB');
sext_indexes = sext_indexes(cellfun(@(x) length(x)>=3 && x(3)~=0, getcellstruct(RING, 'PolynomB', sext_indexes)));

% Initial values and bounds
initial_k = getcellstruct(RING, 'PolynomB', sext_indexes, 3);
lb = -10 * abs(initial_k);  % Lower bounds
ub =  10 * abs(initial_k);  % Upper bounds

% Multi-Objective Genetic Algorithm options
options = optimoptions('gamultiobj', ...
    'PopulationSize', 100, ...
    'MaxGenerations', 50, ...
    'Display', 'iter', ...
    'UseParallel', true);
%parpool('local');  % Start parallel pool
% Run the MOGA
[k_opt, fval, exitflag, output, population, scores] = ...
    gamultiobj(@(k) chromaticityDAcost(k, SC.RING, sext_indexes), ...
    length(sext_indexes), [], [], [], [], lb, ub, [], options);

% Update RING with optimal values
RING = setcellstruct(RING, 'PolynomB', sext_indexes, k_opt(1,:), 3);

% Plot Pareto Front
figure;
plot(fval(:,1), -fval(:,2), 'bo');
xlabel('Chromaticity (\xi_x^2 + \xi_y^2)');
ylabel('Dynamic Aperture');
title('Pareto Front: Chromaticity vs. Dynamic Aperture');
grid on;



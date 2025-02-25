[DAs, RMAXs, thetas]  = SCdynamicAperture(SC.RING,10e-3, 'bounds' ,[0,1e-3],...
                                            'useOrbit6' ,1, 'nturns' , 1000);


%%
dE=1.e-3
if isempty(gcp('nocreate'))
    parpool;
end
runParallel = true;
%profile on;
[DA, RMAX, theta] = SCdynamicAperture(SC.RING, dE, ...
    'nturns', 1000, ...
    'thetas', linspace(0, pi, 16), ...
    'accuracy', 1e-5, ...
    'plot', 0, ...
    'verbose', 0,'launchOnOrbit',1, 'useOrbit6',1);
%profile viewer;
%% 1. Energy Deviation Analysis:
dE_values = [-0.02, -0.01, 0, 0.01, 0.02]; % 2% energy deviation
for dE = dE_values
    [DA, RMAXs, thetas] = SCdynamicAperture(SC.RING, dE, ...
              'nturns', 1000, ...
              'thetas', linspace(0, 2*pi, 18), ...
              'accuracy', 1e-5, 'launchOnOrbit',1, 'useOrbit6',1);

    polarplot([thetas, thetas(1)], [RMAXs; RMAXs(1)]);
    hold on;
end
hold off;
title('Dynamic Aperture for Different dE');
legend(arrayfun(@num2str, dE_values, 'UniformOutput', false));

%% Angular Resolution Study:
theta_counts = [8, 16, 32, 64];
for cnt = theta_counts
    [DA, RMAXs, thetas] = SCdynamicAperture(SC.RING, 0, ...
        'thetas', linspace(0, 2*pi, cnt), 'launchOnOrbit',1, 'useOrbit6',1);
    polarplot([thetas, thetas(1)], [RMAXs; RMAXs(1)]);
    hold on;
end
hold off;
title('Dynamic Aperture for Different Angular Resolutions');
legend(arrayfun(@num2str, theta_counts, 'UniformOutput', false));

%% 
% Example: Varying strength of the first quadrupole
k_values = linspace(1.2, 1.6, 5); % ±10% variation
for k = k_values
    tempRING = THERING;
    tempRING{20}.K = tempRING{20}.K * k;
    [DA, RMAXs, thetas] = SCdynamicAperture(tempRING, dE, ...
                      'nturns', 100, ...
                        'thetas', linspace(0, 2*pi, 18), ...
                       'accuracy', 1e-5,...
                          'launchOnOrbit',1, 'useOrbit6',1);
    polarplot([thetas, thetas(1)], [RMAXs; RMAXs(1)]);
    hold on;
end
hold off;
title('Effect of First Quadrupole Strength on Dynamic Aperture');
legend(arrayfun(@(x) sprintf('K=%.2f', x), k_values, 'UniformOutput', false));

%% Long-Term Stability Checks:
nturns_values = [500, 1000, 2000, 5000];
for nt = nturns_values
    [DA, RMAXs, thetas] = SCdynamicAperture(SC.RING, 0, 'nturns', nt, 'plot', false);
    polarplot([thetas, thetas(1)], [RMAXs; RMAXs(1)]);
    hold on;
end
hold off;
title('Dynamic Aperture with Different Turn Numbers');
legend(arrayfun(@num2str, nturns_values, 'UniformOutput', false));


%% 
% Convert polar coordinates to Cartesian coordinates
x = RMAXs .* cos(thetas);
y = RMAXs .* sin(thetas);


% Plot the dynamic aperture
figure;
plot(x, y, '-o', 'MarkerSize', 4, 'LineWidth', 2);
hold on;
plot(-x, -y, '-o', 'MarkerSize', 4, 'LineWidth', 2); % Mirror the negative side
axis equal;
xlabel('x [m]');
ylabel('y [m]');
title('Dynamic Aperture');
grid on;
legend('Dynamic Aperture');
hold off;
%% 
% Create a polar plot
figure;
polarplot(theta, RMAX, '-o', 'MarkerSize', 4, 'LineWidth', 2);
hold on
%qfb
%polarplot(thetas2, RMAXs2, '-ro', 'MarkerSize', 4, 'LineWidth', 2);
title('Dynamic Aperture in Polar Coordinates');
legend('Dynamic Aperture');
grid on;
hold off


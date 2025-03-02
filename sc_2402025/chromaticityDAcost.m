function F = chromaticityDAcost(k, RING, sext_indexes)
    % Update sextupole strengths
    RING = setcellstruct(RING, 'PolynomB', sext_indexes, k, 3);

    % Calculate Chromaticity
    try
    [~, ~, chromOpt] = atlinopt(RING, 0, 1:length(RING));
        if any(isnan(chromOpt) | isinf(chromOpt))
        error('Chromaticity calculation returned NaN or Inf.');
        end
    catch ME
    warning('Failed to calculate chromaticity: %s', ME.message);
    chromOpt = [0, 0];  % Default to zero to avoid crashing
    end
    chromx = chromOpt(1);
    chromy = chromOpt(2);
    J1 = chromx^2 + chromy^2;  % Objective 1: Minimize chromaticity

    % Calculate Dynamic Aperture
    [~, RMAXs, thetas] = SCdynamicAperture(RING, 0,...
                'nturns', 500, ...
                'thetas', linspace(0, 2*pi, 18), ...
                'accuracy', 1e-5, 'launchOnOrbit',1, 'useOrbit6',1);
    
    % Check dimensions before calculating DA
    if length(RMAXs) == length(thetas)
        DA = polyarea(cos(thetas)'.*RMAXs, sin(thetas)'.*RMAXs);
    else
        warning('Mismatched dimensions for Dynamic Aperture calculation');
        DA = 0;
    end
    J2 = -DA;  % Objective 2: Maximize dynamic aperture

    % Return objective vector
    F = [J1, J2];
end
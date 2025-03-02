% Objective Function - Should be at the end of the script or in a separate file
function err = chromaticityObjective(K2, RING, targetChromX, targetChromY, SF_idx, SD_idx)
    % Update sextupole strengths
    RING = setcellstruct(RING, 'PolynomB', SF_idx, K2(1), 3);
    RING = setcellstruct(RING, 'PolynomB', SD_idx, K2(2), 3);
    
    % Calculate chromaticity
    [~, ~, chrom] = atlinopt(RING, 0, 1:length(RING));
    
    % Error: Difference from target chromaticities
    err = sum((chrom - [targetChromX, targetChromY]).^2);
end
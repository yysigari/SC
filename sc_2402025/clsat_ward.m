% function clsat
% ----------------------------------------------------------------------------------------------
% $Header: MatlabApplications/acceleratorcontrol/cls/clsat.m 1.8 2010/04/25 12:45:18GMT-06:00 Ward Wurtz (wurtzw) Exp  $
% ----------------------------------------------------------------------------------------------
% Canadian Light Source
% modified November 2007 to include chicanes and skew quads
% ----------------------------------------------------------------------------------------------
global FAMLIST THERING GLOBVAL
GLOBVAL.E0 = 2.9e9;
GLOBVAL.LatticeFile = 'clsat';
FAMLIST = cell(0);
disp(['   Loading CLS magnet lattice ', mfilename]);
HarmNumber = 285;
AP    = aperture('AP',  [-0.1, 0.1, -0.1, 0.1], 'AperturePass');
L0    = 170.8800;
C0    = 299792458; 
CAV	  = rfcavity('RF', 0, 2.4e+6, HarmNumber*C0/L0, HarmNumber, 'CavityPass');  
COR   = corrector('COR',0.15,[0 0],'CorrectorPass');  
BPM   = marker('BPM', 'IdentityPass');
D1    = drift('D1' , 0.25,  'DriftPass');
D1L   = drift('D1L', 2.25, 'DriftPass');
D1b   = drift('D1b', 0.357, 'DriftPass');
D1bua = drift('D1bua', 0.291, 'DriftPass');
D1bub = drift('D1bub', 0.066, 'DriftPass');
D1bda = drift('D1bda', 0.070, 'DriftPass');
D1bdb = drift('D1bdb', 0.287, 'DriftPass');
D2    = drift('D2', 0.534, 'DriftPass');
D3    = drift('D3', 0.312, 'DriftPass');
D4u   = drift('D4', 0.3905, 'DriftPass'); 
D4d   = drift('D4', 0.0375, 'DriftPass');
D5    = drift('D5', 0.3335,'DriftPass');
D6    = drift('D6', 0.1695,'DriftPass');
D7    = drift('D7', 0.4185,'DriftPass');
D8u   = drift('D8', 0.113, 'DriftPass');
D8d   = drift('D8', 0.23, 'DriftPass');
D9    = drift('D9', 0.264, 'DriftPass');
D10   = drift('D10', 0.12, 'DriftPass');
D11   = drift('D11', 0.135, 'DriftPass');
D12   = drift('D12', 0.249, 'DriftPass');
BND	  =	rbend('BND', 1.87, 0.2617994, 0.105, 0.105, -0.3972, 'BndMPoleSymplectic4RadPass');
QFA   = quadrupole('QFA', 0.18, 1.67900, 'StrMPoleSymplectic4RadPass');
QFB   = quadrupole('QFB', 0.18, 1.88264, 'StrMPoleSymplectic4RadPass');
QFC   = quadrupole('QFC', 0.26, 2.04000, 'StrMPoleSymplectic4RadPass');
SF    = sextupole('SF', 0.192, -24.793, 'StrMPoleSymplectic4RadPass');
SD    = sextupole('SD', 0.0, 42.9572, 'StrMPoleSymplectic4RadPass');
SQA   = quadrupole('SQA', 0.0, 0.0, 'StrMPoleSymplectic4RadPass');
SQB   = quadrupole('SQB', 0.0, 0.0, 'StrMPoleSymplectic4RadPass');
settilt(SQA, 1.5708);
settilt(SQB, 1.5708);

% chicane magnet placement and drifts not exact
CHIC  = corrector('CHC',0.10,[0 0],'CorrectorPass');  
D3MC  = drift('D3MC', 2.389, 'DriftPass');
D5MCS = drift('D5MCS', 0.5, 'DriftPass'); 
D5MCL = drift('D5MCL', 1.789, 'DriftPass');

STRA = [D1L,D1bua,D1bdb,D1L];
STCH3 = [CHIC,D3MC,CHIC,D3MC,CHIC];
STCH5 = [CHIC,D5MCS,CHIC,D5MCL,CHIC,D5MCL,CHIC,D5MCS,CHIC];
HCELL =	[BPM,D1bub,QFA,D9,COR,D10,QFB,D3,BND,D4u,BPM,D4d,SD,SQA,COR,D5,QFC,D6,SF,SQB];
HCELR =	[D6,QFC,D7,COR,SQA,SD,D8u,BPM,D8d,BND,D3,QFB,D11,COR,D12,QFA,D1bda,BPM];
%HCELR_XSR =	[D6 QFC D7 SD CORSD SD D8A BPM D8B BEND1 BEND2 XSR BEND3 BEND4 D3 QFB D9A COR D9B QFA D10A BPM D10B ones(1,9)*D1];
%HCELR_BXDS =[D6 QFC D7 SD CORSD SD D8A BPM D8B BEND1 BEND2 XSR BEND3 BEND4 D3 QFB D9A COR D9B QFA D10A BPM D10B ones(1,9)*D1 BXDS];

SECT  = [STRA,HCELL,HCELR];
SECH3 = [STCH3,HCELL,HCELR];
SECH5 = [STCH5,HCELL,HCELR];
SECAV = [D1L,D1bua,CAV,D1bdb,D1L,HCELL,HCELR];
ELIST = [SECT,SECT,SECT,SECT,SECT,SECT,SECT,SECH3,SECT,SECH5,SECH3,SECAV]; 
buildlat(ELIST);
evalin('base', 'global THERING FAMLIST GLOBVAL');
disp('   Finished loading lattice in Accelerator Toolbox');

% ----------------------------------------------------------------------------------------------
% $Log: MatlabApplications/acceleratorcontrol/cls/clsat.m  $
% Revision 1.8 2010/04/25 12:45:18GMT-06:00 Ward Wurtz (wurtzw) 
% Split skew quads into two families now that we have two families hooked up.
% Revision 1.7 2007/11/23 15:23:07GMT-06:00 Tasha Summers (summert) 
% Now including skew quads and chicanes
% Revision 1.1.1.2 2007/07/10 12:47:46CST Tasha Summers (summert) 
% 
% Revision 1.5 2007/03/05 18:25:38CST summert 
% 
% Revision 1.4 2007/03/05 18:06:38GMT-06:00 summert 
% 
% ----------------------------------------------------------------------------------------------

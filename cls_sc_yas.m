clear all;
%% 
%addpath('~/modelling/MATLAB/MML-master/applications/loco/');
addpath('sc/sc_code/SC-master/SC-master')
%addpath('~/SC-master');
%% 
clsatrad_yas;
%% 
global plotFunctionFlag
SC = SCinit(THERING);
%% Register lattice in SC
ords = SCgetOrds(SC.RING,'BPM');
SC = SCregisterBPMs(SC,ords,...
    	'CalError',5E-2 * [1 1],... % x and y, relative
	    'Offset',500E-6 * [1 1],... % x and y, [m]
	    'Noise',10E-6 * [1 1],...   % x and y, [m]
	    'NoiseCO',1E-6 * [1 1],...  % x and y, [m]
	    'Roll',1E-3);               % az, [rad]
ords = SCgetOrds(SC.RING,'QFA');
SC = SCregisterMagnets(SC,ords,...
	'HCM',1E-3,...                      % [rad]
	'CalErrorB',[5E-2 1E-3],...         % relative
	'MagnetOffset',200E-6 * [1 1 0],... % x, y and z, [m]
	'MagnetRoll',200E-6* [1 0 0]);      % az, ax and ay, [rad]
%% 
ords = SCgetOrds(SC.RING,'QFB');
SC2 = SCregisterMagnets(SC,ords,...
	'HCM',1E-3,...                      % [rad]
	'CalErrorB',[1E-2 -1E-3],...         % relative
	'MagnetOffset',20E-6 * [1 1 0],... % x, y and z, [m]
	'MagnetRoll',20E-6* [1 0 0]);      % az, ax and ay, [rad]
%% 
ords = SCgetOrds(SC2.RING,'QFC');
SC3 = SCregisterMagnets(SC2,ords,...
	'VCM',1E-3,...                      % [rad]
	'CalErrorA',[5E-2 0],...            % relative
	'CalErrorB',[0 1E-3],...            % relative
	'MagnetOffset',200E-6 * [1 1 0],... % x, y and z, [m]
	'MagnetRoll',200E-6* [1 0 0]);      % az, ax and ay, [rad]

ords = SCgetOrds(SC.RING,'BEND');
SC3 = SCregisterMagnets(SC3,ords,...
	'BendingAngle',1E-3,...             % relative
	'MagnetOffset',200E-6 * [1 1 0],... % x, y and z, [m]
	'MagnetRoll',200E-6* [1 0 0]);      % az, ax and ay, [rad]
ords = SCgetOrds(SC.RING,'SF|SD');
SC3 = SCregisterMagnets(SC3,ords,...
	'SkewQuad',0.1,...                   % [1/m]
	'CalErrorA',[0 1E-3 0],...           % relative
	'CalErrorB',[0 0 1E-3],...           % relative
	'MagnetOffset',200E-6 * [1 1 0 ],... % x, y and z, [m]
	'MagnetRoll',200E-6* [1 0 0]);       % az, ax and ay, [rad]
%% 

ords = findcells(SC.RING,'Frequency');
SC = SCregisterCAVs(SC,ords,...
	'FrequencyOffset',5E3,... % [Hz]
	'VoltageOffset',5E3,...   % [V]
	'TimeLagOffset',0.5);     % [m]
%% 
ords = [SCgetOrds(SC.RING,'GirderStart');SCgetOrds(SC.RING,'GirderEnd')];
SC = SCregisterSupport(SC,...
	'Girder',ords,...
	'Offset',100E-6 * [1 1 0],... % x, y and z, [m]
	'Roll',200E-6* [1 0 0]);      % az, ax and ay, [rad]
%% 
ords = [SCgetOrds(SC.RING,'SectionStart');SCgetOrds(SC.RING,'SectionEnd')];
SC = SCregisterSupport(SC,...
	'Section',ords,...
	'Offset',100E-6 * [1 1 0]); % x, y and z, [m]
%% 6x6 beam sigma matrix
SC.INJ.beamSize = diag([200E-6, 100E-6, 100E-6, 50E-6, 1E-3, 1E-4].^2);

SC.SIG.randomInjectionZ = [1E-4; 1E-5; 1E-4; 1E-5; 1E-4; 1E-4]; % [m; rad; m; rad; rel.; m]
SC.SIG.staticInjectionZ = [1E-3; 1E-4; 1E-3; 1E-4; 1E-3; 1E-3]; % [m; rad; m; rad; rel.; m]

SC.SIG.Circumference = 2E-4; % relative
SC.BPM.beamLostAt    = 0.6;  % relative

for ord=SCgetOrds(SC.RING,'Drift')
	SC.RING{ord}.EApertures = 13E-3 * [1 1]; % [m]
end

for ord=SCgetOrds(SC.RING,'QFA|QFB|QFC|BEND|SF|SD')
	SC.RING{ord}.EApertures = 10E-3 * [1 1]; % [m]
end

SC.RING{SC.ORD.Magnet(50)}.EApertures = [6E-3 3E-3]; % [m]
%% Check registration
SCsanityCheck(SC);

SCplotLattice(SC,'nSectors',10);
%% Apply errors

SC = SCapplyErrors(SC);
SCplotSupport(SC);
%% Setup correction chain
SC.RING = SCcronoff(SC.RING,'cavityoff');

sextOrds = SCgetOrds(SC.RING,'SF|SD');
SC = SCsetMags2SetPoints(SC,sextOrds,2,3,0,...
	'method','abs');

RM1 = SCgetModelRM(SC,SC.ORD.BPM,SC.ORD.CM,'nTurns',1);
RM2 = SCgetModelRM(SC,SC.ORD.BPM,SC.ORD.CM,'nTurns',2);

Minv1 = SCgetPinv(RM1,'alpha',50);
Minv2 = SCgetPinv(RM2,'alpha',50);
%% turn-by-turn tracking mode

SC.INJ.nParticles = 1;
SC.INJ.nTurns     = 1;
SC.INJ.nShots     = 1;
SC.INJ.trackMode  = 'TBT';

eps   = 1E-4; % Noise level
plotFunctionFlag = 0;

SCgetBPMreading(SC);

%% Start correction chain
[CUR,ERROR] = SCfeedbackFirstTurn(SC,Minv1,'verbose',1);
if ~ERROR; SC=CUR; else; return; end

SC.INJ.nTurns = 2;

[CUR,ERROR] = SCfeedbackStitch(SC,Minv2,...
	'nBPMs',3,...
	'maxsteps',20,...
	'verbose',1);
if ~ERROR; SC=CUR; else; return; end

[CUR,ERROR] = SCfeedbackRun(SC,Minv2,...
	'target',300E-6,...
	'maxsteps',30,...
	'eps',eps,...
	'verbose',1);
if ~ERROR; SC=CUR; else; return; end

[CUR,ERROR] = SCfeedbackBalance(SC,Minv2,...
	'maxsteps',32,...
	'eps',eps,...
	'verbose',1);
if ~ERROR; SC=CUR; else; return; end
%
for S = linspace(0.1,1,5)

	SC = SCsetMags2SetPoints(SC,sextOrds,2,3,S,...
		'method','rel');

	[CUR,ERROR] = SCfeedbackBalance(SC,Minv2,...
		'maxsteps',10,...
		'eps',eps,...
		'verbose',1);

	if ~ERROR; SC=CUR; end
end

plotFunctionFlag = 0;

SC.RING = SCcronoff(SC.RING,'cavityon');

SCplotPhaseSpace(SC,...
	'nParticles',10,...
	'nTurns',100);
%% rf phase and frequency correction in a loop 
for nIter=1:2
	% Perform RF phase correction.
	[deltaPhi,ERROR] = SCsynchPhaseCorrection(SC,...
		'nTurns',5,...      % Number of turns
		'nSteps',25,...     % Number of phase steps
		'plotResults',1,... % Final results are plotted
		'verbose',1);       % Print results
	if ERROR; error('Phase correction crashed');end

	% Apply phase correction
	SC = SCsetCavs2SetPoints(SC,SC.ORD.Cavity,...
			'TimeLag',deltaPhi,...
			'add');

	% Perform RF frequency correction.
	[deltaF,ERROR] = SCsynchEnergyCorrection(SC,...
		'range',40E3*[-1 1],... % Frequency range [kHz]
		'nTurns',20,...         % Number of turns
		'nSteps',15,...         % Number of frequency steps
		'plotResults',1,...     % Final results are plotted
		'verbose',1);           % Print results

	% Apply frequency correction
	if ~ERROR; SC = SCsetCavs2SetPoints(SC,SC.ORD.Cavity,...
			'Frequency',deltaF,...
			'add');
	else; return; end
end
%% Plot final phase space and check if beam capture is achieved.
SCplotPhaseSpace(SC,'nParticles',10,'nTurns',1000);

[maxTurns,lostCount,ERROR] = SCgetBeamTransmission(SC,...
	'nParticles',100,...
	'nTurns',10,...
	'verbose',true);
if ERROR;return;end
SC.INJ.trackMode = 'ORB';

MCO = SCgetModelRM(SC,SC.ORD.BPM,SC.ORD.CM,'trackMode','ORB');
eta = SCgetModelDispersion(SC,SC.ORD.BPM,SC.ORD.Cavity);

quadOrds = repmat(SCgetOrds(SC.RING,'QFA|QFB|QFC'),2,1);
BPMords  = repmat(SC.ORD.BPM,2,1);
SC       = SCpseudoBBA(SC,BPMords,quadOrds,50E-6);


for	alpha = 10:-1:1
	% Get pseudo inverse
	MinvCO = SCgetPinv([MCO 1E8*eta],'alpha',alpha);

	% Run feedback
	[CUR,ERROR] = SCfeedbackRun(SC,MinvCO,...
		'target',0,...
		'maxsteps',50,...
		'scaleDisp',1E8,...
		'verbose',1);
	if ERROR;break;end

	% Calculate intial and final rms BPM reading.
	B0rms = sqrt(mean(SCgetBPMreading(SC ).^2,2));
	Brms  = sqrt(mean(SCgetBPMreading(CUR).^2,2));

	% Break if orbit feedback did not result in a smaller rms BPM reading
	if mean(B0rms)<mean(Brms);break;end

	% Accept new machine
	SC = CUR;
end
%% 

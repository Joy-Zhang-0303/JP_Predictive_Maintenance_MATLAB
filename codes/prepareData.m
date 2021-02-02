% Copyright 2016 The MathWorks, Inc.
% ���LURL�Ō��J����Ă���f�[�^���_�E�����[�h���A
% Data Set FD001���G���W������csv�t�@�C���Ƃ��ĕ������Ďg�p���܂��B
% https://ti.arc.nasa.gov/tech/dash/groups/pcoe/prognostic-data-repository/
%
%  Data Set: FD001
% * Train trjectories: 100
% * Conditions: ONE (Sea Level)
% * Fault Modes: ONE (HPC Degradation)
%
% References:
% * A. Saxena, K. Goebel, D. Simon, and N. Eklund, Damage Propagation Modeling for Aircraft Engine Run-to-Failure Simulation 
% in the Proceedings of the 1st International Conference on Prognostics and Health Management (PHM08), Denver CO, Oct 2008.


% ����g�p����f�[�^�t�@�C��(CMAPSSData.zip)�����LURL����_�E�����[�h���A
% OriginalDataSet�t�H���_�ɓW�J���܂��B
% "Save As..." �_�C�A���O�������オ��܂��̂ŁA
% ".\originalDataSet" �� CMAPSSData.zip ��ۑ����Ă��������B
originalFile = 'originalDataSet\CMAPSSData.zip';
dataDir = 'originalDataSet';
if ~exist(dataDir,'dir')
    mkdir(dataDir);
end
if ~exist(originalFile, 'file') % download only once
    web('http://ti.arc.nasa.gov/c/6')
    disp('Downloading 12MB data set... this might take a while');
    fprintf(['\nDownload of the original dataset in progress...\n',...
        'Please allow the download of the .zip file to complete before proceeding.\n\n',...
        'Press a key when done.\n'])
    winopen(dataDir);
    pause
end

% ��L�X�e�b�v������ɋ@�\���Ȃ��ꍇ�� Web�u���E�U ���璼��
% http://ti.arc.nasa.gov/c/6
% �ɃA�N�Z�X���ACMAPSSData.zip ���_�E�����[�h�ł��܂��B
% �{�X�N���v�g (prepareData.m) �����݂���t�H���_����
% originalDataSet �Ƃ������O�̃t�H���_���쐬���A���̒��� CMAPSSData.zip ��ۑ����Ă��������B

% ���̌㉺�L�����s���Ă��������B
unzip(originalFile, dataDir);
disp(['Data is unziped to the directory ', dataDir, '.']);

%% train_FD001.txt�̃f�[�^���A�G���W�����Ƃɕ������܂��B
outputFolder = 'originalDataSet';
File = fullfile(outputFolder,'train_FD001.txt');
data = dlmread(File);

% �ϐ����쐬 
varNames = {'Unit', 'Time', 'Setting1', 'Setting2', 'Setting3', 'FanInletTemp',...
    'LPCOutletTemp', 'HPCOutletTemp', 'LPTOutletTemp', 'FanInletPres', ...
    'BypassDuctPres', 'TotalHPCOutletPres', 'PhysFanSpeed', 'PhysCoreSpeed', ...
    'EnginePresRatio', 'StaticHPCOutletPres', 'FuelFlowRatio', 'CorrFanSpeed', ...
    'CorrCoreSpeed', 'BypassRatio', 'BurnerFuelAirRatio', 'BleedEnthalpy', ...
    'DemandFanSpeed', 'DemandCorrFanSpeed', 'HPTCoolantBleed', 'LPTCoolantBleed'};
dataSet = array2table(data,'VariableNames',varNames);

if ~exist('Data', 'dir') 
    disp('Created a new folder "Data"');
    mkdir('Data');
end

% �G���W���̐������Acsv �ւ̏o�͂��J��Ԃ��܂��B
NofEngine = length(unique(dataSet.Unit));
for ii = 1:NofEngine
    idx = dataSet.Unit == ii;
    filename = ['Data\train_FD001_Unit_', num2str(ii), '.csv'];
    writetable(dataSet(idx,:),filename);
end

%% �f���̌㔼�œǂݍ��� mat �t�@�C���̏���
% �iUnsupervisedLive_JP.mlx ���œK������m�C�Y�����̏������s�j
tmp = dataSet;
dataSet = [];
for ii = 1:NofEngine
    tempData = tmp(tmp.Unit == ii,:);
    tempData{:,3:end} = movmean(tempData{:,3:end}, 5);
    dataSet = [dataSet;tempData(5:end,:)]; %#ok<AGROW>
end

% �̏�܂Ŏc���ꂽ�t���C�g��
% splitapply �� �eUnit�̂��ꂼ��̃f�[�^�ɑ΂��� subtractMax �֐���K�p���܂��B
TimeToFail = splitapply(@(x) {subtractMax(x)},dataSet.Time,dataSet.Unit);
dataSet.TimeToFail = cat(1,TimeToFail{:});

% ��L�Q�s�Ɠ��������� for ���[�v���g�p�������L�Ɠ��������ł��B
% dataSet.TimeToFail = zeros(height(dataSet),1);�@
% FailedTime = splitapply(@max,dataSet.Time,dataSet.Unit); % �e�G���W���̌̏᎞�_�̃t���C�g��
% for ii = 1:NofEngine
%     idx = dataSet.Unit == ii;
%     dataSet.TimeToFail(idx) = dataSet.Time(idx) - FailedTime(ii); 
% end

% �����Ɏg�p����ϐ������� fullDataset.mat �ɕۑ�
variableNames = {'Unit' 'Time' 'LPCOutletTemp' 'HPCOutletTemp', 'LPTOutletTemp' 'TotalHPCOutletPres' 'PhysFanSpeed' ...
    'PhysCoreSpeed' 'StaticHPCOutletPres' 'FuelFlowRatio', 'CorrFanSpeed' 'CorrCoreSpeed' 'BypassRatio'...
    'BleedEnthalpy' 'HPTCoolantBleed' 'LPTCoolantBleed','TimeToFail'};
fullDataset = dataSet(:,variableNames);
save('fullDataset.mat','fullDataset')

disp('Data Set for case 1 (UnsupervisedLive_JP.mlx) demo is ready.');

%% ClassificationLive_JP.mlx �p�̃f�[�^��p�ӂ��܂��B
% ������ł� Time ���̏�܂łɎc���ꂽ�t���C�g�� TimeToFail �Œu�������܂��B
fullDataset.Time = fullDataset.TimeToFail;
variableNames = {'Unit' 'Time' 'LPCOutletTemp' 'HPCOutletTemp', 'LPTOutletTemp' 'TotalHPCOutletPres' 'PhysFanSpeed' ...
    'PhysCoreSpeed' 'StaticHPCOutletPres' 'FuelFlowRatio', 'CorrFanSpeed' 'CorrCoreSpeed' 'BypassRatio'...
    'BleedEnthalpy' 'HPTCoolantBleed' 'LPTCoolantBleed'};
fullDataset = fullDataset(:,variableNames);
save('classificationData.mat','fullDataset')

disp('Data Set for case 2 (CassificationLive_JP.mlx) demo is ready.');
%%
clear
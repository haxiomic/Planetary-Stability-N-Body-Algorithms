function [] = loadAndPlot()
figure;

txtFiles = dir('*.txt'); 
numfiles = length(txtFiles);

for k = 1:numfiles 
	[path,varname,ext] = fileparts(txtFiles(k).name);
	eval([varname '= importdata(txtFiles(k).name);']);
end

clearvars k txtFiles numfiles varname path ext;

plot3(sun(:,1), sun(:,2), sun(:,3));hold on;
plot3(venus(:,1), venus(:,2), venus(:,3));hold on;
plot3(earth(:,1), earth(:,2), earth(:,3));hold on;
plot3(mars(:,1), mars(:,2), mars(:,3));hold on;
plot3(jupiter(:,1), jupiter(:,2), jupiter(:,3));hold on;
plot3(saturn(:,1), saturn(:,2), saturn(:,3));hold on;
plot3(uranus(:,1), uranus(:,2), uranus(:,3));hold on;
plot3(neptune(:,1), neptune(:,2), neptune(:,3));hold on;
plot3(neighbour(:,1), neighbour(:,2), neighbour(:,3));hold on;

set(gca, 'DataAspectRatio', [1,1,1]);
set(gca, 'PlotBoxAspectRatio', [1,1,1]);
end


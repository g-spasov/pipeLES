%
% Description: compute average of all profiles in current folder extracted using extractProfiles.py
%
% Usage: octave computeAverageProfiles.m
% Output: averageProfile.dat

clear all

files=glob('*.csv');
n=length(files);

for i=1:n
	angle=(i-1)*2*pi/n;
	data=dlmread(['profile' num2str(i) '0.csv'],' ',1,0);
	if(i==1)
		[m,dummy]=size(data);
	end
	x=linspace(min(data(:,12)),max(data(:,12)),m);
	dataInterp(:,:,i)=interp1(data(:,12), data,x);
	Rrr=dataInterp(:,5,i)*cos(angle).^2+dataInterp(:,6,i)*sin(angle).^2-2*dataInterp(:,5,i).*dataInterp(:,6,i)*cos(angle)*sin(angle);
	Rtt=dataInterp(:,5,i)*sin(angle).^2+dataInterp(:,6,i)*cos(angle).^2+2*dataInterp(:,5,i).*dataInterp(:,6,i)*cos(angle)*sin(angle);
	Rxr=dataInterp(:,7,i)*cos(angle)-dataInterp(:,9,i)*sin(angle);
	alldata(:,:,i)=[dataInterp(:,:,i) Rrr Rtt Rxr];
end
meanData=mean(alldata,3);
save averagedProfiles.dat meanData -ascii

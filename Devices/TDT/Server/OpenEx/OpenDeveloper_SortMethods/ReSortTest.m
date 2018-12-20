clear all; close all; clc;

%Setup
%Create ActiveX object and establish a connection to the desired tank/block
TT = actxcontrol('TTank.X',[0 0 1 1]);
TT.ConnectServer('Local','Me');
TT.OpenTank('Z:\\OpenDeveloper_SortMethods\\ReSorter','R');
TT.SelectBlock('Block-1');

%Check sort settings
Map = TT.GetSortChanMap('MySort','Snip');

%Read out spike events
chan=2;
nSpks = TT.ReadEventsV(10000, 'Snip', chan, 0, 0.0, 0.0, 'ALL,IDXPSQ');

%Get TSQ file indicies
IDX = TT.GetEvTsqIdx();

%Detect features for sort code assignment
Data = TT.ParseEvV(0,nSpks);
MaxData = max(Data,[],1);

V1 = max(Data(:,1));
V2 = max(Data(:,2));
Thresh = 0.5*(V1+V2);

%Processing an sort code assignment 1 = > thresh while 2 = < thresh
NewCodes = zeros(1,nSpks);
for i = 1:nSpks
   if MaxData(i) > Thresh
       NewCodes(i) = 1;
   elseif MaxData(i) < Thresh
       NewCodes(i) = 2;
   end
end

%Create new sort code lists
%This loop interleaves the IDX vector matrix with the assigned sort code
%vector matrix so the size of the new vector is twice that of the original.
%This is the necessary form described in the doc for the SaveSortCodes
%method.
SortArray = zeros(1,2*nSpks, 'int32');
for i=1:nSpks
    SortArray(2*i-1) = IDX(i);
    SortArray(2*i) = int32(NewCodes(i));
end

%Write new sort code data to tank
cond = ['Matlab test sort channel ' num2str(chan)];
e = TT.SaveSortCodes('MySort', 'Snip', chan, cond, SortArray);

%Read out sort condition string
condition = TT.GetSortCondition('MySort', 'Snip', chan)

%Cleanup
TT.CloseTank
TT.ReleaseServer;

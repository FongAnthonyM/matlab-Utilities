import time

from win32com.client import *
obj=Dispatch('TDevAcc.X')
obj.ConnectServer('Local')

sz = obj.GetTargetSize('RZ2_1.dBuffer')
last_ind = 0
while 1:
    ind = obj.GetTargetVal('RZ2_1.sBuffer')
    #print(ind)
    if ind != last_ind:
        print(ind)
        
        # catch if buffer looped
        if ind < last_ind:            
            ddd = sz - last_ind + ind
        else:
            ddd = last_ind - ind
        rd = obj.ReadTargetVEX('RZ2_1.dBuffer', last_ind, ddd, 'I32', 'I32')
        print(rd)
        last_ind = ind
    time.sleep(0.1)
    
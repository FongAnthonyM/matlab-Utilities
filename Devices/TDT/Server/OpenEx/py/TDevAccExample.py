from win32com.client import *
obj=Dispatch('TDevAcc.X')
obj.ConnectServer('Local')

#create hoops in OpenController sort window and read locations
rd = obj.ReadTargetVEX('Amp1.cSnip~1', 0, 96, 'F32', 'F32')

#manually move hoops and read new location
rdn = obj.ReadTargetVEX('Amp1.cSnip~1', 0, 96, 'F32', 'F32')

#Move hoops back to original location
obj.WriteTargetVEX('Amp1.cSnip~1',0,'F32',rd)

#Move hoops to new location
obj.WriteTargetVEX('Amp1.cSnip~1',0,'F32',rdn)

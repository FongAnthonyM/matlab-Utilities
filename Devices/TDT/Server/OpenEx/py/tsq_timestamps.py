import struct
import time

import numpy as np

tsq_filename = 'PATH_TO.tsq';

EVMARK_STARTBLOCK = 1;
EVMARK_STOPBLOCK = 2;
    
with open(tsq_filename, 'rb') as tsq:

    # read start time
    tsq.seek(48)
    xxx = tsq.read(4)
    ddd = struct.unpack('i', xxx)
    if ddd[0] == EVMARK_STARTBLOCK:
        tsq.seek(56)
        ttt = struct.unpack('d', tsq.read(8))
        start_time = time.gmtime(np.round(ttt, 0))
        print('start time:', start_time)
    else:
        print('start time not found')

    # read start time
    tsq.seek(-32, 2)
    xxx = tsq.read(4)
    ddd = struct.unpack('i', xxx)
    if ddd[0] == EVMARK_STOPBLOCK:
        tsq.seek(-24, 2)
        ttt = struct.unpack('d', tsq.read(8))
        stop_time = time.gmtime(np.round(ttt, 0))
        print('stop time:', stop_time)
    else:
        print('stop time not found')
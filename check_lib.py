#!/usr/bin/env python2.7

import time
# get time and day
date = time.localtime()
day = (date.tm_mday-6) + 31*(date.tm_mon-10)

# get sessid, normalized to October 5th, 2017
sessid = 1191254462 + day * 86400
print sessid

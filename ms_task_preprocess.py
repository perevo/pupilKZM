#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Oct  8 11:09:10 2023

@author: jialiu
"""

from matplotlib import pyplot as plt
import numpy as np
from EngbertMicrosaccadeToolbox import microsac_detection
import scipy.io as sio 

# Set parameters
SAMPLING = 1000
MINDUR = 6 # 6 samples
VFAC = 5

# load mat file
data =  sio.loadmat('E:\Projects\Toolbox\EngbertMicrosaccadeToolbox-master//zy.mat')
cond1 = data['cond1'] 
cond1[:,[1,2]]=(cond1[:,[1,2]]-512)/31
cond1[:,[3,4]]=(cond1[:,[3,4]]-384)/31
cond2 = data['cond2'] 
cond2[:,[1,2]]=(cond2[:,[1,2]]-512)/31
cond2[:,[3,4]]=(cond2[:,[3,4]]-384)/31


# Run Detection in Trials of each Condition
cond1_list=[]
for trial in range(1,50):
    right_eye = cond1[(trial-1)*1701:trial*1701,[2,4]]
    left_eye = cond1[(trial-1)*1701:trial*1701,[1,3]]
    
    ms_r, rad_r = microsac_detection.microsacc(right_eye)
    ms_l, rad_l = microsac_detection.microsacc(left_eye)
    if ms_r and ms_l:
        bino, monol, monor = microsac_detection.binsacc(ms_r, ms_l)
        if bino:
            bino_data=np.array(bino)
            if len(cond1_list)==0:
                cond1_list=bino_data
            else:
                cond1_list=np.concatenate((cond1_list,bino_data))
            
cond2_list=[]
for trial in range(1,50):
    right_eye = cond2[(trial-1)*1701:trial*1701,[2,4]]
    left_eye = cond2[(trial-1)*1701:trial*1701,[1,3]]
    
    ms_r, rad_r = microsac_detection.microsacc(right_eye)
    ms_l, rad_l = microsac_detection.microsacc(left_eye)
    if ms_r and ms_l:
        bino, monol, monor = microsac_detection.binsacc(ms_r, ms_l)
        if bino:
            bino_data=np.array(bino)
            if len(cond2_list)==0:
                cond2_list=bino_data
            else:
                cond2_list=np.concatenate((cond2_list,bino_data))
    

 

# MS count
t=np.arange(-500,1201,1)
ms_c1=np.zeros((1701,1));
ms_c2=np.zeros((1701,1));


for i in range(50,1651): # window = 100
    ms_c1[i]=np.sum((cond1_list[:,0]>i-50) * (cond1_list[:,0]<=i+50))*10/50; # divided the number of trials
    ms_c2[i]=np.sum((cond2_list[:,0]>i-50) * (cond2_list[:,0]<=i+50))*10/50;

 
# plot
plt.plot(t,ms_c1)
plt.plot(t,ms_c2)


sio.savemat('E:\Projects\Toolbox\EngbertMicrosaccadeToolbox-master//zy__ms.mat',{'r1':ms_c1,'r2':ms_c2,'t':t})





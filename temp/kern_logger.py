import random
import time

exmpl = '<4>%s node-164 kernel: [767975.369264] XFS (%s): xfs_log_force: error 5 returned.\n'

print time.strftime("%b %d %H:%M:%S", time.gmtime())

devices = ['sdd1', 'sda', 'sdd3', 'sdx8', 'vdh', 'sdg4', 'sda3', 'sdb', 'sdd9', 'sdf2']

s = 0
for i in range(1000):
    with open("/home/isvetlov/heka_test/hdd/kern.log", 'a') as f:
        f.write(exmpl % (time.strftime("%b %d %H:%M:%S", time.gmtime()), random.choice(devices)))
    time.sleep(0.05)
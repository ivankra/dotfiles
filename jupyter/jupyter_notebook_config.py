import os, re

s = os.path.join(os.environ['HOME'], '.jupyter/token')
if os.path.exists(s):
  s = open(s, 'r').readline().strip()
  c.NotebookApp.token = s
  c.LabApp.token = s

if os.path.exists('/proc/self/cgroup') and '/docker' in open('/proc/self/cgroup', 'r').read():
  c.NotebookApp.allow_root = True
  c.NotebookApp.open_browser = False
  #c.NotebookApp.ip = '0.0.0.0'

c.NotebookApp.iopub_data_rate_limit = 1000000000

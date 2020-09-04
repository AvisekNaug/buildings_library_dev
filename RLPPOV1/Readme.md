## Example python instructions to run RLPPOV1 folders

Get the docker from [JModelica_docker](https://github.com/AvisekNaug/JModelica_docker)

* Run the docker (make sure you export this library from host machine to the docker and add its path in the docker to MODELICAPATH)
* Compile into an fmu

```bash
export MODELICAPATH=<path to this library on docker>$MODELICAPATH
mkdir testbed
cd testbed
ipython
```

```python
from pymodelica import compile_fmu
import pymodelica
# Increase memory in case compilation fails
pymodelica.environ['JVM_ARGS'] = '-Xmx4096m'

model_name = 'Buildings.Examples.VAVReheat.RLPPOV1'
fmu_path = compile_fmu(model_name, target='cs')


quit()
```

```bash
conda activate modelicagym
ipython
```

```python
import matplotlib.pylab as plt
from pyfmi import load_fmu


fmu_path = 'Buildings_Examples_VAVReheat_RLPPOV1.fmu'
fmu = load_fmu(fmu_path)
model_input_names = ['TSupSetHea']
model_output_names = ['rl_oat','rl_ret','rl_TSupEas','rl_sat']

# Step 1 of the simulation
model_input_value = [285]  # Heating Set Point
fmu.set(list(model_input_names),list(model_input_value))
result = fmu.simulate(start_time=0.0,final_time=57600.0)
res_log = tuple([result.final(k) for k in model_output_names]) # only final value
res_log1 = {'rl_sat':result['rl_sat'],'rl_oat':result['rl_oat'],'rl_ret':result['rl_ret'],'rl_TSupEas':result['rl_TSupEas'],'rl_EHea':result['res.EHea'],'time':result['time']}

# Step 2 of the simulation

model_input_value = [279]  # changing the heating set point for new gym step method of the Heating Set Point
fmu.set(list(model_input_names),list(model_input_value))
opts = fmu.simulate_options()
opts['initialize'] = False
result = fmu.simulate(start_time=57600.0,final_time=115200.0,options=opts)
res_log = tuple([result.final(k) for k in model_output_names]) # only final value
res_log2 = {'rl_sat':result['rl_sat'],'rl_oat':result['rl_oat'],'rl_ret':result['rl_ret'],'rl_TSupEas':result['rl_TSupEas'],'rl_EHea':result['res.EHea'],'time':result['time']}
```

Plot with time
```python
import matplotlib.pylab as plt
from pyfmi import load_fmu
from datetime import datetime, timedelta
from matplotlib.dates import DateFormatter, date2num

formatter = DateFormatter('%B-%d %I:%M:%S %p')
start_time = datetime(2019,1,1)
time_idx = [start_time + timedelta(seconds=i)  for i in res_log1['time']]
time_idx = date2num(time_idx)


fig, ax = plt.subplots()
plt.plot_date(time_idx, res_log1['rl_oat'])
plt.plot_date(time_idx, res_log1['rl_ret'])
plt.plot_date(time_idx, res_log1['rl_TSupEas'])
plt.plot_date(time_idx, res_log1['rl_sat'])
plt.legend(('Ambient T','Return air T','East Zone T','AHU Supply Air T'))

ax.set_xlabel('Time')
ax.set_ylabel('Example Measured Temperature Variables in Kelvin')
ax.xaxis.set_major_formatter(formatter)
ax.xaxis.set_tick_params(rotation=30, labelsize=10)

plt.savefig('demo_plot.png',bbox_inches='tight')
plt.savefig('demo_plot1.pdf',bbox_inches='tight')
```
Cisualize the pdfs locally or on remote machine whichever you are working with.
Then,
```bash
 mv demo_plot.png /home/developer/buildings_library_dev/RLPPOV1
 mv demo_plot1.pdf /home/developer/buildings_library_dev/RLPPOV1
```

## What we have to understand next
* How the rooms switch between different heating/cooling during on/off phase? Otherwise we see behaviors we don't understand.
* How fast is the system able to achieve the set point and its effects are seen in the building?
* Why are there only 1000 points in the plot?
* Is the operation mode also present in the G36 as in ASHRAE20016?

## How to decide configuration for the simulation
* What is the period of simulation between steps?
* Do we need modelica gym at all?
* will simulation be a bottle neck?

### Using step method to do the simulation
```python
from pyfmi import load_fmu
import numpy as np
import time

fmu_path = 'Buildings_Examples_VAVReheat_RLPPOV1.fmu'
fmu = load_fmu(fmu_path)

start_time = 3600*2500
final_time = 3600*3200

model_input_names = ['TSupSetHea']
model_output_names = ['rl_oat', 'rl_sat', 'rl_TSupEas', 'conVAVEas.TRooHeaSet', 'conVAVEas.TRooCooSet', 'res.PHea', 'res.PFan', 'res.PCooSen', 'res.PCooLat']


fmu.reset()
fmu.initialize(start_time=start_time,stop_time=final_time)
step_size = 3600.0

res = {}
store = {}
for i in model_output_names+model_input_names:
    store[i] = []
store['time'] = []

iter = 1
t_step = start_time
while t_step < final_time:
    fmu.set(model_input_names,[np.random.uniform(276,285,1)[0]])
    time_start = time.time()
    res[t_step] = fmu.do_step(current_t=t_step, step_size=step_size, new_step=True)
    time_end = time.time()
    print("Took {:.2f} s to complete the simulation iteration {}".format(time_end-time_start, iter))
    iter += 1
    for i in model_output_names+model_input_names:
        store[i].append(fmu.get(i)[0])
    store['time'].append(fmu.time)
    t_step += step_size

# plot with time

import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from matplotlib.dates import DateFormatter, date2num

plt.rcParams["figure.figsize"]=15,7

alias_dict = {'rl_oat':'Ambient T','rl_ret':'Return air T', 'TSupSetHea':'AHU Heating Coil Set Point',\
'rl_TSupEas':'East Zone T','rl_sat':'AHU Supply Air T', 'res.PHea' : 'Heating Power', 'conVAVEas.TRooHeaSet':'Setpoint temperature for room for heating', 'conVAVEas.TRooCooSet': 'Setpoint temperature for room for cooling', 'res.PFan':'Fan Power', 'res.PCooSen':'Sesible Cooling Power', 'res.PCooLat':'Latent Cooling Power'}

model_input_names = ['TSupSetHea']
model_output_names = ['rl_oat', 'rl_sat', 'rl_TSupEas', 'conVAVEas.TRooHeaSet', 'conVAVEas.TRooCooSet', 'res.PHea', 'res.PFan', 'res.PCooSen', 'res.PCooLat']

formatter = DateFormatter('%B-%d %I:%M:%S %p')
start_time = datetime(2019,1,1)
time_idx = [start_time + timedelta(seconds=i)  for i in store['time']]
time_idx = date2num(time_idx)

fig, (ax, ax2, ax3) = plt.subplots(3, sharex=True)

# plot 1
for y_val in model_output_names[:-4]+model_input_names:
    ax.plot_date(time_idx, store[y_val],linestyle='solid', marker='.',label=alias_dict[y_val])
ax.set_ylabel('Kelvin')
ax.grid(True)
ax.minorticks_on()
ax.legend(loc='upper left', bbox_to_anchor=(1.05, 1))

# plot 2
y_val=model_output_names[-4]
ax2.plot_date(time_idx, store[y_val],linestyle='--', marker='.',label=alias_dict[y_val])
ax2.set_ylabel('watt')
ax2.grid(True)
ax2.minorticks_on()
ax2.legend(loc='upper left', bbox_to_anchor=(1.05, 1))

# plot 2
for y_val in model_output_names[-3:]:
    ax3.plot_date(time_idx, store[y_val],linestyle='--', marker='.',label=alias_dict[y_val])
ax3.set_xlabel('Time')
ax3.set_ylabel('watt')
ax3.grid(True)
ax3.minorticks_on()
ax3.xaxis.set_major_formatter(formatter)
ax3.xaxis.set_tick_params(rotation=10, labelsize=6)
ax3.legend(loc='upper left', bbox_to_anchor=(1.05, 1))

plt.tight_layout(rect=[0,0,0.90,1])

plt.show()

plt.clf()

plt.savefig('demo_plot.png',bbox_inches='tight')
plt.savefig('demo_plot1.pdf',bbox_inches='tight')
```


```python
import pickle
with open('store.pickle', 'rb') as handle:
    store = pickle.load(handle)

```

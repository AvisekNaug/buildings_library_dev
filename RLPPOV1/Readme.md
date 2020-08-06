## Example python instructions to run RLPPOV1

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
model_name = 'Buildings.Examples.VAVReheat.RLPPOV1'
fmu_path = compile_fmu(model_name, target='cs')

# Increase memory in case compilation fails
pymodelica.environ['JVM_ARGS'] = '-Xmx4096m'
quit()
```

```bash
conda activate modelicagym
ipython
```

```python

# Step 1 of the simulation
import matplotlib.pylab as plt
from pyfmi import load_fmu


fmu_path = 'Buildings_Examples_VAVReheat_RLPPOV1.fmu'
fmu_model = load_fmu(fmu_path)
model_input_names = ['TSupSetHea']
model_output_names = ['rl_oat','rl_ret','rl_TSupEas','rl_sat']
model_input_value = [285]  # Heating Set Point
fmu_model.set(list(model_input_names),list(model_input_value))
result = fmu_model.simulate(start_time=0.0,final_time=57600.0)
res_log = tuple([result.final(k) for k in model_output_names])
res_log1 = {'rl_sat':result['rl_sat'],'rl_oat':result['rl_oat'],'rl_ret':result['rl_ret'],'rl_TSupEas':result['rl_TSupEas'],'rl_EHea':result['res.EHea']}

plt.plot(res_log1['rl_oat'])
plt.plot(res_log1['rl_ret'])
plt.plot(res_log1['rl_TSupEas'])
plt.plot(res_log1['rl_sat'])
plt.legend(('rl_oat','rl_ret','rl_TSupEas','rl_sat'))
plt.show()
plt.savefig('testbed1.pdf',bbox_inches='tight')
plt.clf()

# Step 2 of the simulation

model_input_value = [279]  # changing the heating set point for new gym step method of the Heating Set Point
fmu_model.set(list(model_input_names),list(model_input_value))
opts = fmu_model.simulate_options()
opts['initialize'] = False
result = fmu_model.simulate(start_time=57600.0,final_time=115200.0,options=opts)
res_log = tuple([result.final(k) for k in model_output_names])
res_log2 = {'rl_sat':result['rl_sat'],'rl_oat':result['rl_oat'],'rl_ret':result['rl_ret'],'rl_TSupEas':result['rl_TSupEas'],'rl_EHea':result['res.EHea']}

plt.plot(res_log2['rl_oat'])
plt.plot(res_log2['rl_ret'])
plt.plot(res_log2['rl_TSupEas'])
plt.plot(res_log2['rl_sat'])
plt.legend(('rl_oat','rl_ret','rl_TSupEas','rl_sat'))
plt.show()
plt.savefig('testbed2.pdf',bbox_inches='tight')
plt.clf()
```

```bash
mv testbed1.pdf <path to buildings library on docker>
mv testbed2.pdf <path to buildings library on docker>
```
visualize the pdfs locally or on remote machine whichever you are working with. They will be located inside the buildings library folder.

Alternative plotting
```python
import matplotlib.pylab as plt
plt.figure(figsize=(15,10))
import numpy as np
arr1 = np.concatenate((res_log1['rl_sat'],res_log2['rl_sat']))
arr2 = np.concatenate((res_log1['rl_ret'],res_log2['rl_ret']))
arr3 = np.concatenate((res_log1['rl_TSupEas'],res_log2['rl_TSupEas']))
arr4 = np.concatenate((res_log1['rl_oat'],res_log2['rl_oat']))
arr5 = np.concatenate((res_log1['rl_EHea'],res_log2['rl_EHea']))
plt.plot(arr1,'r*-')
plt.plot(arr2,'k4-')
plt.plot(arr3,'b.-')
plt.plot(arr4,'go-')
plt.plot(arr5,'co-')
plt.legend(('rl_sat', 'rl_ret', 'rl_TSupEas', 'oat','Heating Energy(J/m2)'))
plt.savefig('testbed7.pdf',bbox_inches='tight')
plt.clf()
```

Plot with time
```python
import matplotlib.pylab as plt
from pyfmi import load_fmu
from datetime import datetime, timedelta
from matplotlib.dates import DateFormatter, date2num

formatter = DateFormatter('%B-%d %I:%M:%S %p')
start_time = datetime(2019,1,1)
time_idx = [start_time + timedelta(seconds=i)  for i in res_log['time']]
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
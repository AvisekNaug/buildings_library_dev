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

from pyfmi import load_fmu
fmu_path = 'Buildings_Examples_VAVReheat_RLPPOV1.fmu'
fmu_model = load_fmu(fmu_path)
model_input_names = ['TSupSetHea']
model_output_names = ['rl_oat','rl_ret','rl_TSupEas','rl_sat']
model_input_value = [298]  # Heating Set Point
fmu_model.set(list(model_input_names),list(model_input_value))
result = fmu_model.simulate(start_time=0.0,final_time=14400.0)
res_log = tuple([result.final(k) for k in model_output_names])

import matplotlib.pylab as plt
res_log1 = {'rl_sat':result['rl_sat'],'rl_oat':result['rl_oat'],'rl_ret':result['rl_ret'],'rl_TSupEas':result['rl_TSupEas']}

plt.plot(res_log1['rl_oat'])
plt.plot(res_log1['rl_ret'])
plt.plot(res_log1['rl_TSupEas'])
plt.plot(res_log1['rl_sat'])
plt.legend(('rl_oat','rl_ret','rl_TSupEas','rl_sat'))
plt.show()
plt.savefig('testbed1.pdf',bbox_inches='tight')
plt.clf()

# Step 2 of the simulation

model_input_value = [283]  # changing the heating set point for new gym step method of the Heating Set Point
fmu_model.set(list(model_input_names),list(model_input_value))
opts = fmu_model.simulate_options()
opts['ncp'] = 50
opts['initialize'] = False
result = fmu_model.simulate(start_time=14400.0,final_time=28800.0,options=opts)
res_log = tuple([result.final(k) for k in model_output_names])

import matplotlib.pylab as plt
res_log2 = {'rl_sat':result['rl_sat'],'rl_oat':result['rl_oat'],'rl_ret':result['rl_ret'],'rl_TSupEas':result['rl_TSupEas']}

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
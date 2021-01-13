---
jupyter:
  jupytext:
    formats: ipynb,md
    notebook_metadata_filter: blog
    text_representation:
      extension: .md
      format_name: markdown
      format_version: '1.2'
      jupytext_version: 1.9.1
  kernelspec:
    display_name: Python 3
    language: python
    name: python3
---

Some text

```python
import random
import numpy
import seaborn

K_ARMS = 10
TIME_STEPS = 20
EPSILON = 0.1

# Initialise q*(a)
true_action_values = numpy.random.normal(size=K_ARMS)
action_values = numpy.zeros(K_ARMS)
action_counts = numpy.zeros(K_ARMS)


reward = numpy.zeros(TIME_STEPS)
action_difference = numpy.zeros(TIME_STEPS)

for t in range(0, TIME_STEPS):
    
    if numpy.random.uniform() > EPSILON:
        epsilon_select = False
        selected_action_idx = numpy.argmax(action_values)
    else:
        epsilon_select = True
        selected_action_idx = random.randrange(K_ARMS)
    
    # Select reward
    reward[t] = numpy.random.normal(true_action_values[selected_action_idx])
    
    # Update action counts
    action_counts[selected_action_idx] += 1
    
    # Update the action values
    change_in_action_value = (reward[t] - action_values[selected_action_idx]) / action_counts[selected_action_idx]
    action_values[selected_action_idx] += change_in_action_value
    
    # Calculate difference in action values over time
    action_difference[t] = sum(true_action_values - action_values)
    
    print(f"Time: {t} Action: {selected_action_idx} Random: {epsilon_select}")




seaborn.lineplot(y=numpy.cumsum(action_difference), x=range(0, TIME_STEPS))
```

# Locust

Simulates user load. It has the option to run a distributed tests, rather than from a single node.

### Installation

Follow the instructions to install here: https://docs.locust.io/en/stable/installation.html 

### Running a test

To run a test, start locust, using a specified locust file:

```python
locust -f ./path_to_file/my_locust_file.py --host=http://example.com
```

Browse to `http://127.0.0.1:8089` to start a test
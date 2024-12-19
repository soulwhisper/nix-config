from setuptools import setup, find_packages

with open('requirements.txt') as f:
  install_requires = f.read().splitlines()

setup (
  name='sgcc_electricity',
  version='VERSION',
  install_requires=install_requires,
  packages=find_packages(where='scripts'),
  package_dir={'': 'scripts'},
  include_package_data=True,
  package_data={'': ['captcha.onnx'],},
)

# Windows setup

## Running shell scripts in Intellij

There's a python script for running shell commands inside the Windows Subsystem for Linux (WSL).  
It's located at `src/python/windows_scripts/sh.py`

You need to modify the windows PYTHONPATH so we can invoke the script from anywhere:

```shell
$ python src/python/windows_scripts/sh.py --sh-help

usage: Run a WSL command from the zsh shell.
To run linux commands directly from windows you need to:
(1) Add PYTHONPATH=C:\Users\<user>\clone\src\python\script
(2) $ python -m windows_scripts.sh echo hi

```

Then in Intellij you can run WSL scripts by doing
`Run` > `Edit Configurations...` -> `Before launch: +` -> `Run External Tool` -> `+` 

And in the "Program:" field put: 
```shell
python -m windows_scripts.sh echo hi
```
    
    

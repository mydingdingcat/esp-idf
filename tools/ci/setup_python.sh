#!/usr/bin/env bash

# py2_incomp='assign_test|nvs_compatible_test|IT'
# - auto_test_script do not support python2 anymore
# but there are still some jobs incompatible with Python 3 (eg: example_test)
# keep the default python interpreter as 2.7.15 until all the jobs support python3

# Regexp for matching job names which are incompatible with Python 3
# - UT_009_ - multi-device tests are not compatible
# - UT_017_ - multi-device tests are not compatible
py3_incomp='UT_009_|UT_017_'

if [ -z ${PYTHON_VER+x} ] || [[ $CI_JOB_NAME =~ $py3_incomp ]]; then
    # Use this version of the Python interpreter if it was not defined before or
    # the given job is not compatible with Python 3
    PYTHON_VER=2.7.15
fi

if [ -f /opt/pyenv/activate ];
then
    source /opt/pyenv/activate
    pyenv global $PYTHON_VER || {
                                    echo 'Python' $PYTHON_VER 'is not installed.'
                                    INSTALLED_PY_VERS=$(pyenv versions --bare)

                                    while [ ${#PYTHON_VER} -gt 0 ]
                                    do
                                        echo 'Tring to locate a match for' $PYTHON_VER

                                        for ver in ${INSTALLED_PY_VERS[@]}
                                        do
                                            if [[ $ver == $PYTHON_VER* ]];
                                            then
                                                pyenv global $ver
                                                break 2
                                            fi
                                        done

                                        # Removing last character and trying to find some match.
                                        # For example, if 3.4.8 was selected but isn't installed then it will try to
                                        # find some other installed 3.4.X version, and then some 3.X.X version.
                                        PYTHON_VER=${PYTHON_VER: : -1}
                                    done
                                }
    python --version || {
                            echo 'No matching Python interpreter is found!'
                            exit 1
                        }
elif command -v python -V 1>/dev/null 2>&1;
then
    python --version
    echo 'No /opt/pyenv/activate exists and Python from path is used.'
else
    echo 'No /opt/pyenv/activate exists and no Python interpreter is found!'
    exit 1
fi

# add esp-idf local package path to PYTHONPATH so it can be imported directly
export PYTHONPATH="$IDF_PATH/tools:$IDF_PATH/tools/ci/python_packages:$PYTHONPATH"

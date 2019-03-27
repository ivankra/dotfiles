#!/bin/bash

cat <<EOF
{
  "NotebookApp": {
    "nbserver_extensions": {
      $(python -c 'import jupyter_nbextensions_configurator' >/dev/null 2>&1 &&
        echo '"jupyter_nbextensions_configurator": true')
    }
  }
}
EOF

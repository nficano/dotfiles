#!/bin/sh
#/ NAME
#/      {{ basename }} -- ~60 character imperative summary of the script.
#/ 
#/ SYNOPSIS
#/      {{ basename }} [-h] [--help]
#/      {{ basename }} [operand]
#/      See: https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html
#/ 
#/ DESCRIPTION
#/      The command description is an extended explainer that answers 
#/      "what the command does", "what are the usecases", and "what are the 
#/      "arguments"

set -o errexit          # Exit on most errors (see the manual)
set -o nounset          # Disallow expansion of unset variables
#set -o errtrace        # Make sure any error trap is inherited (BASH only)
#set -o pipefail        # Use last non-zero exit code in a pipeline (BASH only)
#set -o xtrace          # Trace the execution of the script (UNCOMMENT TO DEBUG)

usage () {
    grep '^#/ ' < "$0" | cut -c4- | sed "s/{{ basename }}/${0##*/}/"
    exit 1
}

[ $# -eq 0 ] || [ "$1" = "--help" ] || [ $# -ne 1 ] && usage


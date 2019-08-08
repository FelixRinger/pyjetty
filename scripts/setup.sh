#!/bin/bash

cdir=$(pwd)

function thisdir()
{
	SOURCE="${BASH_SOURCE[0]}"
	while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	  SOURCE="$(readlink "$SOURCE")"
	  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	echo ${DIR}
}
THISD=$(thisdir)
source ${THISD}/util.sh
separator "${BASH_SOURCE}"
build_with_python="python"
[ "x$(get_opt "python2" $@)" == "xyes" ] && build_with_python="python2"
[ "x$(get_opt "python3" $@)" == "xyes" ] && build_with_python="python3"
${THISD}/../scripts/make_module.sh --${build_with_python}
module use ${THISD}/../modules
module avail
separator ''
module load pyjetty/pyjetty_${build_with_python}
[ -e "${THISD}/../.pyjetty_config_external" ] && source ${THISD}/../.pyjetty_config_external
reset=$(get_opt "reset-external" $@)
if [ -z ${PYJETTY_SETUP_EXTERNAL} ] || [ "x${reset}" == "xyes" ]; then
	[ "x${reset}" == "xyes" ] && warning "PYJETTY_SET resetting ... ${reset}"
	if [ -e ${THISD}/../.pyjetty_config_external ]; then
		source ${THISD}/../.pyjetty_config_external
	else
		echo "PYJETTY_SETUP_EXTERNAL=${THISD}/external/setup.sh" | tee ${THISD}/../.pyjetty_config_external
		if [ -e ${THISD}/../.pyjetty_config_external ]; then
			source ${THISD}/../.pyjetty_config_external
		fi
	fi
	[ -e ${PYJETTY_SETUP_EXTERNAL} ] && echo_info "[i] PYJETTY_SETUP_EXTERNAL=${PYJETTY_SETUP_EXTERNAL}" && ${PYJETTY_SETUP_EXTERNAL} $@
else
	module load pyjetty/${build_with_python}/HEPMC2
	module load pyjetty/${build_with_python}/HEPMC3
	module load pyjetty/${build_with_python}/LHAPDF6
	module load pyjetty/${build_with_python}/PYTHIA8
	module load pyjetty/${build_with_python}/FASTJET
fi

redo=$(get_opt "rebuild" $@)
( [ ! -d ${THISD}/../cpptools/lib ] || [ "x${redo}" == "xyes" ] ) && ${THISD}/../cpptools/scripts/build_cpptools.sh $@

${THISD}/make_module.sh --make-main-module

cd ${cpwd}

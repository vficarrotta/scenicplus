# ============================================================
# SCENIC+ install on Easley
# bootstrap module: python/anaconda/3.11.4
# compiler module:  gcc/9.3.0
# env:  /home/vzf0010/apps/conda_envs/scenicplus
# repo: /home/vzf0010/apps/scenicplus
# ============================================================

cd /home/vzf0010/apps

source /etc/profile.d/modules.sh
module purge
module load python/anaconda/3.11.4
module load gcc/9.3.0

export CONDA_NO_PLUGINS=true
export CONDA_PKGS_DIRS=/home/vzf0010/.conda/pkgs
export CONDA_ENVS_DIRS=/home/vzf0010/.conda/envs
export PYTHONNOUSERSITE=1

mkdir -p /home/vzf0010/.conda/pkgs
mkdir -p /home/vzf0010/.conda/envs
mkdir -p /home/vzf0010/apps
mkdir -p /home/vzf0010/apps/conda_envs

# reinitialize conda shell support cleanly
source /tools/anacondapython-3.11.4/etc/profile.d/conda.sh

# quick check
which conda
conda --version

# ------------------------------------------------------------
# cleanup
# ------------------------------------------------------------
rm -rf /home/vzf0010/apps/conda_envs/scenicplus
rm -rf /home/vzf0010/apps/scenicplus

# ------------------------------------------------------------
# create env
# ------------------------------------------------------------
conda --no-plugins create --solver classic -p /home/vzf0010/apps/conda_envs/scenicplus python=3.11.4 -y

# ------------------------------------------------------------
# activate env
# ------------------------------------------------------------
conda activate /home/vzf0010/apps/conda_envs/scenicplus

# make sure env python/bin wins
export PATH="/home/vzf0010/apps/conda_envs/scenicplus/bin:$PATH"
hash -r

echo "CONDA_PREFIX=$CONDA_PREFIX"
echo "PYTHON => $(which python)"
python --version
echo "GCC    => $(which gcc)"
gcc --version

# env may not have pip yet
conda --no-plugins install --solver classic -y -p /home/vzf0010/apps/conda_envs/scenicplus pip
hash -r

echo "PIP => $(which pip)"
python -m pip --version

# keep pip/setuptools conservative for old-package compatibility
python -m pip install --upgrade "pip<26" "setuptools<81" wheel

# ------------------------------------------------------------
# compiled scientific stack
# ------------------------------------------------------------
conda --no-plugins install --solver classic -y -p /home/vzf0010/apps/conda_envs/scenicplus -c conda-forge numpy=1.26 scipy cython libcblas libblas openblas

python - <<'PY'
import numpy as np
print("numpy:", np.__version__)
np.show_config()
PY

# ------------------------------------------------------------
# preinstall bedtools/pybedtools + htslib + pysam via conda
# ------------------------------------------------------------
conda --no-plugins install --solver classic -y -p /home/vzf0010/apps/conda_envs/scenicplus -c conda-forge -c bioconda pybedtools bedtools htslib pysam

python - <<'PY'
import pysam
print("pysam:", pysam.__file__)
print("has CMATCH:", hasattr(pysam, "CMATCH"))
from pysam.libcalignedsegment import *
print("libcalignedsegment import OK")
PY

python - <<'PY'
import pybedtools
print("pybedtools:", pybedtools.__version__)
PY

bedtools --version

# ------------------------------------------------------------
# preinstall MACS2
# ------------------------------------------------------------
python -m pip install "macs2==2.2.9.1"

# ------------------------------------------------------------
# clone scenicplus and use development branch
# ------------------------------------------------------------
cd /home/vzf0010/apps
git clone https://github.com/aertslab/scenicplus.git scenicplus
cd /home/vzf0010/apps/scenicplus
git checkout development

# ------------------------------------------------------------
# remove pybedtools requirement locally
# ------------------------------------------------------------
sed -i '/pybedtools/d' requirements.txt
sed -i '/pybedtools/d' requirements.in

# optional only if pyproject.toml blocks your exact Python patch
# sed -i 's/requires-python = ">=3.8,<=3.11.11"/requires-python = ">=3.8,<=3.11.99"/' pyproject.toml

# ------------------------------------------------------------
# install scenicplus itself, then remaining reqs, without deps
# ------------------------------------------------------------
python -m pip install --no-deps -e .
python -m pip install --no-deps -r requirements.txt

# restore setuptools<81 in case requirements bumped it
python -m pip install --force-reinstall "setuptools<81"

# optional cleanup for pyscenic warning seen during install
python -m pip install diptest

# ------------------------------------------------------------
# smoke tests
# ------------------------------------------------------------
python - <<'PY'
import sys
print(sys.executable)
PY

python -c "import scenicplus; print('SCENIC+ import OK')"
python -c "import pycisTopic; print('pycisTopic import OK')"
python -c "import pycistarget; print('pycistarget import OK')"
python -c "import pyscenic; print('pySCENIC import OK')"
python -c "import pybedtools; print('pybedtools import OK', pybedtools.__version__)"
python -c "import diptest; print('diptest import OK')"
python -c "import scenicplus; import pycisTopic; import pycistarget; import pyscenic; import pybedtools; import diptest; print('all core imports OK')"

# ------------------------------------------------------------
# freeze working environment
# ------------------------------------------------------------
conda list -p /home/vzf0010/apps/conda_envs/scenicplus > /home/vzf0010/apps/conda_envs/scenicplus_conda_list.txt
python -m pip freeze > /home/vzf0010/apps/conda_envs/scenicplus_pip_freeze.txt
conda env export -p /home/vzf0010/apps/conda_envs/scenicplus > /home/vzf0010/apps/conda_envs/scenicplus_env_export.yml


module use /scratch/mathlab/packages/modules
module load openfoam/2012

export WM_PROJECT_USER_DIR=$PWD
export FOAM_USER_APPBIN=/home/gspasov/OpenFoam/platforms/linux64IccDPInt32OptBDW/bin
export FOAM_USER_LIBBIN=/home/gspasov/OpenFoam/platforms/linux64IccDPInt32OptBDW/lib

wmake -all >& wmake.log &

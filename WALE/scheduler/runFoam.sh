#!/bin/bash
#SBATCH --job-name=LES
#SBATCH --account=gspasov
#SBATCH --partition=regular2
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=20
#SBATCH --time=07:59:00
#SBATCH --mem=40GB
#SBATCH --error FOAM.err
#SBATCH --output FOAM.out


# Load modules
module use /scratch/mathlab/packages/modules
module load openfoam/2012

export FOAM_USER_APPBIN=/home/gspasov/OpenFoam/platforms/linux64IccDPInt32OptBDW/bin
export FOAM_USER_LIBBIN=/home/gspasov/OpenFoam/platforms/linux64IccDPInt32OptBDW/lib

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$FOAM_USER_LIBBIN
export PATH=$PATH:$FOAM_USER_APPBIN


# Set solver
PROG=pimpleFoam

# Load control dictionary
\cp system/controlDictFoam.tmp system/controlDict
rm -f controlDictFoam.tmp

# Initialize foam
rm -f runFoam.log
wait $!

if [ $SLURM_NTASKS -eq 1 ]; then
	cmd="$PROG"
else
	cmd="mpirun -n $SLURM_NTASKS $PROG -parallel"
fi

if [ "y" = "n" ] ; then
	if [ ! -d "0" ]; then
		cp -r 0.tmp 0
	else
		\cp -r 0.tmp/* 0/
	fi
	rm -rf 0.tmp
	wait $!
	if [ "y" = "y" ] ; then
		perturbUCylinder >> runFoam.log	
	fi
	rm -rf postProcessing
	wait $!
	if [ $SLURM_NTASKS -ne 1 ]; then
		rm -rf processor*
		wait $!
		\cp system/decomposeParDictFoam system/decomposeParDict
   		wait $!
   		sed -i -e 's/nProcFoam/'$SLURM_NTASKS'/g' system/decomposeParDict	
		wait $!
		decomposePar -latestTime >> runFoam.log
		wait $!
	fi
fi

if [ "y" = "y" ] && [ "n" = "y" ] && [ $SLURM_NTASKS -ne 1 ]; then
	cp system/decomposeParDictFoam system/decomposeParDict
    wait $!
    sed -i -e 's/nProcFoam/'$SLURM_NTASKS'/g' system/decomposeParDict
	wait $!
	decomposePar -latestTime > runFoam.log
	wait $!
fi

# Run foam
$cmd >> runFoam.log

# Finalize run
if [ $SLURM_NTASKS -ne 1 ]; then
	if [ "n" = "y" ]; then
		reconstructPar  >> runFoam.log
		wait $!
	else
		reconstructPar -latestTime  >> runFoam.log
		wait $!
	fi
	if [ "n" = "y" ]; then
		rm -rf processor*
	fi
fi
if [ "y" = "y" ]; then
    echo >> runFoam.log

    if [ -d  "postProcessing/cutPlanes" ]; then
        echo "Converting cut planes files..." >> runFoam.log

        cd postProcessing/cutPlanes/

        python2 ../../system/vtpAnim.py

        sh ../../system/makeVtpSeries.sh 1e-3

        cd ../..

        echo "Done." >> runFoam.log

        if [ "y" = "y" ]; then
            echo >> runFoam.log

            echo "Cleaning cut planes folders..." >> runFoam.log

            mv postProcessing/cutPlanes/*.vtp postProcessing/cutPlanes/*.series postProcessing/

            rm -rf postProcessing/cutPlanes/*

            mv postProcessing/*.vtp postProcessing/*.series postProcessing/cutPlanes/

            echo "Done." >> runFoam.log
        fi
    else
        echo "postProcessing/cutPlanes does not exist..." >> runFoam.log
    fi
fi
if [ "y" = "y" ]; then
    echo >> runFoam.log

    if [ -d  "postProcessing/isoSurfaces" ]; then
        echo "Converting iso surfaces files..." >> runFoam.log

        cd postProcessing/isoSurfaces/

        python2 ../../system/vtpAnim.py

        sh ../../system/makeVtpSeries.sh 5e-3

        cd ../..

        echo "Done." >> runFoam.log

        if [ "y" = "y" ]; then
            echo >> runFoam.log

            echo "Cleaning iso surfaces folder..." >> runFoam.log

            mv postProcessing/isoSurfaces/*.vtp postProcessing/isoSurfaces/*.series postProcessing/

            rm -rf postProcessing/isoSurfaces/*

            mv postProcessing/*.vtp postProcessing/*.series postProcessing/isoSurfaces/

            echo "Done." >> runFoam.log
        fi
    else
        echo "postProcessing/isoSurfaces does not exist..." >> runFoam.log
    fi
fi

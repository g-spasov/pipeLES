#
# Description: extract radial profiles of field variables from slice at several angular locations
#
# Usage: pvpython extractProfiles.py [casePath] [sliceNormal (string)] [sliceOrigin (float)] [nProfiles (integer)]
# Output: profile1.csv, profile2.csv, profile3.csv,..., profileN.csv

# Import modules
import os
from paraview.simple import *
from math import *

# Read arguments
sliceNormal = sys.argv[2]
sliceOrigin = float(sys.argv[3])
nProfiles = int(sys.argv[4])+1

# Read dataset
openfoam = OpenFOAMReader(FileName=[sys.argv[1]+'open.foam'])
openfoam.MeshRegions = ['internalMesh']
openfoam.CellArrays = ['UMean','UPrime2Mean','pMean','pPrime2Mean']

# Go to last time folder
animationScene1 = GetAnimationScene()
animationScene1.UpdateAnimationUsingDataTimeSteps()
animationScene1.GoToLast()

# Create streamwise slice and initial intersection curve filter
slice1 = Slice(Input=openfoam)
slice1.SliceType = 'Plane'
slice1.SliceOffsetValues = [0.0]
plotOnIntersectionCurves1 = PlotOnIntersectionCurves(Input=slice1)
plotOnIntersectionCurves1.SliceType = 'Plane'
if sliceNormal == 'x':
	slice1.SliceType.Origin = [sliceOrigin, 0.0, 0.0]
	slice1.SliceType.Normal = [1.0, 0.0, 0.0]
	plotOnIntersectionCurves1.SliceType.Normal = [0.0, 1.0, 0.0]
if sliceNormal == 'y':
	slice1.SliceType.Origin = [0.0, sliceOrigin, 0.0]
	slice1.SliceType.Normal = [0.0, 1.0, 0.0]
	plotOnIntersectionCurves1.SliceType.Normal = [0.0, 0.0, 1.0]
if sliceNormal == 'z':
	slice1.SliceType.Origin = [0.0, 0.0, sliceOrigin]
	slice1.SliceType.Normal = [0.0, 0.0, 1.0]
	plotOnIntersectionCurves1.SliceType.Normal = [1.0, 0.0, 0.0]

lineChartView1 = CreateView('XYChartView')

print("\n Extracting profiles...")

# Loop over all radial sections
for i in range(1,nProfiles,1):

	angle=(i-1)*2*pi/nProfiles
	uProfileNormal=sin(angle)
	vProfileNormal=cos(angle)

	# Update plot on intersection curve filter
	if sliceNormal == 'x':
		plotOnIntersectionCurves1.SliceType.Normal = [0.0, uProfileNormal, vProfileNormal]
	if sliceNormal == 'y':
		plotOnIntersectionCurves1.SliceType.Normal = [uProfileNormal, 0.0, vProfileNormal]
	if sliceNormal == 'z':
		plotOnIntersectionCurves1.SliceType.Normal = [uProfileNormal, vProfileNormal, 0.0]

	plotOnIntersectionCurves1Display = Show(plotOnIntersectionCurves1, lineChartView1)
	plotOnIntersectionCurves1Display.CompositeDataSetIndex = []
	plotOnIntersectionCurves1Display.UseIndexForXAxis = 0
	plotOnIntersectionCurves1Display.XArrayName = 'arc_length'
	lineChartView1.Update()

	# Save current slice
	SaveData('./profile' + str(i) +'.csv', proxy=plotOnIntersectionCurves1, UseScientificNotation=1)

# Edit output files
os.system("sed -i -e 's/,/ /g' profile*")

print(" Done.\n")

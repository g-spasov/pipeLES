/*---------------------------------------------------------------------------*\
Date: June 24, 2005
Author: Eugene de Villiers
Source: http://www.cfd-online.com/Forums/openfoam-solving/58043-les-2.html#post187619
-------------------------------------------------------------------------------
License
    This file is a derivative work of OpenFOAM.

    OpenFOAM is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with OpenFOAM; if not, write to the Free Software Foundation,
    Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Application
    perturbU

Description
    initialise channel velocity with superimposed streamwise streaks.
    To be used to force channelOodles to transition and reach a fully
    developed flow sooner.

    Reads in perturbUDict.

    EdV from paper:
        Schoppa, W. and Hussain, F.
        "Coherent structure dynamics in near wall turbulence",
        Fluid Dynamics Research, Vol 26, pp119-139, 2000.

\*---------------------------------------------------------------------------*/

#include "fvCFD.H"
#include "Random.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

int main(int argc, char *argv[])
{
#   include "setRootCase.H"

#   include "createTime.H"
#   include "createMesh.H"

    // These values should be edited according to the case
    // d is the diameter of the pipe
    // Ubar should be set in transportProperties
    // Flow must be in the x direction

    IOdictionary perturbDict
    (
        IOobject
        (
            "perturbUDict",
            runTime.constant(),
            mesh,
            IOobject::MUST_READ,
            IOobject::NO_WRITE
        )
    );
    const scalar Retau(readScalar(perturbDict.lookup("Retau")));
    const scalar d(readScalar(perturbDict.lookup("d")));
 	const bool setBulk(readBool(perturbDict.lookup("setBulk")));
    const bool perturb(readBool(perturbDict.lookup("perturb")));
    const scalar du(readScalar(perturbDict.lookup("duPlus")));
    const scalar beta(readScalar(perturbDict.lookup("betaPlus")));
    const scalar alpha(readScalar(perturbDict.lookup("alphaPlus")));
    const scalar sigma(readScalar(perturbDict.lookup("sigma")));
    const scalar epsilon(readScalar(perturbDict.lookup("epsilonPlus")));

    Info<< "Pipe diameter             = " << d << nl
        << "Re(tau)                   = " << Retau << nl
        << "Set bulk flow             = " << Switch(setBulk) << nl
        << "Perturb flow              = " << Switch(perturb) << nl
		<< "Wall normal circulation as a fraction of Ubar/utau  = " << du << nl
    	<< "Spanwise perturbation spacing in wall units         = " << beta << nl
    	<< "Streamwise perturbation spacing in wall units       = " << alpha << nl
    	<< "Linear perturbation amplitude as a fraction of Ubar = " << epsilon << nl
		<< "Transverse decay = " << sigma << nl
        << endl;


    if (!setBulk && !perturb)
    {
        FatalErrorIn(args.executable())
            << "At least one of setBulk or perturb needs to be set"
            << " to do anything to the velocity"
            << exit(FatalError);
    }

    IOobject Uheader
    (
        "U",
        runTime.timeName(),
        mesh,
        IOobject::MUST_READ
    );
    Info<< "Reading U" << endl;
    volVectorField U(Uheader, mesh);

    IOdictionary transportProperties
    (
        IOobject
        (
            "transportProperties",
            runTime.constant(),
            mesh,
            IOobject::MUST_READ,
            IOobject::NO_WRITE
        )
    );

    dimensionedScalar nu
    (
        transportProperties.lookup("nu")
    );
    dimensionedVector Ubar
    (
        transportProperties.lookup("Ubar")
    );


    //Info<< "nu      = " << nu << endl;
    //Info<< "Ubar    = " << Ubar << endl;
    //Info<< "Re(tau) = " << Retau << endl;
    const scalar utau = Retau*nu.value()/(d/2.0);
    //Info<< "u(tau)  = " << utau << endl;


    //wall normal circulation
    const scalar duPlus = Ubar.value()[0]*du/utau;
	//spanwise wavenumber: spacing z+ = 200
    const scalar betaPlus = 2.0*constant::mathematical::pi*(1.0/beta);
    //streamwise wave number: spacing x+ = 500
    const scalar alphaPlus = 2.0*constant::mathematical::pi*(1.0/alpha);
    const scalar epsilonPlus = Ubar.value()[0]*epsilon;

    const vectorField& centres = mesh.C();

	forAll(centres, celli)
    {
    	scalar& Ux(U[celli].x());
        vector cCenter = centres[celli];
        scalar r = ::sqrt(::sqr(cCenter.y()) + ::sqr(cCenter.z()));
        
		if (setBulk)
        {
            // laminar parabolic profile
			Ux = 2*mag(Ubar.value())*(1-::sqr(2*r/d));
        }

		if (perturb)
        {
			scalar y = d - r;
        	r = r*Retau/d;
        	y = y*Retau/d;

        	scalar theta = ::atan(cCenter.y()/cCenter.z());
        	scalar x = cCenter.x()*Retau/d;

        	Ux = Ux + (utau*duPlus/2.0)
        	     *::cos(betaPlus*theta*r) *(y/30)
        	     *::exp(-sigma*::sqr(y) + 0.5);
        	scalar utheta = epsilonPlus*::sin(alphaPlus*x)*y
        	                *::exp(-sigma*::sqr(y));

        	vector tangential
        	(
        		0, cCenter.y(), cCenter.z()
        	);
        	tangential = tangential ^ vector(1,0,0);
        	tangential = tangential/mag(tangential);
			U[celli] = U[celli] + utheta*tangential;
		}
	}

    Info<< "Writing modified U field to " << runTime.timeName() << endl;
    U.write();

    Info<< endl;

    return(0);
}


// ************************************************************************* //

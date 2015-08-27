#! /usr/bin/octave -q

format long
global dcp basis db prefix nstep verbose run_inputs ycur dcpfin...
       costmin iload stime0 astep dcpeval maxnorm fixnorm

#### Modify this to change the input behavior ####

## Do you want lots of stuff in the output?
verbose = 0;

## Functional
method="blyp";

## Basis set or basis file or files. You can use a single string
## or a cell array. If you use a string, then the script will look
## for a file by that name. If the file does not exist, then the string
## will be assumed to be a Gaussian keyword and passed to the input
## If a file is found, it is parsed and the basis-set information read,
## then information for the relevant atoms passed to the inputs. 
## Several basis set files can be used (e.g. {"basis1","basis2"}).
## basis="basis.ini";
basis="basis.ini";

## Extra bits for gaussian (do not include pseudo=read here)
# extragau="EmpiricalDispersion=GD3BJ SCF=(Conver=6, MaxCycle=40) Symm=Loose int=(grid=ultrafine)";
extragau="SCF=(Conver=6, MaxCycle=40) Symm=Loose int=(grid=ultrafine)";

## Number of CPUs and memory (in GB) for Gaussian runs
ncpu=8;
mem=2;

## List of database files to use in DCP optimization
listdb={...
"atz_blyp/s225_2pyridoxine2aminopyridin09.db","atz_blyp/s225_2pyridoxine2aminopyridin10.db","atz_blyp/s225_2pyridoxine2aminopyridin12.db",...
"atz_blyp/s225_2pyridoxine2aminopyridin15.db","atz_blyp/s225_2pyridoxine2aminopyridin20.db","atz_blyp/s225_adeninethyminestack09.db",...
"atz_blyp/s225_adeninethyminestack10.db","atz_blyp/s225_adeninethyminestack12.db","atz_blyp/s225_adeninethyminestack15.db",...
"atz_blyp/s225_adeninethyminestack20.db","atz_blyp/s225_adeninethymineWC09.db","atz_blyp/s225_adeninethymineWC10.db",...
"atz_blyp/s225_adeninethymineWC12.db","atz_blyp/s225_adeninethymineWC15.db","atz_blyp/s225_adeninethymineWC20.db",...
"atz_blyp/s225_ammoniadimer09.db","atz_blyp/s225_ammoniadimer10.db","atz_blyp/s225_ammoniadimer12.db",...
"atz_blyp/s225_ammoniadimer15.db","atz_blyp/s225_ammoniadimer20.db","atz_blyp/s225_benzeneammonia09.db",...
"atz_blyp/s225_benzeneammonia10.db","atz_blyp/s225_benzeneammonia12.db","atz_blyp/s225_benzeneammonia15.db",...
"atz_blyp/s225_benzeneammonia20.db","atz_blyp/s225_benzenedimerstack09.db","atz_blyp/s225_benzenedimerstack10.db",...
"atz_blyp/s225_benzenedimerstack12.db","atz_blyp/s225_benzenedimerstack15.db","atz_blyp/s225_benzenedimerstack20.db",...
"atz_blyp/s225_benzenedimerTshape09.db","atz_blyp/s225_benzenedimerTshape10.db","atz_blyp/s225_benzenedimerTshape12.db",...
"atz_blyp/s225_benzenedimerTshape15.db","atz_blyp/s225_benzenedimerTshape20.db","atz_blyp/s225_benzeneHCN09.db",...
"atz_blyp/s225_benzeneHCN10.db","atz_blyp/s225_benzeneHCN12.db","atz_blyp/s225_benzeneHCN15.db",...
"atz_blyp/s225_benzeneHCN20.db","atz_blyp/s225_benzenemethane09.db","atz_blyp/s225_benzenemethane10.db",...
"atz_blyp/s225_benzenemethane12.db","atz_blyp/s225_benzenemethane15.db","atz_blyp/s225_benzenemethane20.db",...
"atz_blyp/s225_benzenewater09.db","atz_blyp/s225_benzenewater10.db","atz_blyp/s225_benzenewater12.db",...
"atz_blyp/s225_benzenewater15.db","atz_blyp/s225_benzenewater20.db","atz_blyp/s225_ethenedimer09.db",...
"atz_blyp/s225_ethenedimer10.db","atz_blyp/s225_ethenedimer12.db","atz_blyp/s225_ethenedimer15.db",...
"atz_blyp/s225_ethenedimer20.db","atz_blyp/s225_etheneethyne09.db","atz_blyp/s225_etheneethyne10.db",...
"atz_blyp/s225_etheneethyne12.db","atz_blyp/s225_etheneethyne15.db","atz_blyp/s225_etheneethyne20.db",...
"atz_blyp/s225_formamidedimer09.db","atz_blyp/s225_formamidedimer10.db","atz_blyp/s225_formamidedimer12.db",...
"atz_blyp/s225_formamidedimer15.db","atz_blyp/s225_formamidedimer20.db","atz_blyp/s225_formicaciddimer09.db",...
"atz_blyp/s225_formicaciddimer10.db","atz_blyp/s225_formicaciddimer12.db","atz_blyp/s225_formicaciddimer15.db",...
"atz_blyp/s225_formicaciddimer20.db","atz_blyp/s225_indolebenzenestack09.db","atz_blyp/s225_indolebenzenestack10.db",...
"atz_blyp/s225_indolebenzenestack12.db","atz_blyp/s225_indolebenzenestack15.db","atz_blyp/s225_indolebenzenestack20.db",...
"atz_blyp/s225_indolebenzeneTshape09.db","atz_blyp/s225_indolebenzeneTshape10.db","atz_blyp/s225_indolebenzeneTshape12.db",...
"atz_blyp/s225_indolebenzeneTshape15.db","atz_blyp/s225_indolebenzeneTshape20.db","atz_blyp/s225_methanedimer09.db",...
"atz_blyp/s225_methanedimer10.db","atz_blyp/s225_methanedimer12.db","atz_blyp/s225_methanedimer15.db",...
"atz_blyp/s225_methanedimer20.db","atz_blyp/s225_phenoldimer09.db","atz_blyp/s225_phenoldimer10.db",...
"atz_blyp/s225_phenoldimer12.db","atz_blyp/s225_phenoldimer15.db","atz_blyp/s225_phenoldimer20.db",...
"atz_blyp/s225_pyrazinedimer09.db","atz_blyp/s225_pyrazinedimer10.db","atz_blyp/s225_pyrazinedimer12.db",...
"atz_blyp/s225_pyrazinedimer15.db","atz_blyp/s225_pyrazinedimer20.db","atz_blyp/s225_uracildimerHB09.db",...
"atz_blyp/s225_uracildimerHB10.db","atz_blyp/s225_uracildimerHB12.db","atz_blyp/s225_uracildimerHB15.db",...
"atz_blyp/s225_uracildimerHB20.db","atz_blyp/s225_uracildimerstack09.db","atz_blyp/s225_uracildimerstack10.db",...
"atz_blyp/s225_uracildimerstack12.db","atz_blyp/s225_uracildimerstack15.db","atz_blyp/s225_uracildimerstack20.db",...
"atz_blyp/s225_waterdimer09.db","atz_blyp/s225_waterdimer10.db","atz_blyp/s225_waterdimer12.db",...
"atz_blyp/s225_waterdimer15.db","atz_blyp/s225_waterdimer20.db",...
};
weightdb=[1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 ...
          1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 ...
          1 5 1 1 1 1 5 1 1 1 1 5 1 1 1 1 5 1 1 1];

## Initial DCP file (you can use a cell array of files here, like
## {"C.dcp","H.dcp"}, or a single string "bleh.dcp")
dcpini="dcp.ini";

## Final DCP file (can be the same as the initial file). While 
## the script is running, dcpfin contains the DCP for the evaluation
## with lowest cost function.
dcpfin="dcp.fin";

## Final evaluation file. Contains the evaluation of the best DCP
## found on hte parametrization set. While the script is running,
## dcpeval contains the DCP for the evaluation with the lowest cost
## function. 
dcpeval="dcp.eval";

## Prefix for the calculations. If prefix is "bleh", then all the
## inputs and outputs will be stored in subdirectory bleh/ of the
## current working directory. The file names will be bleh_xx.tar.bz2
## where xx is the DCP optimization evaluation number. The archive
## contains files bleh_xx_name, where name is the identifier for the
## database entry. 
prefix="bleh";

## Name of the function to be minimized 
funeval   = "fbasic";
funevald1 = "fbasicd1";
funevald2 = "fbasicd2";

## Name of the Gaussian input runner routine
## run_inputs = @run_inputs_serial; ## Run all Gaussian inputs sequentially on the same node
## run_inputs = @run_inputs_grex; ## Submit inputs to the queue, wait for all to finish. Grex version.
## run_inputs = @run_inputs_plonk; ## Submit inputs to a private queue, plonk version.
run_inputs = @run_inputs_nint_trasgu; ## Submit inputs to a private queue on the NINT cluster.
## run_inputs = @run_inputs_elcap3; ## Submit inputs to elcap3.

## Tolerance criteria for the minimization (function difference between successive steps)
ftol = 1d-1; ## function change tolerance for random walk batches

## Number of random batches
nrnd = Inf;

## Norm of the random step
rndstep = 1d-3;

## Maximum norm: when the norm of the coefficients (square root of the
## sum of the squares), the cost function is Inf. This limits the
## minimizer search to a ball of radius maxnorm around zero. (optional)
## maxnorm = 1d-3;

## Norm constraint: the norm of the coefficients is constrained to
## this value. (optional)
fixnorm = 1d-2;

#### No touching past this point. ####

## Header
printf("### Random walk started on %s ###\n",strtrim(ctime(time())));
printf("# PID: %d \n",getpid());

## Read the basis set
basis = parsebasis(basis);

## Read the initial DCP
dcp = parsedcp(dcpini);
if (verbose) 
  printf("### Initial DCP ###\n");
  writedcp(dcp);
endif

## Read the parametrization database 
db = parsedb(listdb);
db = filldb(db,weightdb,method,extragau,ncpu,mem);
if (verbose) 
  printf("### Database for the parametrization ###\n");
  writedb(db);
endif

## Crash if some of the DCP atoms are not used in any of the
## db files
for i = 1:length(dcp)
  atom = dcp{i}.atom;
  ifound = 0;
  for j = 1:length(db)
    for k = 1:db{j}.mol.nat
      if (tolower(atom) == tolower(db{j}.mol.at{k}))
        ifound = 1;
        break
      endif
    endfor
    if (ifound)
      break
    endif
  endfor
  if (!ifound)
    error(sprintf("Atom %s is present in the inital DCP file (%s) but is not present in any of the DB files.",atom,dcpini))
  endif
endfor

## Run the minimization, initialize global variables
nstep = 0;
astep = 0;
costmin = Inf;
iload = [];
stime0 = time();
x = packdcp(dcp);
if (exist("fixnorm","var") && fixnorm > 0)
  x(end) = sqrt(fixnorm^2 - sum(x(2:2:end).^2));
endif
n = length(x) / 2;

## Evaluate the zero DCP 
printf("# Evaluating the zero DCP cost\n");
x0 = x;
x0(2:2:end) = 0;
cost0 = feval(funeval,x0);

## Save the initial random seed
v = rand("state");
save "dcp_rwalk.seed" v;

irnd = 1;
while (irnd <= nrnd)
  ## Header
  printf("# Random batch number %d\n",irnd);

  ## Generate new random DCP using the dcpfin
  ## Number of coefficients to change
  nchng = floor(rand() * n + 1); 
  nchng = min(max(nchng,1),n);
  printf("# Number of coefficients changed: %d/%d [",nchng,n);

  ## Pick the nchng terms to change
  iperm = randperm(n);
  iperm = sort(iperm(1:nchng));
  for i = 1:nchng
    printf("%d ",iperm(i));
  endfor
  printf("]\n");

  ## Generate the coefficients using a normal distribution
  ## with mean zero and variance one
  step = randn(1,nchng);

  ## Normalize to the random step value
  stepnorm = rand() * rndstep;
  step = step / norm(step) * stepnorm;
  printf("# Step length: %.4e\n",stepnorm);

  ## Define the new step
  xnew = x;
  xnew(2*iperm) = xnew(2*iperm) + step;

  ## Normalize 
  if (exist("fixnorm","var") && fixnorm > 0)
    nn = norm(xnew(2:2:end));
    xnew(2:2:end) = xnew(2:2:end) / nn * fixnorm;
  endif
  if (exist("maxnorm","var") && maxnorm > 0)
    xnew(2:2:end) = min(xnew(2:2:end),maxnorm);
  endif
  printf("# New coefficient norm: %.4e\n",norm(xnew(2:2:end)));

  ## Check that the first DCP evaluation works
  cost = feval(funeval,xnew);

  ## Apply a Metropolis-like algorithm
  if (cost < cost0) 
    iaccept = 1;
    printf("# Step accepted (lower cost)\n");
    printf("# New intial cost for acceptance threshold: %.4f\n",cost0);
  else
    if (rand() < cost0/cost)
      printf("# Step accepted at probability %.4f\n",cost0/cost);
      iaccept = 1;
    else
      printf("# Step rejected\n");
      iaccept = 0;
    endif
  endif

  ## Accept the step and launch the minimization 
  if (iaccept)
    irnd++;
    cost0 = cost;
    [xmin, ymin] = d2_min(funeval,funevald2,xnew,ftol);
    x = xmin;
  endif
endwhile

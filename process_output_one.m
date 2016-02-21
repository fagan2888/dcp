% Copyright (C) 2015 Alberto Otero-de-la-Roza <alberto@fluor.quimica.uniovi.es>
%
% dcp is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free
% Software Foundation, either version 3 of the License, or (at your
% option) any later version. See <http://www.gnu.org/licenses/>.
%
% The routine distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
% more details.

function [dy ycalc yref dery ycalcnd] = process_output_one(ent,xdm=0,derivs=0)
  %% function [dy ycalc yref dery ycalcnd] = process_output_one(ent,xdm=0,derivs=0)
  %%
  %% Read the Gaussian output for database entry ent. The
  %% output file should have been generated by Gaussian after 
  %% a call to run_inputs. Depending on the type of entry, evaluate
  %% the result (ycalc, e.g. calculate the energy) and compare to the 
  %% reference in the database (yref, e.g. the reference energy). 
  %% dy = ycalc - yref. The derivs parameter indicates the order
  %% of the derivatives to calculate in the argument dery. If xdm
  %% is given, return the bare binding energy in ycalcnd.

  h2k = 627.50947;
  global prefix nstep

  if (strcmp(ent.type,"be_frozen_monomer"))
    ## Read the energy for the dimer
    if (xdm) 
      file = sprintf("%s_%4.4d_%s_mol.pgout",prefix,nstep,ent.name);
    else
      file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    endif
    if (!exist(file,"file"))
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif
    if (xdm) 
      [s out] = system(sprintf("grep 'total energy' %s | awk '{print $NF}'",file));
      [s2 out2] = system(sprintf("grep 'scf energy' %s | awk '{print $NF}'",file));
      e2s = str2num(out2);
    else
      [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
      e2s = 0;
    endif
    e2 = str2num(out);
    if (s != 0 || isempty(e2)) 
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif

    ## Then the monomer 1
    if (ent.mon1.nat > 0)
      if (xdm) 
        file = sprintf("%s_%4.4d_%s_mon1.pgout",prefix,nstep,ent.name);
      else
        file = sprintf("%s_%4.4d_%s_mon1.log",prefix,nstep,ent.name);
      endif
      if (!exist(file,"file"))
        dy = ycalc = yref = ycalcnd = Inf;
        return
      endif
      if (xdm)
        [s out] = system(sprintf("grep 'total energy' %s | awk '{print $NF}'",file));
        [s2 out2] = system(sprintf("grep 'scf energy' %s | awk '{print $NF}'",file));
        e1as = str2num(out2);
      else
        [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
        e1as = 0;
      endif
      e1a = str2num(out);
      if (s != 0 || isempty(e1a)) 
        dy = ycalc = yref = ycalcnd = Inf;
        return
      endif
    else 
      e1a = 0;
      e1as = 0;
    endif

    ## Then the monomer 2
    if (ent.mon2.nat > 0)
      if (xdm)
        file = sprintf("%s_%4.4d_%s_mon2.pgout",prefix,nstep,ent.name);
      else
        file = sprintf("%s_%4.4d_%s_mon2.log",prefix,nstep,ent.name);
      endif
      if (!exist(file,"file"))
        dy = ycalc = yref = ycalcnd = Inf;
        return
      endif
      if (xdm)
        [s out] = system(sprintf("grep 'total energy' %s | awk '{print $NF}'",file));
        [s2 out2] = system(sprintf("grep 'scf energy' %s | awk '{print $NF}'",file));
        e1bs = str2num(out);
      else
        [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
        e1bs = 0;
      endif
      e1b = str2num(out);
      if (s != 0 || isempty(e1b)) 
        dy = ycalc = yref = ycalcnd = Inf;
        return
      endif
    else
      e1b = 0;
      e1bs = 0;
    endif

    if (derivs == 0)
      ## Scalar calculation
      ycalc = (e2 - e1a - e1b) * h2k;
      ycalcnd = (e2s - e1as - e1bs) * h2k;
      yref = ent.ref;
      dy = ycalc - yref;
      dery = 0;
    else
      ## Derivatives/term contribution calculation
      n = length(e2);
      if (length(e1a) != n)
        e1a = zeros(size(e2));
      endif
      if (length(e1b) != n)
        e1b = zeros(size(e2));
      endif

      ## The scalar value
      ycalc = (e2(1) - e1a(1) - e1b(1)) * h2k;
      ycalcnd = (e2s(1) - e1as(1) - e1bs(1)) * h2k;
      yref = ent.ref;
      dy = ycalc - yref;

      ## Prepare for derivatives 
      n = length(e2)-2;
      if (abs(n-round(n)) > 1d-10)
        error("Length of the output array is not consistent. (2n+2, 2n+4)");
      endif
      e2_c = e2(3:n+2) - e2(2);
      e1a_c = e1a(3:n+2) - e1a(2);
      e1b_c = e1b(3:n+2) - e1b(2);
      be_c = (e2_c - e1a_c - e1b_c) * h2k;

      ## First derivatives
      dery = zeros(1,n);
      dery = be_c';
    endif
  elseif (strcmp(ent.type,"intramol_geometry"))
    ## Read the output geometry
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    if (!exist(file,"file"))
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif
    mol = mol_readlog(file);

    ## Compare to the reference molecule
    rmsd = mol_kabsch(mol.atxyz,ent.mol.x') * 1000;
    ycalc = rmsd;
    ycalcnd = rmsd;
    yref = 0;
    dy = ycalc;
    dery = 0;
  elseif (strcmp(ent.type,"intermol_geometry"))
    ## Read the output geometry
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    if (!exist(file,"file"))
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif
    mol = mol_readlog(file);

    ## Calculate the center of mass of each fragment
    n1 = ent.mon1.nat;
    n2 = ent.mon2.nat;
    xcm1 = sum(mol.atxyz(:,1:n1),2) / n1;
    xcm2 = sum(mol.atxyz(:,n1+1:n1+n2),2) / n2;
    dist = norm(xcm1 - xcm2);

    ## Compare to the reference molecule
    ycalc = dist;
    ycalcnd = dist;
    yref = ent.ref;
    dy = ycalc - yref;
    dery = 0;
  elseif (strcmp(ent.type,"total_energy"))
    ## Read the output energy
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    if (!exist(file,"file"))
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif
    [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
    e = str2num(out);
    if (s != 0 || isempty(e)) 
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif

    ## Compare to the reference molecule
    ycalc = e;
    ycalcnd = e;
    yref = ent.ref;
    dy = e-ent.ref;
    dery = 0;
  elseif (strcmp(ent.type,"dipole"))
    ## Read the output energy
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    if (!exist(file,"file"))
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif
    [s out] = system(sprintf("grep -A 1 'Dipole moment' %s | tail -n 1 | awk '{print $NF}'",file));
    e = str2num(out);
    if (s != 0 || isempty(e)) 
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif

    ## Compare to the reference molecule
    ycalc = e;
    ycalcnd = e;
    yref = ent.ref;
    dy = e-ent.ref;
    dery = 0;
  else
    ## I don't know what that type is
    error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
  endif
  
endfunction

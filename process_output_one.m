% Copyright (C) 2015 Alberto Otero-de-la-Roza <aoterodelaroza@gmail.com>
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
  global prefix nstep ferr

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# process_output_one %s - %s\n",ent.name,strtrim(ctime(time())));
    fflush(ferr);
  endif

  if (strcmp(ent.type,"reaction_frozen"))
    ycalc = ycalcnd = 0;
    dery = [];
    for j = 1:ent.nmol
      ## Read the energy for the dimer
      if (xdm)
        file = sprintf("%s_%4.4d_%s_mol%d.pgout",prefix,nstep,ent.name,j);
      else
        file = sprintf("%s_%4.4d_%s_mol%d.log",prefix,nstep,ent.name,j);
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

      if (derivs == 0)
        ## Scalar calculation
        ycalc += ent.molc{j}.coef * e2 * h2k;
        ycalcnd += ent.molc{j}.coef * e2s * h2k;
      else
        ## Derivatives/term contribution calculation
        n = length(e2);
        if (isempty(dery))
          dery = zeros(1,n-2);
        endif

        ## The scalar value
        ycalc += ent.molc{j}.coef * e2(1) * h2k;
        ycalcnd += ent.molc{j}.coef * e2s(1) * h2k;

        ## Prepare for derivatives 
        e2_c = ent.molc{j}.coef * (e2(3:n) - e2(2)) * h2k;

        ## First derivatives
        dery += e2_c';
      endif
    endfor

    yref = ent.ref;
    dy = ycalc - yref;

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
    if (derivs == 0) 
      ycalc = e;
      ycalcnd = e;
      yref = ent.ref;
      dy = e-ent.ref;
      dery = 0;
    else
      n = length(e);
      ## The scalar value
      ycalc = e(1);
      ycalcnd = e(1);
      yref = ent.ref;
      dy = ycalc - yref;
      
      ## Prepare for derivatives 
      e_c = e(3:n) - e(2);

      ## First derivatives
      dery = zeros(1,n);
      dery = e_c';
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
  elseif (strcmp(ent.type,"dipole"))
    ## Read the dipole from the output
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
  elseif (strcmp(ent.type,"multipoles"))
    ## Read the multipoles from the output
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);

    if (!exist(file,"file"))
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif

    e = zeros(1,34);
    if (ent.reftype >= 1 && ent.reftype <= 3)
      [s out] = system(sprintf("grep -A 1 'Dipole moment' %s | tail -n 1 | awk '{print $2, $4, $6}' | tr '\n' ' '",file));
      e(1:3) = str2num(out);
    elseif (ent.reftype >= 4 && ent.reftype <= 9)
      [s out] = system(sprintf("grep -A 2 '^ *Quadrupole moment' %s | tail -n 2 | awk '{print $2, $4, $6}' | tr '\n' ' '",file));
      e(4:9) = str2num(out);
    elseif (ent.reftype >= 10 && ent.reftype <= 19)
      [s out] = system(sprintf("grep -A 3 'Octapole moment' %s | tail -n 3 | awk '{print $2, $4, $6, $8}' | tr '\n' ' '",file));
      e(10:19) = str2num(out);
    elseif (ent.reftype >= 20 && ent.reftype <= 34)
      [s out] = system(sprintf("grep -A 4 'Hexadecapole moment' %s | tail -n 4 | awk '{print $2, $4, $6, $8}' | tr '\n' ' '",file));
      e(20:34) = str2num(out);
    endif

    if (s != 0 || isempty(e)) 
      dy = ycalc = yref = ycalcnd = Inf;
      return
    endif
    e = e(ent.reftype);

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

% Copyright (C) 2015 Alberto Otero-de-la-Roza <aoterodelaroza@gmail.com>
%
% acp is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free
% Software Foundation, either version 3 of the License, or (at your
% option) any later version. See <http://www.gnu.org/licenses/>.
%
% The routine distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
% more details.

function [x xempty] = process_output_one_postscf(ent,atoms,lchan,lexp)
  %% function [x xempty] = process_output_one_postscf(ent,atoms,lchan,lexp)
  %%
  %% Read the Gaussian output for database entry ent. The output file
  %% should have been generated by Gaussian after a call to
  %% run_inputs. Depending on the type of entry, evaluate the result
  %% (x, e.g. calculate the energy) and compare to the reference
  %% in the database (yref, e.g. the reference energy).  dy = ycalc -
  %% yref. The derivs parameter indicates the order of the derivatives
  %% to calculate in the argument dery. If xdm is non-empty, return
  %% the bare binding energy in ycalcnd and the dispersion-corrected
  %% energy in ycalc. If d3 is non-empty, return the d3-corrected
  %% binding energy in ycalc and the bare binding energy in ycalcnd.

  h2k = 627.50947;
  global prefix nstep ferr

  llabel = {"l","s","p","d"};
  l2num = struct();
  l2num.l = 1;
  l2num.s = 2;
  l2num.p = 3;
  l2num.d = 4;

  ## Debug
  if (ferr > 0) 
    fprintf(ferr,"# process_output_one_postscf %s - %s\n",ent.name,strtrim(ctime(time())));
    fflush(ferr);
  endif

  ## Expected number of items on output
  nterm = 0;
  for i = 1:length(atoms)
    for j = 1:getfield(l2num,lower(lchan{i}))
      nterm = nterm + length(lexp);
    endfor
  endfor
  x = zeros(nterm,1);
  xempty = 0;

  if (strcmp(ent.type,"reaction_frozen"))
    for j = 1:ent.nmol
      ## Normal termination
      file = sprintf("%s_%4.4d_%s_mol%d.log",prefix,nstep,ent.name,j);
      ok = exist(file,"file");
      [s out] = system(sprintf("tail -n 1 %s | grep Normal",file));
      if (!ok || s != 0)
        x(:) = Inf;
        return
      endif

      ## Read the energies
      file = sprintf("%s_%4.4d_%s_mol%d.log",prefix,nstep,ent.name,j);
      [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
      aux = str2num(out);

      ## Check we have the correct number of them
      if (length(aux) != nterm+1)
        x(:) = Inf;
        return
      endif        

      ## Accumulate in the result vector
      x += ent.molc{j}.coef * aux(2:end);
      xempty += ent.molc{j}.coef * aux(1);
    endfor
    x *= h2k;
    xempty *= h2k;

  elseif (strcmp(ent.type,"total_energy"))
    ## Normal termination
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    ok = exist(file,"file");
    [s out] = system(sprintf("tail -n 1 %s | grep Normal",file));
    if (!ok || s != 0)
      x(:) = Inf;
      return
    endif

    ## Read the energies
    file = sprintf("%s_%4.4d_%s_mol.log",prefix,nstep,ent.name);
    [s out] = system(sprintf("grep Done %s | awk '{print $5}'",file));
    aux = str2num(out);

    ## Check we have the correct number of them
    if (length(aux) != nterm+1)
      x(:) = Inf;
      return
    endif        

    x = aux(2:end);
    xempty = aux(1);

  elseif (strcmp(ent.type,"intramol_geometry") || strcmp(ent.type,"intermol_geometry"))
    error("Geometries not implemented in postscf")

  elseif (strcmp(ent.type,"dipole"))
    error("Not implemented")
  elseif (strcmp(ent.type,"multipoles"))
    error("Not implemented")
  else
    ## I don't know what that type is
    error(sprintf("Unknown type (%s) in entry %s",db{i}.type,db{i}.file))
  endif
  
endfunction
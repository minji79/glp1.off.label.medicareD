# start
ssh -X c-mkim255-59883@jhpcecms01.jhsph.edu  
srun --pty --x11 --partition=sas bash

# directory
cd /cms01/data/dua/59883/
cd /users/59883/c-mkim255-59883/

# figure reset
mv  .config/chromium/ .config/chromium.aside

# in the directory
cd glp1off/sas_input

## using R
module load R
module load rstudio
rstudio

## set the main directory
setwd("/users/59883/c-mkim255-59883/glp1off/sas_input")


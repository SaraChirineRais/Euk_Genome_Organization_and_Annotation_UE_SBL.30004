srun --partition=pibu_el8 \
--nodes=1 --ntasks=1 --cpus-per-task=4 \
--mem=32G --time=02:00:00 \
--account=class-sbl-30004-ws-2026 \
--reservation=class-sbl-30004-2026-10-21 \
--pty bash -l

#prepare a pusher
git add .
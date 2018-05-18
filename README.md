# burstcoin-simple-plotter-docker
At last a burstcoin plotter fit for a human. Accepts simple arguments and will find or calculate the rest. This docker image uses the PoC Consortum's optimized burstcoin miner.

https://github.com/PoC-Consortium/cg_obup

## Quickstart
```
docker run \
  --rm \
  --name "burstcoin-simple-plotter" \
  --read-only \
  --interactive \
  --tty \
  --volume /mnt/drive_1/burstcoin-plots/:/plots/1:ro \
  --volume /mnt/drive_2/burstcoin-plots/:/plots/2:ro \
  --volume /mnt/drive_3:/plots/3:ro \
  --volume /mnt/drive_4/:/plots/4 \
  vangorra/burstcoin-simple-plotter-docker \
  --directory \
  /plots/4 \
  --size 200G \
  --source /plots
```

## Features
- Accepts human readable disk sizes for the target plot. Automatically calculates appropriate nonces.
- Detects account id from previous plot files.
- Automatically calulates the start nonce based on previous plot files.
- Generates a pre-optimized plot file.
- Automatic calculation of number of thread to use. It will use the number cpus listed in /proc/cpuinfo

## Command line arguments
```
  --directory    The destination to write the plot. (required)
  --size         Size of the plot. (eg 1G, 2.3T, etc) (required)
  --account      Account number. (Default: The account number from the previous plot)
  --threads      The number of threads to use. (Default: auto-detected)
  --start-nonce  Start nonce. (Default: 0 or last place left off on provided plots)
  --source       Source directory with other plots.  (multiple allowed)
```

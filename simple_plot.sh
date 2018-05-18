#!/usr/bin/env bash

DEFAULT_THREAD_COUNT=$(grep -c processor /proc/cpuinfo)

function showUsage() {
  cat << EOF
usage: simple_plot.sh --directory <directory> --size <size> --account <account> /dir/to/plots /dir2/to/plots /dir3/to/plots
  --directory    The destination to write the plot. (required)
  --size         Size of the plot. (eg 1G, 2.3T, etc) (required)
  --account      Account number. (Default: The account number from the previous plot)
  --threads      The number of threads to use. (Default: $DEFAULT_THREAD_COUNT)
  --start-nonce  Start nonce. (Default: 0 or last place left off on provided plots)
  --source       Source directory with other plots. (multiple allowed)
EOF
}

function getBytes() {
  echo "$1" | awk '{
    ex = index("KMGTPEZY", substr($1, length($1)))
    val = substr($1, 0, length($1) - 1)

    prod = val * 10^(ex * 3)

    sum += prod
  }
  END {print sum}'
}

PLOTS_DIRS=()
while [[ "$#" -gt 0 ]]
do
  key="$1"
  case "$key" in
    --directory)
      OUTPUT_DIR="$2"
      shift
      shift
    ;;
    --size)
      PLOT_SIZE_STR="$2"
      shift
      shift
    ;;
    --account)
      ACCOUNT_NUMBER="$2"
      shift
      shift
    ;;
    --threads)
      THREAD_COUNT="$2"
      shift
      shift
    ;;
    --start-nonce)
      NONCE_START="$2"
      shift
      shift
    ;;
    -h|--help|-help)
      showUsage
      exit
      shift
      shift
    ;;
    --source)
      PLOTS_DIRS+=("$2")
      shift
      shift
    ;;
    *)
      shift # past argument
    ;;
  esac
done

# Get the lastest plot file information.
PLOT_FILES=$(find ${PLOTS_DIRS[@]} -type f | grep -E '^.*/[0-9]{18,}_[0-9]+_[0-9]+_[0-9]+(\.plotting|\.plot)?$')
LAST_PLOT=$(echo "$PLOT_FILES" | xargs -I {} basename {} | sed -E 's/^[0-9]{18,}_//' | sort | tail -n1)
LAST_NONCE_START=$(echo "$LAST_PLOT" | cut -d '_' -f1)
LAST_NONCE_COUNT=$(echo "$LAST_PLOT" | cut -d '_' -f2)
LAST_PLOT_FILE=$(echo "$PLOT_FILES" | grep -E "$LAST_PLOT\$" | sort | tail -n1)
LAST_ACCOUNT_NUMBER=$(basename "$LAST_PLOT_FILE" | cut -d'_' -f1)


if [[ -z "$OUTPUT_DIR" ]]; then
  echo "Error: Output directory is required."
  showUsage
  exit 1
fi

if ! [[ -e "$OUTPUT_DIR" ]]; then
  echo "Error: Output directory does not exist: '$OUTPUT_DIR'."
  showUsage
  exit 1
fi

if ! [[ -d "$OUTPUT_DIR" ]]; then
  echo "Error: Provided output directory is not a directory: '$OUTPUT_DIR'."
  showUsage
  exit 1
fi

if [[ -z "$PLOT_SIZE_STR" ]]; then
  echo "Error: Plot size is required."
  showUsage
  exit 1
fi

if ! [[ `echo "$PLOT_SIZE_STR" | grep -E '^[0-9,\.]+[KMGTPEZY]$'` ]]; then
  echo "Error: Invalid plot size provided: '$PLOT_SIZE_STR'."
  showUsage
  exit 1
fi

SIZE_COUNT=$(getBytes "$PLOT_SIZE_STR")
NONCE_COUNT=$(expr "$SIZE_COUNT" "/" "262144" | cut -d'.' -f1)
DISK_DEVICE=$(findmnt --noheading --output SOURCE --target "$OUTPUT_DIR" | sed -E 's|^(/dev/[a-zA-Z0-9]+).*|\1|')
DISK_FREE_STR=$(df -h | grep "$DISK_DEVICE" | sed -E 's/ +/ /g' | cut -d' ' -f4)
DISK_FREE_BYTES=$(getBytes "$DISK_FREE_STR")
if [[ "$SIZE_COUNT" > "$DISK_FREE_BYTES" ]]; then
  echo "Error: Not enough free space on disk."
  exit 1
fi

if [[ -z "$THREAD_COUNT" ]]; then
  THREAD_COUNT="$DEFAULT_THREAD_COUNT"
fi

if ! [[ `echo "$THREAD_COUNT" | grep -E '^[0-9]+$'` ]]; then
  echo "Error: Invalid thread count provided: '$THREAD_COUNT'."
  showUsage
  exit 1
fi

if [[ -z "$ACCOUNT_NUMBER" ]] && [[ -n "$LAST_ACCOUNT_NUMBER" ]]; then
  echo "Using account number from latest plot: '$LAST_ACCOUNT_NUMBER'."
  ACCOUNT_NUMBER="$LAST_ACCOUNT_NUMBER"
fi

if [[ -z "$ACCOUNT_NUMBER" ]]; then
  echo "Error: Since no previous plots could be found, an account number is required."
  showUsage
  exit 1
fi

if ! [[ `echo "$ACCOUNT_NUMBER" | grep -E "^[0-9]{18,}$"` ]]; then
  echo "Error: Provided account number is invalid: '$ACCOUNT_NUMBER'."
  showUsage
  exit 1
fi

if [[ -z "$NONCE_START" ]] && [[ -n "$LAST_NONCE_START" ]]; then
  echo "Using nonce start from latest plot: '$LAST_NONCE_START'."
  NONCE_START=$(expr "$LAST_NONCE_START" "+" "$LAST_NONCE_COUNT")
elif [[ -z "$NONCE_START" ]]; then
  NONCE_START="0"
fi

if ! [[ `echo "$NONCE_START" | grep -E "^[0-9]+$"` ]]; then
  echo "Error: Provided nonce start is invalid: '$NONCE_START'."
  showUsage
  exit 1
fi

if [[ -n "$PLOT_FILES" ]]; then
  echo "Existing Plot Files Found:"
  echo "$PLOT_FILES" | sed -E 's/^/  /'
else
  echo "No existing plot files found."
fi

if [[ -n "$LAST_PLOT_FILE" ]]; then
  echo "Latest plot file: '$LAST_PLOT_FILE'."
fi

plot64 -k "$ACCOUNT_NUMBER" \
  -x 1 \
  -d "$OUTPUT_DIR" \
  -s "$NONCE_START" \
  -n "$NONCE_COUNT" \
  -t "$THREAD_COUNT" \
  -v

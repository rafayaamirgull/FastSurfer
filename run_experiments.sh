#!/bin/bash

# --- Configuration ---
DATA_BASE="/home/aamirh/my_mri_data/828/data"
OUTPUT_BASE="$HOME/my_fastsurfer_analysis"
LICENSE_PATH="$FREESURFER_HOME/.license"
# Adjusted to run only the remaining branch
BRANCHES=("t2reg") 
LOG_FILE="experiment_resume_$(date +%Y%m%d_%H%M%S).log"

# Subject Data Arrays
S1_T1s=("$DATA_BASE/OAS2_0001_MR1/mri/orig.mgz" "$DATA_BASE/OAS2_0001_MR2/mri/orig.mgz")
S1_IDs=("OAS2_0001_MR1" "OAS2_0001_MR2")

S2_T1s=("$DATA_BASE/OAS2_0002_MR1/mri/orig.mgz" "$DATA_BASE/OAS2_0002_MR2/mri/orig.mgz" "$DATA_BASE/OAS2_0002_MR3/mri/orig.mgz")
S2_IDs=("OAS2_0002_MR1" "OAS2_0002_MR2" "OAS2_0002_MR3")

# Redirect all output to log file and console
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Resuming Experiments at $(date)"
echo "Logging to $LOG_FILE"

# --- Error Handling Function ---
failure_handler() {
    echo "--------------------------------------------------------"
    echo "ERROR: Script failed at line $1"
    echo "Last Command: $BASH_COMMAND"
    echo "Check $LOG_FILE for details."
    echo "--------------------------------------------------------"
    exit 1
}

trap 'failure_handler $LINENO' ERR

# --- Pre-flight Checks ---
echo "Performing pre-flight checks..."

# if [[ -n $(git status --porcelain | grep -v "run_experiments.sh" | grep -v "resume_experiments.sh" | grep "^ [M|D|R|C|U]") ]]; then
#     echo "ERROR: You have uncommitted changes in your code."
#     echo "Please 'git stash' or 'git commit' your changes before running."
#     git status -s | grep -v "run_experiments.sh" | grep -v "resume_experiments.sh"
#     exit 1
# fi

if [ ! -f "$LICENSE_PATH" ]; then
    echo "ERROR: License file not found at $LICENSE_PATH"
    exit 1
fi

# --- Execution ---
for branch in "${BRANCHES[@]}"; do
    echo ">>> SWITCHING TO BRANCH: $branch"
    git checkout "$branch"
    
    CURRENT_SD="$OUTPUT_BASE/$branch"
    mkdir -p "$CURRENT_SD"

    # Run Subject 1 on the current branch
    echo ">>> Running Person 1 on $branch..."
    ./long_fastsurfer.sh \
        --fs_license "$LICENSE_PATH" \
        --tid OAS2_0001 \
        --t1s "${S1_T1s[@]}" \
        --tpids "${S1_IDs[@]}" \
        --sd "$CURRENT_SD" \
        --edits \
        --threads 4

    # Run Subject 2 on the current branch
    # Note: If the cerebellum leak is present on this branch as well, this step may still fail.
    echo ">>> Running Person 2 on $branch..."
    ./long_fastsurfer.sh \
        --fs_license "$LICENSE_PATH" \
        --tid OAS2_0002 \
        --t1s "${S2_T1s[@]}" \
        --tpids "${S2_IDs[@]}" \
        --sd "$CURRENT_SD" \
        --edits \
        --threads 4
done

echo "========================================"
echo "SUCCESS: All remaining experiments completed at $(date)"
echo "========================================"

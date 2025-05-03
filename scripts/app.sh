#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the sleep duration from environment variable, default to 7200 seconds if not set
SLEEP_DURATION=${WORKLOAD_SLEEP_DURATION:-7200}

# Initial delay before the first run starts (default: 0 seconds = no delay)
INITIAL_DELAY=${WORKLOAD_INITIAL_DELAY:-0}

if [ "$INITIAL_DELAY" -gt 0 ]; then
  echo "[$(date)] Waiting for initial delay period: ${INITIAL_DELAY} seconds..."
  sleep ${INITIAL_DELAY}
  echo "[$(date)] Initial delay finished."
fi

echo "--- Starting workload loop ---"
echo "--- Sleep duration inbetween runs is set to: ${SLEEP_DURATION} seconds ---"

# Initialize: start X session
echo "[$(date)] Running google-photos backup..."
echo "[Entry] Cleaning up potential stale Xvfb lock file..."
rm -f /tmp/.X99-lock
echo "[Entry] Cleaning up potential stale chrome session locks (e.g. when closing container abruptly)..."
rm -f /tmp/gphotos-cdp/Singleton* 
echo "[Entry] Starting Xvfb on :99..."
Xvfb :99 -screen 0 1280x800x24 &
XVFBPID=$!
export DISPLAY=:99

echo "[Entry] Xvfb PID: $XVFBPID. Display $DISPLAY set."
sleep 2

# Main app logic runs in an infinite loop
while true; do
    echo "[Entry] Running gphotos-cdp..."
    gphotos-cdp -v -dev -dldir /downloads -run /app/scripts/fix_time.sh
    EXIT_CODE=$?
    echo "[Entry] gphotos-cdp exited with code $EXIT_CODE."

    echo "[$(date)] Google-photos backup finished successfully."
    echo "[$(date)] Sleeping for ${SLEEP_DURATION} seconds until running again..."

    sleep ${SLEEP_DURATION}
done

echo "--- Exiting workload loop (unexpected) ---"
echo "[Entry] Killing Xvfb (PID $XVFBPID)."
kill $XVFBPID 2>/dev/null || echo "[Entry] Xvfb (PID $XVFBPID) already stopped." # Escaped PID, suppress error if already gone

exit 0

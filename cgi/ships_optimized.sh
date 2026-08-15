#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/db_config.sh"
source "$SCRIPT_DIR/common.sh"

require_session_or_exit
user_email="$REQUIRED_SESSION_EMAIL"

now_ts=$(date +%s)
active_since_ts=$((now_ts - 300))
track_floor_ts=$((now_ts - 3600))
since_param=$(get_request_param since || true)

if [ -n "$since_param" ]; then
    if ! valid_unix_timestamp "$since_param"; then
        print_json_error_and_exit "400 Bad Request" "Invalid since parameter"
    fi
    if [ "$since_param" -gt "$now_ts" ]; then
        since_param=$now_ts
    fi
fi

if [ -n "$since_param" ] && [ "$since_param" -gt "$track_floor_ts" ]; then
    track_since_ts="$since_param"
else
    track_since_ts="$track_floor_ts"
fi

run_mysql_query_or_exit active_rows "
    SELECT p.ship_mmsi,
           COALESCE(s.ship_name, p.ship_mmsi),
           p.latitude,
           p.longitude,
           UNIX_TIMESTAMP(p.timestamp)
    FROM positions p
    JOIN (
        SELECT ship_mmsi, MAX(timestamp) AS latest_ts
        FROM positions
        WHERE timestamp >= FROM_UNIXTIME($active_since_ts)
        GROUP BY ship_mmsi
    ) latest
      ON latest.ship_mmsi = p.ship_mmsi
     AND latest.latest_ts = p.timestamp
    LEFT JOIN ships s ON s.mmsi = p.ship_mmsi
    ORDER BY p.timestamp DESC, p.ship_mmsi ASC;
"

run_mysql_query_or_exit track_rows "
    SELECT p.ship_mmsi,
           COALESCE(s.ship_name, p.ship_mmsi),
           p.latitude,
           p.longitude,
           UNIX_TIMESTAMP(p.timestamp)
    FROM positions p
    JOIN (
        SELECT ship_mmsi
        FROM positions
        WHERE timestamp >= FROM_UNIXTIME($active_since_ts)
        GROUP BY ship_mmsi
    ) active ON active.ship_mmsi = p.ship_mmsi
    LEFT JOIN ships s ON s.mmsi = p.ship_mmsi
    WHERE p.timestamp >= FROM_UNIXTIME($track_since_ts)
    ORDER BY p.ship_mmsi ASC, p.timestamp ASC;
"

print_json_header
printf '{"status":"success","implementation":"optimized","user_email":"%s","server_time":%s,"ships":[' "$(json_escape "$user_email")" "$now_ts"

first_ship=1
while IFS=$'\t' read -r mmsi ship_name latitude longitude timestamp; do
    [ -z "$mmsi" ] && continue
    if [ "$first_ship" -eq 0 ]; then
        printf ','
    fi
    printf '{"mmsi":"%s","ship_name":"%s","latitude":%s,"longitude":%s,"timestamp":%s}' \
        "$(json_escape "$mmsi")" "$(json_escape "$ship_name")" "$latitude" "$longitude" "$timestamp"
    first_ship=0
done <<< "$active_rows"

printf '],"tracks":['

first_track=1
current_track_mmsi=""
first_point_in_track=1
while IFS=$'\t' read -r mmsi ship_name latitude longitude timestamp; do
    [ -z "$mmsi" ] && continue

    if [ "$mmsi" != "$current_track_mmsi" ]; then
        if [ -n "$current_track_mmsi" ]; then
            printf ']}'
        fi
        if [ "$first_track" -eq 0 ]; then
            printf ','
        fi
        printf '{"mmsi":"%s","ship_name":"%s","points":[' "$(json_escape "$mmsi")" "$(json_escape "$ship_name")"
        current_track_mmsi="$mmsi"
        first_point_in_track=1
        first_track=0
    fi

    if [ "$first_point_in_track" -eq 0 ]; then
        printf ','
    fi
    printf '{"latitude":%s,"longitude":%s,"timestamp":%s}' "$latitude" "$longitude" "$timestamp"
    first_point_in_track=0
done <<< "$track_rows"

if [ -n "$current_track_mmsi" ]; then
    printf ']}'
fi

printf ']}\n'
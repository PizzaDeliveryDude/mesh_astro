#!/bin/bash

# usage examples
# Griffith Observatory, Los Angles, CA
# mesh_astro.sh 34.11 -118.30 -8 0 "Griffith Observatory"
# Washington Monument, Washington DC
# mesh_astro.sh 38.88 -77.03 -5 0 "Washington DC"
# Central Park New York City
# mesh_astro.sh 40.78 -73.96 -5 0 "Central Park"

# global variables
LAT="${1:-40.78}"
LON="${2:--73.96}"
TZ="${3:--5}"
DST="true"
DIR="mesh_astro"
ID="PizaDude"
CHANNEL="${4:-10}"
SENTFROM="${5:-Central Park}"
MAX_LOGS_TO_KEEP="7"

# functions
logger()
{
  # gpt-5 mini wrote this in GitHub Copilot
  # logger - read stdin and append each input line to $DIR/file.log
  # prefixed with a timestamp in square brackets: [YYYY-MM-DD HH:MM:SS]
  #
  # Usage examples:
  #   printf "Hello World\n" | logger
  #   some_command 2>&1 | logger    # capture stdout+stderr of some_command
  #
  # By default logs to relative path: $DIR/file.log
  # You can override the log path by passing it as the first arg:
  #   printf "x\n" | logger /path/to/other.log

  # some_command 2>&1 | logger
  # printf "This is a test\n" | logger
  # printf "hi\n" | logger /absolute/or/relative/path/file.log
  #
  # this is OG log location to one file, no rotation
  #local log_file="${1:-$DIR/mesh_astro.log}"

  Day=$(date '+%Y-%m-%d')
  local log_file="${1:-$DIR/log/mesh_astro_$Day.log}"

  # Ensure directory exists
  mkdir -p -- "$(dirname -- "$log_file")"

  # Read stdin line-by-line and append timestamped lines to the log file.
  # The '|| [ -n "$line" ]' ensures the last line is handled even if it doesn't end with a newline.
  while IFS= read -r line || [ -n "$line" ]; do
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line" >> "$log_file"
  done

  # remove old logs
  find "${DIR}/log" -maxdepth 1 -name "$mesh_astro_*.log" -type f \
      | xargs -r ls -t \
      | tail -n +$((MAX_LOGS_TO_KEEP + 1)) \
      | xargs -r rm --
}
check_dependencies()
{
  printf "dependencies() started" | logger

  # check if curl is installed
  if command -v curl >/dev/null 2>&1 ; then
      printf "curl found" | logger
  else
      printf "curl not found" | logger
  fi

  # check if jq is installed
  if command -v jq >/dev/null 2>&1 ; then
      printf "jq found" | logger
  else
      printf "jq not found" | logger
  fi

  printf "dependencies() ended" | logger
}
send_message_to_mesh()
{
  printf "send_message_to_mesh() started" | logger

  local TIMESTAMP=$(date '+%H:%M:%S')
  printf "Channel: $CHANNEL" | logger
  MessageBody="$1"
  MessageBody+=$'\n'"📍$SENTFROM $TIMESTAMP"

  printf "Message Body: $MessageBody" | logger

  # check how long the message is
  local MessageBodyLength=${#MessageBody}
  printf "Message Body Length: $MessageBodyLength" | logger

  printf "python voo-doo" | logger
  #python -m venv ~/src/venv && source ~/src/venv/bin/activate;
  #python3 -m venv meshtastic_venv && source meshtastic_venv/bin/activate;
  source meshtastic_venv/bin/activate;

  printf "meshtastic cli" | logger
  meshtastic --ch-index $CHANNEL --sendtext "$MessageBody" | logger

  printf "send_message_to_mesh() ended" | logger
}
moon()
{
  printf "moon() started" | logger

  # basic variables
  local TODAYS_DATE=$(date '+%Y-%m-%d')
  local FILE="moon.json"
  local JSON=$DIR"/"$FILE
  local DATE="$TODAYS_DATE"

  # log all of the variables
  printf "TODAYS_DATE: $TODAYS_DATE" | logger
  printf "DIR: $DIR" | logger
  printf "FILE: $FILE" | logger
  printf "JSON: $JSON" | logger
  printf "DATE: $DATE" | logger
  printf "LAT: $LAT" | logger
  printf "LON: $LON" | logger
  printf "TZ: $TZ" | logger
  printf "DST: $DST" | logger
  printf "ID: $ID" | logger

  # build URL (coords as LAT,LON)
  local COORDS="${LAT},${LON}"
  printf "COORDS: $COORDS" | logger

  # Astronomical Applications API v4.0.1
  local URL="https://aa.usno.navy.mil/api/rstt/oneday?date=${DATE}&coords=${COORDS}&tz=${TZ}&dst=${DST}&id=${ID}"
  printf "URL: $URL" | logger

  # get data
  curl -H "Accept: application/json" --silent $URL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  # json data
  Latitude=$(jq -r .geometry.coordinates[1] $JSON)
  printf "JSON Data Latitude: $Latitude" | logger

  Longitude=$(jq -r .geometry.coordinates[0] $JSON)
  printf "JSON Data Longitude: $Longitude" | logger

  DayOfWeek=$(jq -r .properties.data.day_of_week $JSON)
  printf "JSON Data DayOfWeek: $DayOfWeek" | logger

  Month=$(jq -r .properties.data.month $JSON)
  printf "JSON Data Month: $Month" | logger

  Day=$(jq -r .properties.data.day $JSON)
  printf "JSON Data Day: $Day" | logger

  Year=$(jq -r .properties.data.year $JSON)
  printf "JSON Data Year: $Year" | logger

  TimeZone=$(jq -r .properties.data.tz $JSON)
  printf "JSON Data Time Zone: $TimeZone" | logger

  MoonClosestPhase=$(jq -r .properties.data.closestphase.phase $JSON)
  MoonClosestPhaseDay=$(jq -r .properties.data.closestphase.day $JSON)
  MoonClosestPhaseMonth=$(jq -r .properties.data.closestphase.month $JSON)
  MoonClosestPhaseYear=$(jq -r .properties.data.closestphase.year $JSON)
  printf "JSON Data Moon Closest Phase: $MoonClosestPhase $MoonClosestPhaseYear-$MoonClosestPhaseMonth-$MoonClosestPhaseDay" | logger

  MoonCurrentPhase=$(jq -r .properties.data.curphase $JSON)
  printf "JSON Data Moon Current Phase: $MoonCurrentPhase" | logger

  MoonIllumination=$(jq -r .properties.data.fracillum $JSON)
  printf "JSON Data Moon Illumination: $MoonIllumination%" | logger

  MoonRise=$(jq -r .properties.data.moondata[1].phen $JSON)
  MoonRiseTime=$(jq -r .properties.data.moondata[1].time $JSON)
  printf "JSON Data Moonrise: $MoonRiseTime" | logger
  MoonRiseTime=${MoonRiseTime:0:5}
  printf "Truncated Data Moonrise: $MoonRiseTime" | logger

  MoonUpperTransit=$(jq -r .properties.data.moondata[2].phen $JSON)
  MoonUpperTransitTime=$(jq -r .properties.data.moondata[2].time $JSON)
  printf "JSON Data Moon Upper Transit: $MoonUpperTransitTime" | logger
  MoonUpperTransitTime=${MoonUpperTransitTime:0:5}
  printf "Truncated Data Moon Upper Transit: $MoonUpperTransitTime" | logger

  MoonSet=$(jq -r .properties.data.moondata[0].phen $JSON)
  MoonSetTime=$(jq -r .properties.data.moondata[0].time $JSON)
  printf "JSON Data Moonset: $MoonSetTime" | logger
  MoonSetTime=${MoonSetTime:0:5}
  printf "Truncated Data Moonset: $MoonSetTime" | logger

  # https://emojis.wiki/moon-phases/
  # moon emoji
  MoonEmoji="🌙"
  if [[ $MoonCurrentPhase == "New Moon" ]]; then
  {
	  MoonEmoji="🌑"
  }
  elif [[ $MoonCurrentPhase == "Waxing Crescent" ]]; then
  {
	  MoonEmoji="🌒"
  }
  elif [[ $MoonCurrentPhase == "First Quarter" ]]; then
  {
	  MoonEmoji="🌓"
  }
  elif [[ $MoonCurrentPhase == "Waxing Gibbous" ]]; then
  {
	  MoonEmoji="🌔"
  }
  elif [[ $MoonCurrentPhase == "Full Moon" ]]; then
  {
	  MoonEmoji="🌕"
  }
  elif [[ $MoonCurrentPhase == "Waning Gibbous" ]]; then
  {
	  MoonEmoji="🌖"
  }
  elif [[ $MoonCurrentPhase == "Last Quarter" ]]; then
  {
	  MoonEmoji="🌗"
  }
  elif [[ $MoonCurrentPhase == "Waning Crescent" ]]; then
  {
	  MoonEmoji="🌘"
  }
  else
  {
	  printf "something went wrong with the moon phase emoji" | logger
  }
  fi
  printf "MoonEmoji: $MoonEmoji" | logger

  # moon message body
  MoonMessageBody=""
  MoonMessageBody+=$"Today's Moon $MoonEmoji"
  MoonMessageBody+=$'\n'"Phase:$MoonCurrentPhase"
  #MoonMessageBody+=$'\n'"Illumination:"$MoonIllumination
  MoonMessageBody+=$'\n'"Rise:$MoonRiseTime"
  MoonMessageBody+=$'\n'"Mid:$MoonUpperTransitTime"
  MoonMessageBody+=$'\n'"Set:$MoonSetTime"
  printf "Moon Message Body: $MoonMessageBody" | logger

  # check how long the message is
  MoonMessageBodyLength=${#MoonMessageBody}
  printf "Moon Message Body Length: $MoonMessageBodyLength" | logger

  # send today's moon data
  send_message_to_mesh "$MoonMessageBody"

  printf "moon() ended" | logger
}

sun()
{
  printf "sun() started" | logger

  # basic variables
  local TODAYS_DATE=$(date '+%Y-%m-%d')
  local FILE="sun.json"
  local JSON=$DIR"/"$FILE
  local DATE="$TODAYS_DATE"

  # log all of the variables
  printf "TODAYS_DATE: $TODAYS_DATE" | logger
  printf "DIR: $DIR" | logger
  printf "FILE: $FILE" | logger
  printf "JSON: $JSON" | logger
  printf "DATE: $DATE" | logger
  printf "LAT: $LAT" | logger
  printf "LON: $LON" | logger
  printf "TZ: $TZ" | logger
  printf "DST: $DST" | logger
  printf "ID: $ID" | logger

  # build URL (coords as LAT,LON)
  local COORDS="${LAT},${LON}"
  printf "COORDS: $COORDS" | logger

  # Astronomical Applications API v4.0.1
  local URL="https://aa.usno.navy.mil/api/rstt/oneday?date=${DATE}&coords=${COORDS}&tz=${TZ}&dst=${DST}&id=${ID}"
  printf "URL: $URL" | logger

  # get data
  curl -H "Accept: application/json" --silent $URL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  # json data
  Latitude=$(jq -r .geometry.coordinates[1] $JSON)
  printf "JSON Data Latitude: $Latitude" | logger

  Longitude=$(jq -r .geometry.coordinates[0] $JSON)
  printf "JSON Data Longitude: $Longitude" | logger

  DayOfWeek=$(jq -r .properties.data.day_of_week $JSON)
  printf "JSON Data DayOfWeek: $DayOfWeek" | logger

  Month=$(jq -r .properties.data.month $JSON)
  printf "JSON Data Month: $Month" | logger

  Day=$(jq -r .properties.data.day $JSON)
  printf "JSON Data Day: $Day" | logger

  Year=$(jq -r .properties.data.year $JSON)
  printf "JSON Data Year: $Year" | logger

  TimeZone=$(jq -r .properties.data.tz $JSON)
  printf "JSON Data Time Zone: $TimeZone" | logger

  SunBeginCivilTwilight=$(jq -r .properties.data.sundata[0].phen $JSON)
  SunBeginCivilTwilightTime=$(jq -r .properties.data.sundata[0].time $JSON)
  printf "JSON Data Sun $SunBeginCivilTwilight: $SunBeginCivilTwilightTime" | logger
  SunBeginCivilTwilightTime=${SunBeginCivilTwilightTime:0:5}
  printf "Truncated Data Sun $SunBeginCivilTwilight: $SunBeginCivilTwilightTime" | logger

  SunRise=$(jq -r .properties.data.sundata[1].phen $JSON)
  SunRiseTime=$(jq -r .properties.data.sundata[1].time $JSON)
  printf "JSON Data Sun Rise: $SunRiseTime" | logger
  SunRiseTime=${SunRiseTime:0:5}
  printf "Truncated Data Sun Rise: $SunRiseTime" | logger

  SunUpperTransit=$(jq -r .properties.data.sundata[2].phen $JSON)
  SunUpperTransitTime=$(jq -r .properties.data.sundata[2].time $JSON)
  printf "JSON Data Sun Upper Transit: $SunUpperTransitTime" | logger
  SunUpperTransitTime=${SunUpperTransitTime:0:5}
  printf "Truncated Data Sun Upper Transit: $SunUpperTransitTime" | logger

  SunSet=$(jq -r .properties.data.sundata[3].phen $JSON)
  SunSetTime=$(jq -r .properties.data.sundata[3].time $JSON)
  printf "JSON Data Sun Set: $SunSetTime" | logger
  SunSetTime=${SunSetTime:0:5}
  printf "Truncated Data Sun Set: $SunSetTime" | logger

  SunEndCivilTwilight=$(jq -r .properties.data.sundata[4].phen $JSON)
  SunEndCivilTwilightTime=$(jq -r .properties.data.sundata[4].time $JSON)
  printf "JSON Data Sun $SunEndCivilTwilight: $SunEndCivilTwilightTime" | logger
  SunEndCivilTwilightTime=${SunEndCivilTwilightTime:0:5}
  printf "Truncated Data Sun $SunEndCivilTwilight: $SunEndCivilTwilightTime" | logger

  # daylight amount

  # extract and convert time to hours
  SunRiseTimeHours=$((${SunRiseTime:0:2}))
  SunRiseTimeMins=$((${SunRiseTime:3:2}))
  printf "Sun Rise Time Hours: $SunRiseTimeHours" | logger
  printf "Sun Rise Time Mins: $SunRiseTimeMins" | logger

  # extract and convert time to mins
  SunSetTimeHours=$((${SunSetTime:0:2}))
  SunSetTimeMins=$((${SunSetTime:3:2}))
  printf "Sun Set Time Hours: $SunSetTimeHours" | logger
  printf "Sun Set Time Mins: $SunSetTimeMins" | logger

  # calculate sunlight amount
  SunHours=$((SunSetTimeHours - SunRiseTimeHours))
  if (($SunSetTimeMins > $SunRiseTimeMins)); then
  {
	SunMins=$(($SunSetTimeMins - $SunRiseTimeMins))
  }
  else
  {
	# account for set minute less than rise minute, offset by 60 mins to math right
	SunSetTimeMins=$(($SunSetTimeMins + 60))
	SunMins=$(($SunSetTimeMins - $SunRiseTimeMins))
  	SunHours=$(($SunHours - 1))
  }
  fi
  printf "Sun Hours: $SunHours" | logger
  printf "Sun Mins: $SunMins" | logger
  SunTotal=$SunHours"h"$SunMins"m"
  printf "Sun Total: $SunTotal" | logger

  # sun message body
  SunMessageBody=""
  SunMessageBody+="Today's Sun☀️"
  SunMessageBody+=$'\n'"Rise:$SunRiseTime"
  SunMessageBody+=$'\n'"Mid:$SunUpperTransitTime"
  SunMessageBody+=$'\n'"Set:$SunSetTime"
  SunMessageBody+=$'\n'"Total:$SunTotal"
  printf "Sun Message Body: $SunMessageBody" | logger

  # check how long the message is
  SunMessageBodyLength=${#SunMessageBody}
  printf "Sun Message Body Length: $SunMessageBodyLength" | logger

  # send today's sun data
  send_message_to_mesh "$SunMessageBody"

  printf "sun() ended" | logger
}
seasons()
{
  printf "seasons() started" | logger

  # basic variables
  local TODAYS_YEAR=$(date '+%Y')
  local TODAYS_DATE=$(date '+%Y-%m-%d')
  local FILE="seasons.json"
  local JSON=$DIR"/"$FILE

  # log all of the variables
  printf "TODAYS_YEAR: $TODAYS_YEAR" | logger
  printf "TODAYS_DATE: $TODAYS_DATE" | logger
  printf "DIR: $DIR" | logger
  printf "FILE: $FILE" | logger
  printf "JSON: $JSON" | logger
  printf "TZ: $TZ" | logger
  printf "DST: $DST" | logger
  printf "ID: $ID" | logger

  # Astronomical Applications API v4.0.1
  local URL="https://aa.usno.navy.mil/api/seasons?year=${TODAYS_YEAR}&tz=${TZ}&dst=${DST}&id=${ID}"
  printf "URL: $URL" | logger

  # get data
  curl -H "Accept: application/json" --silent $URL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  # json data
  Event0Phenom=$(jq -r .data[0].phenom $JSON)
  printf "JSON Data Event 0 Phenom: $Event0Phenom" | logger

  Event0Day=$(jq -r .data[0].day $JSON)
  printf "JSON Data Event 0 Day: $Event0Day" | logger

  Event0Month=$(jq -r .data[0].month $JSON)
  printf "JSON Data Event 0 Month: $Event0Month" | logger

  Event0Year=$(jq -r .data[0].year $JSON)
  printf "JSON Data Event 0 Year: $Event0Year" | logger

  Event0Time=$(jq -r .data[0].time $JSON)
  printf "JSON Data Event 0 Time: $Event0Time" | logger

  Event0Date=$Event0Year-$Event0Month-$Event0Day
  printf "Event 0 Date: $Event0Date" | logger

  Event0MessageBody="Today is the Perihelion, when the Earth is closest to the Sun"
  printf "Event 0 Message Body: $Event0MessageBody" | logger

  Event1Phenom=$(jq -r .data[1].phenom $JSON)
  printf "JSON Data Event 1 Phenom: $Event1Phenom" | logger

  Event1Day=$(jq -r .data[1].day $JSON)
  printf "JSON Data Event 1 Day: $Event1Day" | logger

  Event1Month=$(jq -r .data[1].month $JSON)
  printf "JSON Data Event 1 Month: $Event1Month" | logger

  Event1Year=$(jq -r .data[1].year $JSON)
  printf "JSON Data Event 1 Year: $Event1Year" | logger

  Event1Time=$(jq -r .data[1].time $JSON)
  printf "JSON Data Event 1 Time: $Event1Time" | logger

  Event1Date=$Event1Year-$Event1Month-$Event1Day
  printf "Event 1 Date: $Event1Date" | logger

  Event1MessageBody="Today is the Equinox, commonly known as Spring in the Northern and Autumn in the Southern Hemispheres"
  printf "Event 1 Message Body: $Event1MessageBody" | logger

  Event2Phenom=$(jq -r .data[2].phenom $JSON)
  printf "JSON Data Event 2 Phenom: $Event2Phenom" | logger

  Event2Day=$(jq -r .data[2].day $JSON)
  printf "JSON Data Event 2 Day: $Event2Day" | logger

  Event2Month=$(jq -r .data[2].month $JSON)
  printf "JSON Data Event 2 Month: $Event2Month" | logger

  Event2Year=$(jq -r .data[2].year $JSON)
  printf "JSON Data Event 2 Year: $Event2Year" | logger

  Event2Time=$(jq -r .data[2].time $JSON)
  printf "JSON Data Event 2 Time: $Event2Time" | logger

  Event2Date=$Event2Year-$Event2Month-$Event2Day
  printf "Event 2 Date: $Event2Date" | logger

  Event2MessageBody="Today is the Solstice, commonly known as Summer in the Northern and Winter in the Southern Hemispheres"
  printf "Event 2 Message Body: $Event2MessageBody" | logger

  Event3Phenom=$(jq -r .data[3].phenom $JSON)
  printf "JSON Data Event 3 Phenom: $Event3Phenom" | logger

  Event3Day=$(jq -r .data[3].day $JSON)
  printf "JSON Data Event 3 Day: $Event3Day" | logger

  Event3Month=$(jq -r .data[3].month $JSON)
  printf "JSON Data Event 3 Month: $Event3Month" | logger

  Event3Year=$(jq -r .data[3].year $JSON)
  printf "JSON Data Event 3 Year: $Event3Year" | logger

  Event3Time=$(jq -r .data[3].time $JSON)
  printf "JSON Data Event 3 Time: $Event3Time" | logger

  Event3Date=$Event3Year-$Event3Month-$Event3Day
  printf "Event 3 Date: $Event3Date" | logger

  Event3MessageBody="Today is the Aphelion, when the Earth is furthest from the Sun"
  printf "Event 3 Message Body: $Event3MessageBody" | logger

  Event4Phenom=$(jq -r .data[4].phenom $JSON)
  printf "JSON Data Event 4 Phenom: $Event4Phenom" | logger

  Event4Day=$(jq -r .data[4].day $JSON)
  printf "JSON Data Event 4 Day: $Event4Day" | logger

  Event4Month=$(jq -r .data[4].month $JSON)
  printf "JSON Data Event 4 Month: $Event4Month" | logger

  Event4Year=$(jq -r .data[4].year $JSON)
  printf "JSON Data Event 4 Year: $Event4Year" | logger

  Event4Time=$(jq -r .data[4].time $JSON)
  printf "JSON Data Event 4 Time: $Event4Time" | logger

  Event4Date=$Event4Year-$Event4Month-$Event4Day
  printf "Event 4 Date: $Event4Date" | logger

  Event4MessageBody="Today is the Equinoix, commonly known as Autumn in the Northern and Spring in the Southern Hemispheres"
  printf "Event 4 Message Body: $Event4MessageBody" | logger

  Event5Phenom=$(jq -r .data[5].phenom $JSON)
  printf "JSON Data Event 5 Phenom: $Event5Phenom" | logger

  Event5Day=$(jq -r .data[5].day $JSON)
  printf "JSON Data Event 5 Day: $Event5Day" | logger

  Event5Month=$(jq -r .data[5].month $JSON)
  printf "JSON Data Event 5 Month: $Event5Month" | logger

  Event5Year=$(jq -r .data[5].year $JSON)
  printf "JSON Data Event 5 Year: $Event5Year" | logger

  Event5Time=$(jq -r .data[5].time $JSON)
  printf "JSON Data Event 5 Time: $Event5Time" | logger

  Event5Date=$Event5Year-$Event5Month-$Event5Day
  printf "Event 5 Date: $Event5Date" | logger

  Event5MessageBody="Today is the Solstice, commonly known as Winter in the Northern and Summer in the Southern Hemispheres"
  printf "Event 5 Message Body: $Event5MessageBody" | logger

  # convert dates to UNIX time for comparison
  TodaysDate_Unix=$(date -d "$TODAYS_DATE" +"%s")
  printf "TodaysDate_Unix: $TodaysDate_Unix" | logger

  # override for testing messages 
  #TodaysDate_Unix=$(date -d "2025-12-21" +"%s")
  #printf "TodaysDate_Unix: $TodaysDate_Unix" | logger

  Event0Date_Unix=$(date -d "$Event0Date" +"%s")
  printf "Event0Date_Unix: $Event0Date_Unix" | logger
  Event1Date_Unix=$(date -d "$Event1Date" +"%s")
  printf "Event1Date_Unix: $Event1Date_Unix" | logger
  Event2Date_Unix=$(date -d "$Event2Date" +"%s")
  printf "Event2Date_Unix: $Event2Date_Unix" | logger
  Event3Date_Unix=$(date -d "$Event3Date" +"%s")
  printf "Event3Date_Unix: $Event3Date_Unix" | logger
  Event4Date_Unix=$(date -d "$Event4Date" +"%s")
  printf "Event4Date_Unix: $Event4Date_Unix" | logger
  Event5Date_Unix=$(date -d "$Event5Date" +"%s")
  printf "Event5Date_Unix: $Event5Date_Unix" | logger

  # send today's seasonal data
  if [ $TodaysDate_Unix == $Event0Date_Unix ]; then
  {
	  printf "Event Message Body: $Event0MessageBody" | logger
	  send_message_to_mesh "$Event0MessageBody"
  }
  elif [ $TodaysDate_Unix == $Event1Date_Unix ]; then
  {
	  printf "Event Message Body: $Event1MessageBody" | logger
	  send_message_to_mesh "$Event1MessageBody"
  }
  elif [ $TodaysDate_Unix == $Event2Date_Unix ]; then
  {
	  printf "Event Message Body: $Event2MessageBody" | logger
          send_message_to_mesh "$Event2MessageBody"
  }
  elif [ $TodaysDate_Unix == $Event3Date_Unix ]; then
  {
	  printf "Event Message Body: $Event3MessageBody" | logger
          send_message_to_mesh "$Event3MessageBody"
  }
  elif [ $TodaysDate_Unix == $Event4Date_Unix ]; then
  {
	  printf "Event Message Body: $Event4MessageBody" | logger
          send_message_to_mesh "$Event4MessageBody"
  }
  elif [ $TodaysDate_Unix == $Event5Date_Unix ]; then
  {
	  printf "Event Message Body: $Event5MessageBody" | logger
          send_message_to_mesh "$Event5MessageBody"
  }
  else
  {
          printf "no seasonal change today :(" | logger
  }
  fi

  printf "seasons() ended" | logger
}
daylight_savings()
{
  printf "daylight_savings() started" | logger

  # basic variables
  local TODAYS_YEAR=$(date '+%Y')
  local FILE="daylight_savings.json"
  local JSON=$DIR"/"$FILE

  # log all of the variables
  printf "TODAYS_YEAR: $TODAYS_YEAR" | logger
  printf "DIR: $DIR" | logger
  printf "FILE: $FILE" | logger
  printf "JSON: $JSON" | logger
  printf "ID: $ID" | logger

  # Astronomical Applications API v4.0.1
  local URL="https://aa.usno.navy.mil/api/daylightsaving?year=${TODAYS_YEAR}&id=${ID}"
  printf "URL: $URL" | logger

  # get data
  curl -H "Accept: application/json" --silent $URL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  # json data
  Event0Event=$(jq -r .data[0].event $JSON)
  printf "JSON Data Event 0 Event: $Event0Event" | logger

  Event0Day=$(jq -r .data[0].day $JSON)
  printf "JSON Data Event 0 Day: $Event0Day" | logger

  Event0Month=$(jq -r .data[0].month $JSON)
  printf "JSON Data Event 0 Month: $Event0Month" | logger

  Event0Year=$(jq -r .data[0].year $JSON)
  printf "JSON Data Event 0 Year: $Event0Year" | logger

  Event0Date=$Event0Year-$Event0Month-$Event0Day
  printf "Event 0 Date: $Event0Date" | logger

  Event0MessageBody="Today is the beginning of Daylight Savings - Spring Forward, set your clocks 1 hour forward"
  printf "Event 0 Message Body: $Event0MessageBody" | logger

  Event1Event=$(jq -r .data[1].event $JSON)
  printf "JSON Data Event 1 Event: $Event1Event" | logger

  Event1Day=$(jq -r .data[1].day $JSON)
  printf "JSON Data Event 1 Day: $Event1Day" | logger

  Event1Month=$(jq -r .data[1].month $JSON)
  printf "JSON Data Event 1 Month: $Event1Month" | logger

  Event1Year=$(jq -r .data[1].year $JSON)
  printf "JSON Data Event 1 Year: $Event1Year" | logger

  Event1Date=$Event1Year-$Event1Month-$Event1Day
  printf "Event 1 Date: $Event1Date" | logger

  Event1MessageBody="Today is the ending of Daylight Savings - Fall Back, set your clocks 1 hour backward"
  printf "Event 1 Message Body: $Event1MessageBody" | logger

  # convert dates to UNIX time for comparison
  TodaysDate_Unix=$(date -d "$TODAYS_DATE" +"%s")
  printf "TodaysDate_Unix: $TodaysDate_Unix" | logger

  # override for testing messages 
  #TodaysDate_Unix=$(date -d "2025-11-02" +"%s")
  #printf "TodaysDate_Unix: $TodaysDate_Unix" | logger

  Event0Date_Unix=$(date -d "$Event0Date" +"%s")
  printf "Event0Date_Unix: $Event0Date_Unix" | logger
  Event1Date_Unix=$(date -d "$Event1Date" +"%s")
  printf "Event1Date_Unix: $Event1Date_Unix" | logger

  # send today's daylight savings data
  if [ $TodaysDate_Unix == $Event0Date_Unix ]; then
  {
          send_message_to_mesh "$Event0MessageBody"
  	  printf "Event Message Body: $Event0MessageBody" | logger
  }
  elif [ $TodaysDate_Unix == $Event1Date_Unix ]; then
  {
          send_message_to_mesh "$Event1MessageBody"
    	  printf "Event Message Body: $Event1MessageBody" | logger
  }
  else
  {
          printf "no daylight savings change today :)" | logger
  }
  fi

  printf "daylight_savings() ended" | logger
}
eclipse()
{
  printf "eclipse() started" | logger

  # basic variables
  local TODAYS_YEAR=$(date '+%Y')
  local FILE="eclipse.json"
  local JSON=$DIR"/"$FILE

  # log all of the variables
  printf "TODAYS_YEAR: $TODAYS_YEAR" | logger
  printf "DIR: $DIR" | logger
  printf "FILE: $FILE" | logger
  printf "JSON: $JSON" | logger
  printf "ID: $ID" | logger

  # Astronomical Applications API v4.0.1
  local URL="https://aa.usno.navy.mil/api/eclipses/solar/year?year=${TODAYS_YEAR}&id=${ID}"
  printf "URL: $URL" | logger

  # get data
  curl -H "Accept: application/json" --silent $URL > $JSON | logger

  # ensure json is valid
  jq empty $JSON | logger

  # json data
  Event0Event=$(jq -r .eclipses_in_year[0].event $JSON)
  printf "JSON Data Event 0 Event: $Event0Event" | logger

  Event0Day=$(jq -r .eclipses_in_year[0].day $JSON)
  printf "JSON Data Event 0 Day: $Event0Day" | logger

  Event0Month=$(jq -r .eclipses_in_year[0].month $JSON)
  printf "JSON Data Event 0 Month: $Event0Month" | logger

  Event0Year=$(jq -r .eclipses_in_year[0].year $JSON)
  printf "JSON Data Event 0 Year: $Event0Year" | logger

  Event0Date=$Event0Year-$Event0Month-$Event0Day
  printf "Event 0 Date: $Event0Date" | logger

  Event1Event=$(jq -r .eclipses_in_year[1].event $JSON)
  printf "JSON Data Event 1 Event: $Event1Event" | logger

  Event1Day=$(jq -r .eclipses_in_year[1].day $JSON)
  printf "JSON Data Event 1 Day: $Event1Day" | logger

  Event1Month=$(jq -r .eclipses_in_year[1].month $JSON)
  printf "JSON Data Event 1 Month: $Event1Month" | logger

  Event1Year=$(jq -r .eclipses_in_year[1].year $JSON)
  printf "JSON Data Event 1 Year: $Event1Year" | logger

  Event1Date=$Event1Year-$Event1Month-$Event1Day
  printf "Event 1 Date: $Event1Date" | logger

  # convert dates to UNIX time for comparison
  TodaysDate_Unix=$(date -d "$TODAYS_DATE" +"%s")
  printf "TodaysDate_Unix: $TodaysDate_Unix" | logger

  # override for testing messages 
  #TodaysDate_Unix=$(date -d "2025-11-02" +"%s")
  #printf "TodaysDate_Unix: $TodaysDate_Unix" | logger

  Event0Date_Unix=$(date -d "$Event0Date" +"%s")
  printf "Event0Date_Unix: $Event0Date_Unix" | logger
  Event1Date_Unix=$(date -d "$Event1Date" +"%s")
  printf "Event1Date_Unix: $Event1Date_Unix" | logger

  # send today's daylight savings data
  if [ $TodaysDate_Unix == $Event0Date_Unix ]; then
  {
          send_message_to_mesh "$Event0Event"
          printf "Event Message Body: $Event0Event" | logger
  }
  elif [ $TodaysDate_Unix == $Event1Date_Unix ]; then
  {
          send_message_to_mesh "$Event1Event"
          printf "Event Message Body: $Event1Event" | logger
  }
  else
  {
          printf "no eclipses today :(" | logger
  }
  fi

  printf "eclipse() ended" | logger
}
# begin script
LogBegin=$(date '+%Y-%m-%d %H:%M:%S')
printf "+------------------------------------+" | logger
printf "| BEGIN $LogBegin          |" | logger
printf "+------------------------------------+" | logger

check_dependencies
moon LAT LON
sun LAT LON
seasons
daylight_savings
eclipse

LogEnd=$(date '+%Y-%m-%d %H:%M:%S')
printf "+------------------------------------+" | logger
printf "|   END $LogEnd          |" | logger
printf "+------------------------------------+" | logger

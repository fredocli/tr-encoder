#!/usr/local/bin/bash
PREFIX="play"
FF_FORMAT="mov"
PLAY_SIZE="_4"

FF_WIDTH=400
FF_HEIGHT=226

FF_FPS=24

FF_VBITRATE=450

FF_AB=96
FF_AC=2
FF_AR=44100

   

FF_PASS=2

if [[ $EVALUTE == 1 && $EVALUATION == 0 ]]
then

### evalute only once or encode

evaluation_ini

### check the evolution of the encoding

elif [[ $EVALUTE == 1 && $EVALUATION -gt 0 ]]
then

evaluation_check

else

### encode the video

. "$APP_DIR/formats/$PREFIX-$FF_FORMAT.sh" 

fi
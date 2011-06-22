#!/usr/local/bin/bash

PREFIX="play"
FF_FORMAT="flv"
PLAY_SIZE="_3"

FF_WIDTH=320
FF_HEIGHT=180
FF_FPS=20
FF_VBITRATE=270

FF_AB=48
FF_AC=2
FF_AR=44100

FF_PASS=2
MPLAYER_SUB=" -subfont-text-scale 2.5  -sub-bg-color 0 -sub-bg-alpha 150 -font ${SUB_DIRECTORY}/arial.ttf -utf8 "




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
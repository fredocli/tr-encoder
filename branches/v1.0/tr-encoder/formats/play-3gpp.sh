#!/usr/local/bin/bash

	### display the format ### 

	echo -e "\\n${BLUE}$(box "format: $PREFIX-$FF_FORMAT-$PLAY_SIZE")${NC}"
	
	
	### Start timer ###

	TIME_START=$(date +%s)


	### Create the logo or logos ###

    add_logo 
    

	### Check the sub ###
        
    check_sub


	### Calculate the padding for ffmpeg ###
	
	calculate_padding  


	### Create audio.wav ###
	
	dump_audio

	
	### create audio ###
	
	if [[ $OVERWRITE == 0 && -f "${DIRECTORY}/$SUBDIR/audio_${FF_AB}_${FF_AC}_$FF_AR.aac" ]]
	then
			echo -e "${yellow}# Create audio_${FF_AB}_${FF_AC}_$FF_AR.aac ${NC}"		
			echo -e "${green}# This file (audio_${FF_AB}_${FF_AC}_$FF_AR.aac) already exit. We going to use it${NC}"	

	else



			  ### check if resample 8bit to 16 is needed  (sox)
			  # resample_audio
			  
			  ### create audio_${FF_AB}_${FF_AC}_$FF_AR.amr

			  echo -e "${yellow}#Create audio_${FF_AB}_${FF_AC}_$FF_AR.aac ${NC}"
			  COMMAND="${FFMPEG}  -i ${DIRECTORY}/$SUBDIR/audio.wav -v 0 -ss  $SS  -ar $FF_AR -ab ${FF_AB}k -ac $FF_AC  -y ${DIRECTORY}/${SUBDIR}/audio_${FF_AB}_${FF_AC}_$FF_AR.aac"
			  [[ $DEBUG -gt 1 ]] && QUEIT=""  || QUEIT="  2>/dev/null"
			  eval "$COMMAND $QUEIT" && echo -e ${green}$COMMAND$QUEIT${NC} ||  echo -e ${red}$COMMAND${NC}

	fi
	
	
	

	
	
	### Change to the video directory  ( to avoid the x264_2pass.log issue ) ###

	PWD=$(pwd)
	cd ${DIRECTORY}/${SUBDIR}/
	
	
	
	
	
	
	### Create the video ###
	
	if [[  $FFMPEG_VIDEO == 0 ]]
	then
		### pipe mplayer rawvideo to ffmpeg
		
		echo -e "${red}# Resample video${NC}"
		#COMMAND="${FFMPEG} -v 0 $DEINTERLACE -r   $FPS -f yuv4mpegpipe -i ${DIRECTORY}/$SUBDIR/${OUTPUT}.yuv -b 900k $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT} -r 24  $VHOOK    -y ${DIRECTORY}/${SUBDIR}/${OUTPUT}.flv"
		#[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  2>/dev/null"
 		#eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC}
	else
	
		 PADTOP=$(echo "$PADTOP + 22"|bc)
		 PADBOTTOM=$(echo "$PADBOTTOM + 22"|bc)
	     FF_PAD="-padtop $PADTOP -padbottom $PADBOTTOM "
		 echo -e "${yellow}# Adding 2*22 px to the video: $FF_PAD ${NC}"

		
		if [[ $FF_PASS == 2 ]]
		then
		

		
		### create video_${FF_WIDTH}x${FF_HEIGHT}.h264
		
		echo -e "${yellow}# Create the video_${FF_WIDTH}x${FF_HEIGHT}_${FF_FPS}_${FF_VBITRATE}.h264 ${NC}"
		
		echo -e "${yellow}# pass 1 ${NC}"
		
		INPUT_VIDEO=$INPUT 
		[[ ! -z $SUB_FILE ]] && burn_subtitle		

		COMMAND="${FFMPEG} -threads $THREAD -i  ${INPUT_VIDEO} -an -b ${FF_VBITRATE}k -passlogfile /tmp/${OUTPUT}.log -pass 1 -vcodec libx264 $FF_PRESET1  $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT_BP}   $VHOOK  -r $FF_FPS  -ss $SS  -f $FF_FORMAT -aspect 16:9  -y /dev/null "
		[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  2>/dev/null"
		eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC}
		
		echo -e "${yellow}# pass 2 ${NC}"
		

		[[ ! -z $SUB_FILE ]] && burn_subtitle		

		COMMAND="${FFMPEG} -threads $THREAD -i  ${INPUT_VIDEO} -an -b ${FF_VBITRATE}k -passlogfile /tmp/${OUTPUT}.log -pass 2 -vcodec libx264 $FF_PRESET2 $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT_BP}   $VHOOK  -r $FF_FPS -ss $SS  -f $FF_FORMAT -y  ${DIRECTORY}/${SUBDIR}/video_${FF_WIDTH}x${FF_HEIGHT}_${FF_FPS}_${FF_VBITRATE}.h264"
		[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  2>/dev/null"
		eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC}

		else 
		
		echo -e "${yellow}# Only one pass ${NC}"
		
		INPUT_VIDEO=$INPUT 
		[[ ! -z $SUB_FILE ]] && burn_subtitle

		COMMAND="${FFMPEG} -threads $THREADS -i  ${INPUT_VIDEO} -an -b ${FF_VBITRATE}k -vcodec libx264 $FF_PRESET2 $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT_BP}   $VHOOK  -r $FPS -ss $SS  -f $FF_FORMAT -y  ${DIRECTORY}/${SUBDIR}/video_${FF_WIDTH}x${FF_HEIGHT}_${FF_FPS}_${FF_VBITRATE}.h264"
		[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  2>/dev/null"
		eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC}
		fi
	
	fi


	

	### Remux the sound and the video MP4Box
	
	echo -e "${yellow}# Remux sound and video with MP4Box${NC}"
	COMMAND="${MP4BOX} -fps $FF_FPS  -add ${DIRECTORY}/$SUBDIR/video_${FF_WIDTH}x${FF_HEIGHT}_${FF_FPS}_${FF_VBITRATE}.h264 -add ${DIRECTORY}/$SUBDIR/audio_${FF_AB}_${FF_AC}_$FF_AR.aac -3gp -new ${DIRECTORY}/${SUBDIR}/${OUTPUT}${PLAY_SIZE}.${FF_FORMAT}"
	[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  >/dev/null"
	eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC} 

	
	### clean up
	
	[[ -f  ${DIRECTORY}/${SUBDIR}/test.jpg ]] && rm  ${DIRECTORY}/${SUBDIR}/test.jpg
	[[ -f  ${DIRECTORY}/${SUBDIR}/test.mp3 ]] && rm  ${DIRECTORY}/${SUBDIR}/test.mp3
	[[ ! -z $SUB_FILE && -f "$FIFO" ]] && rm  "$FIFO"	      
	  
		 
	### check the file 
	[[ $DEBUG -gt 0 ]] && echo -e "${cyan}`box "Control output file"`${NC}"
	FILE_INFOS=""
	get_file_infos "${DIRECTORY}/$SUBDIR/${OUTPUT}${PLAY_SIZE}.${FF_FORMAT}"

	if [[  $? == 0 ]]
	then 
	echo -e "${GREEN}${DIRECTORY}/$SUBDIR/${OUTPUT}${PLAY_SIZE}.${FF_FORMAT} ${NC}"
	[[ $DEBUG -gt 1 ]] && echo -e "$FILE_INFOS" ||echo -e "$FILE_INFOS" >>  "${DIRECTORY}/$SUBDIR/sample.up"

	### stop timer

	TIME_END=$(date +%s)

	### calculate duration

	let "ENCODING_DURATION=$TIME_END - $TIME_START"

	### quit timer infos to log files (for evaluation)

	logTimer

	else
	echo -e "${RED}$FILE_INFOS${NC}"		
	fi
	
	# Go back to the pwd ( to avoid the x264_2pass.log issue ) ###
	cd $PWD
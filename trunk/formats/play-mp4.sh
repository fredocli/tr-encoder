#!/usr/local/bin/bash

	### start timer

	TIME_START=$(date +%s)

	### display the format 

	echo -e "\\n${BLUE}$(box "format: $PREFIX-$FF_FORMAT-$PLAY_SIZE")${NC}"

	### create the logo or logos 

        add_logo 

	THREADS=1

	### change of directory  ( to avoid the x264_2pass.log issue )

	PWD=$(pwd)
	cd ${DIRECTORY}/${SUBDIR}/

	### Recalculate the padding
	
       if [[ ! -z $FF_PAD ]]
           then

           PAD=`echo "scale=3;(($FF_WIDTH / 1.777 ) - ($FF_WIDTH / $RATIO )) / 2"|bc`
           PAD=`round2 $PAD`
           FF_PAD=" -padtop $PAD -padbottom $PAD "
		 echo -e "${yellow}# Recalculate the padding  ${NC}"	
		 echo -e "${green}# $FF_PAD ${NC}"

        fi   
	
	### Recalculate the FF_HEIGHT_BP 
	
	FF_HEIGHT_BP=$( echo "${FF_HEIGHT} - ( 2*${PAD} )"|bc)
	echo -e "${yellow}# Recalculate the FF_HEIGHT_BP  ${NC}"	
	echo -e "${green}# FF_HEIGHT_BP=$FF_HEIGHT_BP ${NC}"
		

        ### Create audio.wav
	



	   

	   if [[ $CHANNELS == 6 && $FF_AC == 6 ]]
	   then
	   
			 ### Create audio_ch6.wav
			 
		 
	   
			 echo -e "${yellow}# create audio_${FF_AC}.wav ${NC}"
			 if [[ $OVERWRITE == 0 && -f "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav" ]]
			 then

			 echo -e "${green}# This file already exit.We going to use it${NC}"

			 else

			 COMMAND="mplayer -ao pcm:fast:waveheader:file=${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav -channels 6 -vc null -vo null  ${INPUT}"
			 [[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET=" >/dev/null  2>&1"
			 eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC} 

				  ### check the size audio.wav

				  if [[ -f "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav" &&  $SYSTEM == "Linux" ]]
				  then
				  RESULTS_SIZE=`stat -c '%s' "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav"` 
				  elif [[ -f "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav" && $SYSTEM == "FreeBSD" ]] 
				  then
				  RESULTS_SIZE=`stat -f '%z' "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav"`
				  fi

				  ### try one more time if failed

				  if [ "$RESULTS_SIZE" -lt 1014000 ]
				  then
				  echo -e "${yellow}# create audio.wav ${NC}"		
				  COMMAND="mplayer -ao pcm:fast:waveheader:file=${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav -channels 6  -vc dummy -vo null ${INPUT}"
				  [[ $DEBUG -gt 1 ]] && QUEIT=""  || QUEIT=" > /dev/null  2>&1"
				  eval "$COMMAND $QUEIT" && echo -e ${green}$COMMAND$QUEIT${NC} ||  echo -e ${red}$COMMAND${NC} 
				  fi
			 fi

	   else
	   
		    # change some values if the input video is not 6 channels 
	         [[ $FF_AC == 6 ]] &&  FF_AC=2 && FF_AB=$(echo "$FF_AB / 3" |bc)
		    
	   
			 ### Create audio.wav

			 echo -e "${yellow}# Create audio_${FF_AC}.wav ${NC}"

			 if [[ $OVERWRITE == 0 && -f "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav" ]]
			 then

				echo -e "${green}# This file (audio.wav) already exit.We going to use it${NC}"

			 else

				COMMAND="mplayer -ao pcm:fast:waveheader:file=${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav -vc null -vo null ${INPUT}"
				[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET=" > /dev/null  2>&1"
				eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC} 

				  ### check the size audio.wav

				  if [[ -f "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav" &&  $SYSTEM == "Linux" ]]
				  then
				  RESULTS_SIZE=`stat -c '%s' "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav"` 
				  elif [[ -f "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav" && $SYSTEM == "FreeBSD" ]] 
				  then
				  RESULTS_SIZE=`stat -f '%z' "${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav"`
				  fi

				  ### try one more time if failed

				  if [ "$RESULTS_SIZE" -lt 1014000 ]
				  then
				  echo -e "${yellow}# create audio.wav ${NC}"		
				  COMMAND="mplayer -ao pcm:fast:waveheader:file=${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav -vc dummy -vo null ${INPUT}"
				  [[ $DEBUG -gt 1 ]] && QUEIT=""  || QUEIT=" > /dev/null  2>&1"
				  eval "$COMMAND $QUEIT" && echo -e ${green}$COMMAND$QUEIT${NC} ||  echo -e ${red}$COMMAND${NC} 
				  fi





			 fi	
	   fi	    
		   
		

		
		
		
	### create audio_${FF_AB}_${FF_AC}_$FF_AR.aac
	
	echo -e "${yellow}# Create audio_${FF_AB}_${FF_AC}_$FF_AR.aac ${NC}"
	if [[ $OVERWRITE == 0 && -f "${DIRECTORY}/$SUBDIR/audio_${FF_AB}_${FF_AC}_$FF_AR.aac" ]]
	then
	
		echo -e "${green}# This file already exit. We going to use it${NC}"		

	else
		### Resample Audio

		resample_audio

		### Create Audio 

		COMMAND="${FFMPEG}  -i ${DIRECTORY}/$SUBDIR/audio_${FF_AC}.wav -v 0 -ss  $SS  -ar $FF_AR -ab ${FF_AB}k -ac $FF_AC  -y ${DIRECTORY}/${SUBDIR}/audio_${FF_AB}_${FF_AC}_$FF_AR.aac"
		[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  2>/dev/null"
		eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND $QUIET${NC} ||  echo -e ${red}$COMMAND${NC} 
	

	fi
	
	
	
	### create the video
	
	if [[  $FFMPEG_VIDEO == 0 ]]
	then
		### pipe mplayer rawvideo to ffmpeg
		
		echo -e "${red}# Resample video${NC}"
		#COMMAND="${FFMPEG} -v 0 $DEINTERLACE -r   $FPS -f yuv4mpegpipe -i ${DIRECTORY}/$SUBDIR/${OUTPUT}.yuv -b 900k $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT}   $VHOOK  -ss $SS  -y ${DIRECTORY}/${SUBDIR}/${OUTPUT}.flv"
		#[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  2>/dev/null"
		#eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC}
	else
	
		### create video_${FF_WIDTH}x${FF_HEIGHT}.h264
		
		echo -e "${yellow}# Create the video_${FF_WIDTH}x${FF_HEIGHT}_${FF_FPS}_${FF_VBITRATE}.h264 ${NC}"
		
		echo -e "${yellow}# pass 1 ${NC}"
		COMMAND="${FFMPEG} -threads $THREADS -i  ${INPUT} -an   -b ${FF_VBITRATE}k -passlogfile /tmp/${OUTPUT}.log -pass 1 -vcodec libx264 $FF_PRESET1  $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT_BP}   $VHOOK  -ss $SS  -f $FF_FORMAT -aspect 16:9  -y /dev/null "
		[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  2>/dev/null"
		eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC}
		
		echo -e "${yellow}# pass 2 ${NC}"
		COMMAND="${FFMPEG} -threads $THREADS -i  ${INPUT} -an  $DEINTERLACE -b ${FF_VBITRATE}k -passlogfile /tmp/${OUTPUT}.log -pass 2 -vcodec libx264 $FF_PRESET2 $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT_BP}   $VHOOK  -r $FPS -ss $SS  -f $FF_FORMAT -aspect 16:9  -y  ${DIRECTORY}/${SUBDIR}/video_${FF_WIDTH}x${FF_HEIGHT}_${FF_FPS}_${FF_VBITRATE}.h264"
		[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  2>/dev/null"
		eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC}
	
	fi


	

	### Remux the sound and the video MP4Box
	
	echo -e "${yellow}# Remux sound and video with MP4Box${NC}"
	COMMAND="${MP4BOX} -fps $FF_FPS  -add ${DIRECTORY}/$SUBDIR/video_${FF_WIDTH}x${FF_HEIGHT}_${FF_FPS}_${FF_VBITRATE}.h264 -add ${DIRECTORY}/$SUBDIR/audio_${FF_AB}_${FF_AC}_$FF_AR.aac ${DIRECTORY}/${SUBDIR}/video_tmp.${FF_FORMAT}"
	[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  >/dev/null"
	eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC} 
	
	
	### Use AtomicParsley
	echo -e "${yellow}# add some tags${NC}"
	COMMAND="AtomicParsley \"${DIRECTORY}/${SUBDIR}/video_tmp.${FF_FORMAT}\" --metaEnema  --copyright \"\"   --artist \"\"  --title \"\"   --comment \"Encoded and delivered by previewnetworks.com\" -o \"${DIRECTORY}/${SUBDIR}/${OUTPUT}${PLAY_SIZE}.${FF_FORMAT}\" --freefree --overWrite"
	[[ $DEBUG -gt 1 ]] && QUIET=""  || QUIET="  >/dev/null"
	eval "$COMMAND $QUIET" && echo -e ${green}$COMMAND$QUIET${NC} ||  echo -e ${red}$COMMAND${NC} 
	
	
	### clean up
	
	echo -e "${yellow}# clean up${NC}"
	
	[[ -f  ${DIRECTORY}/${SUBDIR}/video_tmp.${FF_FORMAT} ]] && rm  ${DIRECTORY}/${SUBDIR}/video_tmp.${FF_FORMAT}
	[[ -f  ${DIRECTORY}/${SUBDIR}/test.jpg ]] && rm  ${DIRECTORY}/${SUBDIR}/test.jpg
	[[ -f  ${DIRECTORY}/${SUBDIR}/test.mp3 ]] && rm  ${DIRECTORY}/${SUBDIR}/test.mp3
		      
	  
	### check the file 
	
	[[ $DEBUG -gt 0 ]] && echo -e "${cyan}`box "Control output file"`${NC}"
	FILE_INFOS=""
	get_file_infos "${DIRECTORY}/$SUBDIR/${OUTPUT}${PLAY_SIZE}.${FF_FORMAT}"

	if [[  $? == 0 ]]
	then 
	echo -e "${GREEN}${DIRECTORY}/$SUBDIR/${OUTPUT}${PLAY_SIZE}.${FF_FORMAT} ${NC}"
	[[ $DEBUG -gt 1 ]] && echo -e "$FILE_INFOS" ||echo -e "$FILE_INFOS" >  "${DIRECTORY}/$SUBDIR/sample.up"

		### stop timer

		TIME_END=$(date +%s)

		### calculate duration

		let "ENCODING_DURATION=$TIME_END - $TIME_START"

		### quit timer infos to log files (for evaluation)

		logTimer


	else
	echo -e "${RED}$FILE_INFOS${NC}"		
	fi
	
	# go back in the pwd ( to avoid the x264_2pass.log issue )
	cd $PWD
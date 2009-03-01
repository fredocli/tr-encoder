#!/bin/bash
DEBUG=0
DISPLAY=0
OVERWRITE=0
CROPDETECTION=1
TRY=""

EXTENTION="org"
#EXTENTION="VOB"


Vert='\[\033[1;32m' 

# Define some colors first:
BLACK='\e[0;30m'

red='\e[0;31m'
RED='\e[1;31m'

green='\e[0;32m'
GREEN='\e[1;32m'

yellow='\e[0;33m'
YELLOW='\e[1;33m'

blue='\e[0;34m'
BLUE='\e[1;34m'

pink='\e[0;35m'
PINK='\e[1;35m'

cyan='\e[0;36m'
cyan='\e[1;36m'

# 37 With

NC='\e[0m' # No Color


# Set up reasonable defaults.
APPNAME=`basename "$0"`
CONFNAME=."$APPNAME"rc

# Import configuration file, possibly overriding defaults.
[ -r ~/"$CONFNAME" ] && . ~/"$CONFNAME"

# minimum duration of the video 
MINIMUM_DURATION=12


# minimum general biterate accepted
MINIMUM_BITERATE=500000
# minimum video biterate accepted
MINIMUM_VBITERATE=446000
# minimum Audio biterate accepted
MINIMUM_ABITERATE=64000


# qualite minimun de l'image
MINIMUM_BPF=0.06
# number of frames for the crop detection
CROP_FRAMES_S=250
CROP_FRAMES_L=500


MAXSIZE=480
FPS=12000/1001
    usage() {
	echo >&2 "Usage: `basename $0` [-f jpeg|sample|normal] [-d] [file|folder]"
    }

    while getopts "f:T:c:DydY" option
    do
	case "$option" in
	c)	   CROPDETECTION=$OPTARG;;	
	d)      DISPLAY=1;;	
	D)      DEBUG=1;;
	y)      OVERWRITE=1;;
	Y)      OVERWRITE=2;;
	f)      OUTPUT_FORMAT="$OPTARG";;
	T)	   TRY="${OPTARG}-";;
	[?])    usage
		exit 1;;
	esac
    done
    shift $(($OPTIND - 1))




timeout(){
command=$1
# run $command in background, sleep for our timeout then kill the process if it is running
$command &
pid=$!
echo "sleep $2; kill $pid" | at now
wait $pid &> /dev/null
if [ $? -eq 143 ]; then
echo "WARNING - command was terminated - timeout of $2 secs reached ($pid)$?."
echo
fi
}


    round16 () {
	echo "("$1" + 8) / 16 * 16" | bc
    }

    round8 () {
	echo "("$1" + 4) / 8 * 8" | bc
    }

    round2 () {
	echo "("$1" + 1) / 2 * 2" | bc
    }

    floor2 () {
	echo "("$1" ) / 2 * 2" | bc
    }

get_vbitrate_mplayer () {	
# Return VBITERATE_MPLAYER=VBITERATE_MPLAYER=4324320   or  (90 %  $BITERATE_CALC )

#echo "get the video bitrate from mplayer"
VBITERATE_MPLAYER=`mplayer  $INPUT  -frames 1 -identify -quiet -vo null -ao null  2>&1 |grep  "ID_VIDEO_BITRATE=" |tail -1`   
VBITERATE_MPLAYER=${VBITERATE_MPLAYER#ID_VIDEO_BITRATE=}

		# check the value != null
		
		if [[ -z $VBITERATE_MPLAYER || $VBITERATE_MPLAYER == 0 ]] 
		then
		VBITERATE_MPLAYER=`echo "$BITERATE_CALC  * 100 / 90" |bc`
		fi


#echo "VBITERATE_MPLAYER=$VBITERATE_MPLAYER"
}


get_abitrate_mplayer () {	      
#echo  get the audio bitrate from mplayer
ABITERATE_MPLAYER=`mplayer  $INPUT  -frames 1 -identify -quiet -vo null -ao null  2>&1 |grep  "ID_AUDIO_BITRATE=" |tail -1`   ABITERATE_MPLAYER=${ABITERATE_MPLAYER#ID_AUDIO_BITRATE=}

		# check the value != null
		
		if [[   -z $ABITERATE_MPLAYER ||  $VBITERATE_MPLAYER == 0 ]] 
		then
		ABITERATE_MPLAYER=0
		fi

#echo "ABITERATE_MPLAYER=$ABITERATE_MPLAYER"
}


get_fps_mplayer () {	

# get the FPS from mplayer
FPS_MPLAYER=`mplayer  $INPUT  -frames 1 -identify -quiet -vo null -ao null  2>&1 |grep  "ID_VIDEO_FPS=" |tail -1`   
FPS_MPLAYER=${FPS_MPLAYER#ID_VIDEO_FPS=}
#echo "FPS_MPLAYER=$FPS_MPLAYER"
}


get_duration_mplayer () {	
# return  DURATION_MPLAYER=0 or DURATION_MPLAYER=345.78

# echo " get the DURATION from mplayer"
DURATION_MPLAYER=`mplayer  $INPUT  -frames 1 -identify -quiet -vo null -ao null  2>&1 |grep  "ID_LENGTH=" |tail -1`   

		# check the value != null
		if [[  ! -z $DURATION_MPLAYER ||  $DURATION_MPLAYER != 0 ]] 
		then
		DURATION_MPLAYER=${DURATION_MPLAYER#ID_LENGTH=}
		else
		DURATION_MPLAYER=0
		fi

#echo "DURATION_MPLAYER=$DURATION_MPLAYER"
}


get_general_infos () {	      
	      GENERAL_INFOS=""
	      FORMAT=""
	      FILE_SIZE=0
	      DURATION=0
	      BITERATE=0
	      VIDEO_COUNT=0
	      VIDEO_COUNT=0
	      
	      echo -e "\\n${BLUE}# General informations${NC}"

	     # get some general info about the video
	      GENERAL_INFOS=`mediainfo "--Inform=General;FORMAT='%Format%' FILE_SIZE=%FileSize% DURATION=%Duration% BITERATE=%OverallBitRate% VIDEO_COUNT=%VideoCount% AUDIO_COUNT=%AudioCount%" ${INPUT}`
	      #echo "$GENERAL_INFOS"
	      eval "$GENERAL_INFOS"


	      # display the file name and the size
	      
	      echo -e "$INPUT\\t` echo "$FILE_SIZE / 1024 /1024 "| bc `MB\\n"
		 
		 
		 
		 
		 
		 # check if the video codec is supPorted by ffmpeg
		 
		FFMPEG_TEST=`ffmpeg -i "$INPUT" -sameq -vframes 1 -y "${DIRECTORY}/${SUBDIR}/test.jpg" 2>&1 `   
		#echo "$FFMPEG_TEST"
		
		 FFMPEG_TAIL="`echo "$FFMPEG_TEST"|tail  -n 1   `"	
		 FFMPEG_HEAD="`echo "$FFMPEG_TEST"| head -25 `"
		 FFMPEG_YES=`echo "$FFMPEG_TAIL"|grep -o "^video:[1-9][0-9]*kB" `
				if [[ ! -z $FFMPEG_YES ]]
				then
				echo -e "${GREEN}Video codec supported by ffmpeg${NC} "
				#echo $FFMPEG_YES
				else
				
				ERROR="ERROR: Video codec not supported by ffmpeg"

						if [[ $DEBUG == 1 ]]
						then

						echo "$FFMPEG_HEAD"
						fi 

				echo -e "${RED}${ERROR}${NC}\\n${FFMPEG_TAIL}"
				echo -e ${ERROR} ${FFMPEG_HEAD}  >> ${DIRECTORY}/${OUTPUT}.err    
				
				
				fi
				
				
				
		 
		 # check if the video codec is supPorted by ffmpeg
		 
		FFMPEG_TEST=`ffmpeg -i "$INPUT" -t 1 -ac 2 -y "${DIRECTORY}/${SUBDIR}/test.mp3" 2>&1 `   
		#echo "$FFMPEG_TEST"
		
		 FFMPEG_TAIL="`echo "$FFMPEG_TEST"|tail  -n 1   `"	
		 #echo $FFMPEG_TAIL
		 FFMPEG_HEAD="`echo "$FFMPEG_TEST"| head -25 `"
		 FFMPEG_YES=`echo "$FFMPEG_TAIL"|grep -o " audio:[1-9][0-9]*kB" `
				if [[ ! -z $FFMPEG_YES ]]
				then
				echo -e "${GREEN}Audio codec supported by ffmpeg${NC} "
				#echo $FFMPEG_YES
				else
				
				ERROR="ERROR: Audio codec not supported by ffmpeg"

						if [[ $DEBUG == 1 ]]
						then

						echo "$FFMPEG_HEAD"
						fi 

				echo -e "${RED}${ERROR}${NC}\\n${FFMPEG_TAIL}"
				echo -e ${ERROR} ${FFMPEG_HEAD}  >> ${DIRECTORY}/${OUTPUT}.err    
				
				
				fi
				
				
				
				
				
				





	      # check the container FORMAT

	      if [[ ! -z ` grep  "^${FORMAT}$" ./config/FORMATS ` ]]
	      then
	      echo -e "FORMAT=${GREEN}$FORMAT${NC}"
	      else
	      echo -e "FORMAT=${YELLOW}$FORMAT${NC}"
	      fi





	      # check the duration of the video	 
		 
		 # duration null try with mplayer 
	      if [[ -z $DURATION ||  $DURATION == 0 ]]
		 then
		 get_duration_mplayer
		 
		 # set DURATION to  DURATION_MPLAYER value  in miliseconds
		 DURATION=`echo "$DURATION_MPLAYER * 1000"|bc `
		 # set DURATION_S to  DURATION_MPLAYER value  in seconds
		 DURATION_S=${DURATION_MPLAYER%.??}
		 else		 
	      DURATION_S=`echo "$DURATION / 1000"|bc`
		 fi
		 
		 
	      if [[  $DURATION_S -lt  $MINIMUM_DURATION ]] 
	      then
	      ERROR="ERROR: Duration of the video is ($DURATION_S secondes).The minimun duration for a video is ($MINIMUM_DURATION secondes)  "
	      echo -e ${RED}${ERROR}${NC}
	      echo $ERROR >> ${DIRECTORY}/${OUTPUT}.err   
	      else
	      echo -e "DURATION=${GREEN}$DURATION_S${NC}"
	      CROPSTART=`echo ${DURATION_S} / 2|bc`
	      fi


	      
	      # Get the general bitrate by calculation
	      
	      BITERATE_CALC=$(echo "scale=10;$FILE_SIZE * 8 / ($DURATION/1000)"|bc)
	      BITERATE_CALC=${BITERATE_CALC%.*}
		 
		 
	      # Check the general bitrate of thevideo
	      
	      if [[ ! -z $BITERATE && ! -z $BITERATE_CALC && $BITERATE == $BITERATE_CALC  ]]
	      then
	      FF_BITERATE=$(echo "$BITERATE / 1000 "|bc)
	      FF_BITERATE=${FF_BITERATE%.*}k
		 
				# check the size
				if [[ $BITERATE -gt $MINIMUM_BITERATE ]]
				then
				echo -e "BITERATE=${GREEN}$BITERATE${NC}\\t$FF_BITERATE"
				else
				WARNING="WARNING: General biterate  of the video is ( $BITERATE / $FF_BITERATE ).The minimun biterate for a $FORMAT video is ($MINIMUM_BITERATE)  "
				echo -e ${PINK}${WARNING}${NC}
				echo $WARNING >> ${DIRECTORY}/${OUTPUT}.err
				fi
		 
		 # BITERATE not detected from mediainfo take the BITERATE_CALC instead
		 elif [[  -z $BITERATE && ! -z $BITERATE_CALC ]]
	      then
		 BITERATE=$BITERATE_CALC
		 FF_BITERATE=$(echo "$BITERATE / 1000 "|bc)
	      FF_BITERATE=${FF_BITERATE%.*}k

				# check the size
				if [[ $BITERATE -gt $MINIMUM_BITERATE ]]
				then
				echo -e "BITERATE=${GREEN}$BITERATE${NC}\\t$FF_BITERATE\\t(calc)"
				else
				WARNING="WARNING: General biterate  of the video is ( $BITERATE / $FF_BITERATE ).The minimun biterate for a $FORMAT video is ($MINIMUM_BITERATE)  "
				echo -e ${PINK}${WARNING}${NC}
				echo $WARNING >> ${DIRECTORY}/${OUTPUT}.err
				fi

	      fi



	      # Chek the number of video stream
	      
	      if [[ $VIDEO_COUNT == 1 ]] 
	      then
	      echo -e "VIDEO_COUNT=${GREEN}$VIDEO_COUNT${NC}"
	      else
	      ERROR="ERROR: 1 video stream is needed (Detection: $VIDEO_COUNT)."
	      echo -e ${RED}${ERROR}${NC}
	      echo $ERROR >> ${DIRECTORY}/${OUTPUT}.err 
	      fi
	      
	      # Chek the number of audio stream	      
	      
	      if [[ $AUDIO_COUNT == 1 ]] 
	      then
	      echo -e "AUDIO_COUNT=${GREEN}$AUDIO_COUNT${NC}"
		 elif [[ $AUDIO_COUNT -gt 1 ]]
		 then
		 WARNING="WARNING: More than 1 audio stream is detected ($AUDIO_COUNT)"
	      echo -e ${PINK}${WARNING}${NC}
	      echo $WARNING >> ${DIRECTORY}/${OUTPUT}.err 
	      else
	      ERROR="ERROR: 1 audio stream is needed (Detection: $AUDIO_COUNT)"
	      echo -e ${RED}${ERROR}${NC}
	      echo $ERROR >> ${DIRECTORY}/${OUTPUT}.err 
	      fi
}

get_video_infos () {

	      VIDEO_INFOS=""
	      
	      FPS=0
		 FPS_MODE=""
	      INTERLACED=""
	      DEINTERLACE=""
	      DELAY=0
	      WIDTH=0
	      HEIGHT=0
	      ASPECT=0
		 VFORMAT=""
		 VCODEC=""
		 
	      
	      VIDEO_INFOS=`mediainfo "--Inform=Video;FPS_MODE=%FrameRate_Mode% VCODEC='%Codec%' VDURATION=%Duration% VBITERATE=%BitRate% FPS=%FrameRate% DELAY=%Delay% ASPECT=%DisplayAspectRatio% INTERLACED=%ScanType% WIDTH=%Width% HEIGHT=%Height%  VFORMAT='%Format%' PAR=%PixelAspectRatio%  " ${INPUT}`
	      #echo $VIDEO_INFOS
	      eval $VIDEO_INFOS
	      echo -e "\\n${cyan}# Video informations${NC}"
	      
	      
	      # Check the FPS (Frame Rate)
	      
		 # standard
	      if [[ ! -z ` grep  "^${FPS}$" ./config/FPS ` ]]
	      then
		 FPS=${FPS%.000}
	      echo -e "FPS=${GREEN}$FPS${NC}"
	      else
	      # round the FPS 
	      FF_FPS=` echo $FPS | awk '{printf("%d\n",$1 + 0.5)}' `
		 
			 # variabre frame rate
			 if [[ $FF_FPS == 24 ||  $FF_FPS == 25 || $FF_FPS == 30 ]]
			 then
			 echo -e "FPS=${GREEN}$FF_FPS${NC} ${FPS_MODE}\\t$FF_FPS"
			 # bad
			 else
				    
				    # try to get it from mplayer
				    get_fps_mplayer
				    FPS=$FPS_MPLAYER
				    # check again
				    
				    # standard
				    if [[ ! -z ` grep  "^${FPS}$" ./config/FPS ` ]]
				    then
				    FPS_MPLAYER=${FPS%.000}
				    echo -e "FPS=${GREEN}$FPS${NC}\\t(from mplayer)"
				    else
				    
				    # round the FPS 

				    FF_FPS=` echo $FPS | awk '{printf("%d\n",$1 + 0.5)}' `
				    
						    # good
						    if [[ $FF_FPS == 24 ||  $FF_FPS == 25 || $FF_FPS == 30 ]]
						    then

						    echo -e "FPS=${GREEN}$FF_FPS${NC} ${FPS_MODE}\\t$FPS\\t(from mplayer)"
						    # bad
						    else
						    echo -e  "FPS=${RED}$FF_FPS ${FPS_MODE}\\t$FPS${NC}"
						    fi
				    fi
				    
				    
			 fi
		  #[[ $FF_FPS == 23  ]] && FF_FPS=24
		  fi	        
	      
		 
		 
		 
		  # check the  VFORMAT

	      if [[ ! -z ` grep  "^${VFORMAT}$" ./config/VFORMATS ` ]]
	      then
	      echo -e "VFORMAT=${GREEN}$VFORMAT${NC}"
	      else
	      echo -e "VFORMAT=${YELLOW}$VFORMAT${NC}"
	      fi
		 		 
		 
		 
	      # check the  VCODEC
		 
		 VCODEC_INFOS=`grep "^${VCODEC}|*" ./config/VCODECS `

	      if [[ ! -z $VCODEC_INFOS ]]
	      then
			   # Checkc the codec compatibility
			   VCODEC_COMP=`echo "$VCODEC_INFOS" | awk -F "|" '{ print $2 }' `

			   VCODEC_TEXT=`echo "$VCODEC_INFOS" | awk -F "|" '{ print $3 }' `
			   
			   case $VCODEC_COMP in
			   1)echo -e  "VCODEC=${GREEN}${VCODEC} ${NC}\\t$VCODEC_TEXT";;
			   2)echo -e  "VCODEC=${YELLOW}${VCODEC} ${NC}\\t$VCODEC_TEXT";;
			   3)echo -e  "VCODEC=${PINK}${VCODEC} ${NC}\\t$VCODEC_TEXT";;
			   4)echo -e  "VCODEC=${RED}${VCODEC} ${NC}\\t$VCODEC_TEXT";;
			   esac
		 
	      
	      else
		 # codec not defined
	      echo -e "VCODEC=${YELLOW}${VCODEC}${NC}\\tCodec undefined!"
	      fi
		 
		 
		 
		 




	      # check the size
	      
	      SIZE="${WIDTH}x${HEIGHT}"
	      SIZE_INFOS=`grep  "^${SIZE}," ./config/SIZES`
	      #echo $SIZE_INFOS
	      if [[ ! -z $SIZE_INFOS  ]]
	      then
	      SIZE_INFOS=`echo $SIZE_INFOS | awk  -F , '{ print $2"  "$3"  "$4  }'`
	      echo -e "SIZE=${GREEN}$SIZE${NC}\\t$SIZE_INFOS"
	      else
	      echo -e "SIZE=${YELLOW}$SIZE${NC}"
	      fi
	      
	      
	      
	     # Check the RATIO  
	      
	      RATIO=`echo "scale=3;${WIDTH}/${HEIGHT} * 100"|bc`
		 RATIO=`echo $RATIO | awk '{printf("%d\n",$1 + 0.5)}'`
		 RATIO=`echo "scale=2;${RATIO}/ 100"|bc`
	      if [[ ! -z ` grep  "${RATIO}" ./config/RATIOS ` ]]
	      then
	      echo -e "RATIO=${GREEN}${RATIO}${NC}"
	      else
	      echo -e "RATIO=${YELLOW}${RATIO}${NC}"
	      fi
	      	     

	      
	      # Check the ASPECT  
	      
	      ASPECT=${ASPECT%?}
	      if [[ ! -z ` grep  "${ASPECT}" ./config/RATIOS ` ]]
	      then
	      echo -e "ASPECT=${GREEN}${ASPECT}${NC}"
	      else
	      echo -e "ASPECT=${YELLOW}${ASPECT}${NC}"
	      fi
	      
	      
	      
	      # Check the PAR (Pixel aspect Ratio)
		 # case NULL
		 if [[  -z $PAR ]]
	      then
		 FF_PAR=0
		 PAR=0		 
	      echo -e "PAR=${GREEN}$PAR${NC}"
		 
	      # standard 1.77 etc
		 elif [[ ! -z ` grep  "^${PAR}$" ./config/PAR ` ]]
	      then
	      echo -e "PAR=${GREEN}$PAR${NC}"
		 FF_PAR=$PAR
	      else
		 
			 # case like 0.006 0.000 1.004 
			 FF_PAR=`echo "$PAR * 100 / 100 "|bc`
			 if [[ $FF_PAR  -gt  0  ]]
			 then 
			 echo -e "PAR=${GREEN}$FF_PAR${NC}\\t$PAR" 
			 
			 # case like 2.4
			 else
			 FF_PAR=0
		 	 echo -e "PAR=${RED}$PAR${NC}"
			 fi  
	      fi
		 
		# Get the aspect ratio or DAR (mplayer)
	      
	      DAR=`mplayer  $INPUT  -frames 1 -identify -quiet -vo null -ao null 2>&1 | grep Movie-Aspect | grep -v undefined`
	      DAR=${DAR#Movie-Aspect is }
	      DAR=${DAR%:1 - prescaling*}
	      # DAR 1.78 -> 1.77
	      if [[ $DAR = "1.78" ]]  
	      then
	      DAR=1.77
	      fi
	      echo "DAR=${DAR}"


	      
	      # Check the VBITERATE
	      
		 # VBITERATE is null, try with mplayer
	      if [[  -z $VBITERATE || $VBITERATE == 0 ]]
	      then
		 get_vbitrate_mplayer
		 VBITERATE=$VBITERATE_MPLAYER
		 fi
		 
		 # check the size of VBITERATE
			 
		 # VBITERATE is good
		 if [[   $VBITERATE -gt $MINIMUM_VBITERATE ]]
		 then
	      FF_VBITERATE=$(echo "$VBITERATE / 1000 "|bc)
	      FF_VBITERATE=${FF_VBITERATE%.*}k
	      echo -e "VBITERATE=${GREEN}$VBITERATE${NC}\\t$FF_VBITERATE"
	
		 # VBITERATE too small
	      else
	      WARNING="WARNING: Video biterate is ($VBITERATE $VFF_BITERATE ).The minimun biterate for a $VFORMAT video is ($MINIMUM_VBITERATE)  "
	      echo -e ${PINK}${WARNING}${NC}
	      echo $WARNING >> ${DIRECTORY}/${OUTPUT}.err
	      fi
	      
	      
	      # check the VDURATION	     
		 
		 # if VDURATION si null take DURATION
		 
		 [[ $VDURATION == 0 || -z $VDURATION ]] &&  VDURATION=$DURATION
		 
		 
	      
	      VDURATION_S=`echo "$VDURATION / 1000"|bc`
	      if [[  $VDURATION_S -lt $MINIMUM_DURATION ]] 
	      then
	      ERROR="Error: Duration of the video is ($VDURATION_S secondes).The minimun duration for a video is ($MINIMUM_DURATION secondes)  "
	      echo -e ${RED}${ERROR}${NC}
	      echo $ERROR >> ${DIRECTORY}/${OUTPUT}.err   
	      else
	      echo -e "VDURATION=${GREEN}$VDURATION_S${NC}"
	      CROPSTART=`echo ${VDURATION_S} / 2|bc`
	      fi

	      
	      # Check for a DELAY 

	      if [[ ! -z $DELAY ]]
	      then
	      echo -e "DELAY=${YELLOW}$DELAY${NC}"
	      fi     
	      
	      
	      
	      # Check interlaced with mediainfo
	      
	      if [[ $INTERLACED == "Interlaced" ]]
	      then
	      DEINTERLACE=" -deinterlace "
	      echo -e "INTERLACED=${YELLOW}$INTERLACED${NC}"
	      fi
	      
	      
}	      

get_extra_infos () {	 
	      # check the BPF of the video (test)
	      
	      echo -e "\\n${cyan}# Extra informations${NC}\\n"
	      
	      NB_FRAMES=$(mediainfo "--Inform=Video;%FrameCount%" ${INPUT})
	      STREAMSIZE=$(mediainfo "--Inform=Video;%StreamSize%" ${INPUT})
	      NB_PIXELS=$(echo "$WIDTH * $HEIGHT"|bc)
	      if [[ ! -z $STREAMSIZE && ! -z $NB_FRAMES ]]
	      then
	      NB_PIXELS=$(echo "$WIDTH * $HEIGHT"|bc)
	      BPF=$(echo "($STREAMSIZE * 1080 / $NB_FRAMES) / $NB_PIXELS  "|bc)
	      echo -e "fredo BPF1=${GREEN}${BPF}${NC}"
	      fi
	      
	      # check the BPF of the video
	      
	      BPF=$(mediainfo "--Inform=Video;%Bits-(Pixel*Frame)%" ${INPUT})
	           
	      if [[ $BPF < $MINIMUM_BPF && ! -z $BPF ]] 
	      then
	      WARNING="WARNING: BPF quality  of the video is ($BPF).The minimun quality is ($MINIMUM_BPF)  "
	      echo -e "${PINK}$WARNING${NC}"
	      echo $WARNING >> ${DIRECTORY}/${OUTPUT}.err
	      else
	      echo  -e "BPF=${GREEN}${BPF}${NC}"
	      fi
	      

	      
	      VBRPP=$(echo "scale=1;$BITERATE / $NB_PIXELS  "|bc)
	      if [[ $VBRPP <  1.5  ]]
	      then
	      WARNING="WARNING: VBRPP quality  of the video is ($VBRPP).The minimun quality is (1)  "
	      echo -e "${PINK}$WARNING${NC}"
	      echo $WARNING >> ${DIRECTORY}/${OUTPUT}.err
	      else
	      echo -e "fredo VBRPP=${GREEN}${VBRPP}${NC}"
	      fi
}

get_audio_infos () {
	      AUDIO_INFOS=""
	      

	      AFORMAT=""
	      ABITERATE=0
	      ABITERATE2=0
	      FF_ABITERATE=0
	      ADURATION=0
	      AR=0
	      CHANNELS=0
	      
	      echo -e "\\n${cyan}# Audio informations${NC}"
	      
	      AUDIO_INFOS=`mediainfo "--Inform=Audio;ACODEC='%Codec%' AR=%SamplingRate% ABITERATE2=%BitRate_Nominal% ADURATION=%Duration% CHANNELS=%Channel(s)% AFORMAT='%Format%' ABITERATE=%BitRate% " ${INPUT}`
	      #echo $AUDIO_INFOS	     
	      eval $AUDIO_INFOS

	      

	      
# 		 # check the  ACODEC
# 
# 	      if [[ ! -z ` grep  "^${ACODEC}$" ./config/ACODECS ` ]]
# 	      then
# 	      echo -e -n "ACODEC=${GREEN}$ACODEC${NC}"
# 	      else
# 	      echo -e -n "ACODEC=${YELLOW}$ACODEC${NC}"
# 	      fi
		 
		 
		 # check the  AFORMAT

	      if [[ ! -z ` grep  "^${AFORMAT}$" ./config/AFORMATS ` ]]
	      then
	      echo -e "AFORMAT=${GREEN}$AFORMAT${NC}"
	      else
	      echo -e "AFORMAT=${YELLOW}$AFORMAT${NC}"
	      fi
		 
		
		
		# check the  ACODEC
		 
		 ACODEC_INFOS=`grep "^${ACODEC}|*" ./config/ACODECS `

	      if [[ ! -z $ACODEC_INFOS ]]
	      then
			   # Checkc the codec compatibility
			   ACODEC_COMP=`echo "$ACODEC_INFOS" | awk -F "|" '{ print $2 }' `
			   ACODEC_TEXT=`echo "$ACODEC_INFOS" | awk -F "|" '{ print $3 }' `
			   
			   case $ACODEC_COMP in
			   1)echo -e  "ACODEC=${GREEN}${ACODEC} ${NC}\\t$ACODEC_TEXT";;
			   2)echo -e  "ACODEC=${YELLOW}${ACODEC} ${NC}\\t$ACODEC_TEXT";;
			   3)echo -e  "ACODEC=${PINK}${ACODEC} ${NC}\\t$ACODEC_TEXT";;
			   4)echo -e  "ACODEC=${RED}${ACODEC} ${NC}\\t$ACODEC_TEXT";;
			   esac
		 
	      
	      else
		 # codec not defined
	      echo -e -n "ACODEC=${YELLOW}${ACODEC}${NC}\\tCodec undefined!"
	      fi
	      
		  # Check the ABITERATE
		  ABITERATE_NOTICE=""
	      
		 
		  # if mediainfo did not detect the auio bitrate -> try to get if from mplayer 
		  if [[  -z $ABITERATE || $ABITERATE == 0 ]]
		  then
		  get_abitrate_mplayer
		  ABITERATE=$ABITERATE_MPLAYER
		  ABITERATE_NOTICE="# detected by mplayer"
		  fi
		  
		 
		  
		  # take the value  and parse it to ffmpeg
		  
		  if [[ $AFORMAT == "PCM" ]]
		  then
		  TMP_ABITERATE=`echo "$ABITERATE / 1000"|bc `
		  PCM[1411]=128000 
		  PCM[1536]=192000
		  FF_ABITERATE=${PCM[TMP_ABITERATE]}
		  
				# if not a pcm standart send ABITERATE as value
				[[ -z $FF_ABITERATE ]] && FF_ABITERATE=$ABITERATE
		  
		  else
		  FF_ABITERATE=`echo "($ABITERATE + 16000 ) / 32000 * 32000" |bc`
		  fi
		  
		  # compare ABITERATE_MPLAYER with ABITERATE2
		  
		  if [[  -z $FF_ABITERATE  ]] 
		  then
		  ABITERATE=0
		  ABITERATE_NOTICE="# not detected by mplayer"
		  elif [[ ! -z $ABITERATE_NOTICE && $FF_ABITERATE != $ABITERATE2 ]]
		  then
		  # just add a notice that the 2 value are not equal
		  ABITERATE_NOTICE="$ABITERATE_NOTICE but! [$FF_ABITERATE != $ABITERATE2]"	 
		  elif [[ ! -z $ABITERATE2  && $FF_ABITERATE != $ABITERATE2 ]]
		  then
		  # just notice that the 2 value are not equal
		  
		  ABITERATE_NOTICE=" [$FF_ABITERATE != $ABITERATE2]"	
		  fi
		  
		  # check if the value of ABITERATE is acceptable
		
		  # ABITERATE is a standar
		  if [[ ! -z ` grep  "^${FF_ABITERATE}$" ./config/ABITRATES ` ]]
		  then
		  echo -e "ABITERATE=${GREEN}$FF_ABITERATE${NC}\\t$ABITERATE\\t$ABITERATE_NOTICE"
		  # too small
		  elif [[ $FF_ABITERATE -gt $MINIMUM_ABITERATE ]]
		  then
		  echo -e "ABITERATE=${YELLOW}$FF_ABITERATE${NC}\\t$ABITERATE\\t$ABITERATE_NOTICE"
		  else
		  WARNING="WARNING: audio biterate is ($FF_ABITERATE $ABITERATE ).The minimun biterate for a $AFORMAT audio is ($MINIMUM_ABITERATE)  "
		  echo -e ${PINK}${WARNING}${NC}
		  echo $WARNING >> ${DIRECTORY}/${OUTPUT}.err
		  fi

	      
	      
	      # check the ADURATION	      
		 
		  # if ADURATION si null take DURATION


		 [[ $ADURATION == 0 || -z $ADURATION ]] &&  ADURATION=$DURATION
	      
	      ADURATION_S=`echo "$ADURATION / 1000"|bc`
		 
	      if [[  $ADURATION_S -gt $MINIMUM_DURATION ]] 
	      then
		 echo -e "ADURATION=${GREEN}$ADURATION_S${NC}"
	      else
		 ERROR="Error: Duration of the audio is ($ADURATION_S secondes).The minimun duration for a audio is ($MINIMUM_DURATION secondes)  "
	      echo -e ${RED}${ERROR}${NC}
	      echo $ERROR >> ${DIRECTORY}/${OUTPUT}.err 
	      fi
	      
	      # Check the number of CHANNELS
	      
	      if [[ ${CHANNELS} == 2 || ${CHANNELS} == 6 ]]
	      then
	      echo -e "CHANNELS=${GREEN}$CHANNELS${NC}"
	      else
	      echo -e "CHANNELS=${YELLOW}$CHANNELS${NC}"
	      fi
	      
	      
	      # Check the AR (Sampling rate)
	      
	      if [[ ${AR} == 48000 || ${AR} == 44100 ]]
	      then
	      echo -e "AR=${GREEN}$AR${NC}"
	      elif [[ ${AR} == 32000 || ${AR} == 22050 ]]
	      then
	      echo -e "AR=${YELLOW}$AR${NC}"
	      else
	      echo -e "AR=${RED}$AR${NC}"
	      fi


	      
	      
	      
}

cropdetection () {

    
		 if [[ $OVERWRITE != 1  ]]
		 then
    
				if [[ -n $1 ]]
				then
				CROPFRAMES_TMP=$1
				CROPSTART_TMP=0
				echo -e "\\n${cyan}# Crop from -ss $CROPSTART_TMP detction on $1 frames${NC}"

				else

				CROPFRAMES_TMP=$CROP_FRAMES_S
				CROPSTART_TMP=$CROPSTART
				echo -e "\\n${cyan}# Crop detction from -ss $CROPSTART_TMP  on $CROP_FRAMES_S frames${NC}"
				
				fi
		 
		 
				# Run mplayer to get somme parameters of the video.
				CROPDETECTION_CMD="mplayer \"$INPUT\" -ss $CROPSTART_TMP -frames $CROPFRAMES_TMP -vf cropdetect -ac dummy -quiet -vo null -ao null > ${DIRECTORY}/${SUBDIR}/${OUTPUT}.crop 2>&1"
				eval $CROPDETECTION_CMD 
				if [[  $DEBUG -eq 1 ]]
				then
				cat "${DIRECTORY}/${SUBDIR}/${OUTPUT}.crop" |tail -n 10
				fi
				
		fi
	      
		# Get the output of -vf cropdetect.

		CROP=`cat ${DIRECTORY}/${SUBDIR}/${OUTPUT}.crop | grep CROP | tail -1`
		CROP=${CROP#* crop=}
		CROP=${CROP%%\).*}

	      
	      if [[ ! -z $CROP ]]
	      then 
				echo "CROP=${CROP}"

				# get crop left
				CROPLEFT=`echo $CROP|awk -F ':' '{print $3 }'`
				echo  "CROPLEFT=$CROPLEFT"

				if [ $CROPLEFT -gt 0 ]
				then
				FF_CROP_WIDTH=" -cropleft $CROPLEFT"
				fi
				
				# get crop right
				CROPRIGHT=`echo $CROP|awk -F ':' '{print  $1 }'`
				CROPRIGHT=`echo "$WIDTH - $CROPRIGHT - $CROPLEFT"|bc`
				echo  "CROPRIGHT=$CROPRIGHT"

				if [ $CROPRIGHT -gt 0 ]
				then
				FF_CROP_WIDTH="$FF_CROP_WIDTH -cropright $CROPRIGHT"
				fi


				# get crop top
				CROPTOP=`echo $CROP|awk -F ':' '{print $4 }'`
				echo  "CROPTOP=$CROPTOP"

				if [ $CROPTOP -gt 0 ]
				then
				FF_CROP_HEIGHT=" -croptop $CROPTOP"
				fi

				# get crop bottom
				CROPBOTTOM=`echo $CROP|awk -F ':' '{print  $2 }'`
				CROPBOTTOM=`echo "$HEIGHT - $CROPBOTTOM - $CROPTOP"|bc`
				echo  "CROPBOTTOM=$CROPBOTTOM"

				if [ $CROPBOTTOM -gt 0 ]
				then
				FF_CROP_HEIGHT="$FF_CROP_HEIGHT -cropbottom $CROPBOTTOM"
				fi
		 
				#  CROP_RATIO = DAR of the video after cropping
				CROP_RATIO=`echo "scale=3;($WIDTH - $CROPLEFT - $CROPRIGHT)/($HEIGHT - $CROPTOP - $CROPBOTTOM)"|bc`
				echo -e "CROP_RATIO=${cyan}$CROP_RATIO${NC}"
				
				
						 

				CROPHEIGHT=`echo "$CROPTOP+$CROPBOTTOM"|bc`
				#echo "CROPHEIGHT=$CROPHEIGHT"
				CROPHEIGHT_AV=`echo "$CROPHEIGHT / 2"|bc`
				
				CROPWIDTH=`echo "$CROPLEFT+$CROPRIGHT"|bc`
				#echo "CROPWIDTH=$CROPWIDTH"
				CROPWIDTH_AV=`echo "$CROPWIDTH / 2"|bc`
				  
	  
				echo -e "CROPWIDTH_AV=${cyan}$CROPWIDTH_AV${NC}"
				echo -e "CROPHEIGHT_AV=${cyan}$CROPHEIGHT_AV${NC}"

				
		# detection failled once, try one more time with CROPSTART = 0		
		elif [[ -z $CROP && $CROPSTART != 0 && $CROPDETECTION_2PASS != 1 ]]	
		then
		CROPSTART=0
		# avoid loop
		CROPDETECTION_2PASS=1
		
		cropdetection $CROP_FRAMES_L		
		
		 # detection failed
	      else
		 ERROR="Crop detection failled!"
		 ERROR=${ERROR}$CROPDETECTION_CMD
		 ERROR=${ERROR}`cat "${DIRECTORY}/${SUBDIR}/${OUTPUT}.crop" |tail -n 10`
		 
	      echo $ERROR >> ${DIRECTORY}/${OUTPUT}.err   
	      echo -e "${RED}${ERROR}${NC}\\n"

	      fi
	      
	     }

resample_audio(){
 file ${DIRECTORY}/${SUBDIR}/${OUTPUT}.wav | grep -qs 'PCM, 8 bit'
 if [ $? = 0 ]; then
    SOX_B="-b -u"
    SOX_W="-w"

 echo "sox: resampling PCM, 8 bi to PCM, 16 bit" 
 
 echo "sox $SOX_B ${DIRECTORY}/${SUBDIR}/${OUTPUT}.wav -r 48000 $SOX_W ${DIRECTORY}/${SUBDIR}/resample.wav resample "
 if sox $SOX_B ${DIRECTORY}/${SUBDIR}/${OUTPUT}.wav -r 48000 $SOX_W ${DIRECTORY}/${SUBDIR}/resample.wav resample  ; then
    mv -f ${DIRECTORY}/${SUBDIR}/resample.wav ${DIRECTORY}/${SUBDIR}/${OUTPUT}.wav
     echo "sox: resampling done" 
 fi
fi
}

resample_video(){
mplayer $INPUT -ass -embeddedfonts -sid 0 -aid 1 -vf eq2=0.9:1:0:1.02 -vo yuv4mpeg:file=${DIRECTORY}/${SUBDIR}/${OUTPUT}.yuv   -noframedrop -ao null -really-quiet < /dev/null & 
}

encode () {
	      INPUT=$1

	      

	      NOTICE=""
	      WARNING=""
	      ERROR=""
	      
	      SS=0
	      
	      PAD=0
	      FF_PAD=""
		 
		 CROPDETECTION_2PASS=0
		 
		 FF_CROP_WIDTH=""
	      FF_CROP_HEIGHT=""
	      CROP=""
	      CROPTOP=0
	      CROPRIGHT=0
	      CROPBOTTOM=0
	      CROPLEFT=0
	      
	      DISTORTION=""
	    

	      
	      
	      
	      
	      DIRECTORY=`dirname $1`
	      
	      SUBDIR=`basename "$INPUT"`
	      SUBDIR=${SUBDIR%%.${EXTENTION}}
	      
	      OUTPUT=` basename $INPUT`
	      OUTPUT=${OUTPUT%%.???}
	      
	      # create the dir
	      if [[ ! -d  "${DIRECTORY}/${SUBDIR}" ]]
	      then
	      mkdir "${DIRECTORY}/${SUBDIR}"
	      fi
	      


     
	      ### General informations 
	    
	      get_general_infos
	      
 	      ### Video informations 
	    
	      get_video_infos	      
	      
	      ### extra informations
	      
	      #get_extra_infos
	      
	      ### Audio Informations
	      
	      get_audio_infos
	      
	      ### crop detection
	      
	      #cropdetection 
	      
		
	      
	      if [[ ! -z $ERROR ]]
	      then
	      mediainfo ${INPUT} >> ${DIRECTORY}/${OUTPUT}.err
	      #mv ${DIRECTORY}/${OUTPUT}.${EXTENTION} ${DIRECTORY}/${OUTPUT}.mrd
	      
	      fi
	      
	
	
	pal-dar133 (){
	
	
	      # resize
	      NEW_HEIGHT=$(echo "$WIDTH / 1.777" | bc )     
	      NEW_HEIGHT=`round2 $NEW_HEIGHT`
	      NEW_WIDTH=`round2 $WIDTH`
	      NEW_SIZE="${NEW_WIDTH}x${NEW_HEIGHT}"
		 echo -e "${cyan}Resize: $SIZE -> $NEW_SIZE${NC}"
	      

		 

		 
				CROP_PRESET=`grep  "^${TRY}1.25|${WIDTH}x${HEIGHT}|1.33|$CROPWIDTH_AV|$CROPHEIGHT_AV|.*" ./config/CROPS `
				echo $CROP_PRESET
				
				
		 
# 				if [[  ! -z $CROP_PRESET ]]
# 				then
				
				# Width
				
				FF_CROP_WIDTH=`echo $CROP_PRESET |awk -F "|" '{ print $7 }'`
				if [[ ! -z $FF_CROP_WIDTH ]]
				then
				
				# change to the preset values
				FF_CROP_WIDTH=`eval echo "$FF_CROP_WIDTH"`
				echo -e "${cyan}Cropping W: $FF_CROP_WIDTH ${NC}\\t(preset)"				
				else
				
				# keep the cropping detected values
				FF_CROP_WIDTH="-cropleft $CROPLEFT -cropright $CROPRIGHT "
				echo -e "${cyan}Cropping W: $FF_CROP_WIDTH ${NC}\\t(crop detection)"
				
				fi
				
				
				# Height
				
				FF_CROP_HEIGHT=`echo $CROP_PRESET |awk -F "|" '{ print $6 }'`
				if [[ ! -z $FF_CROP_HEIGHT ]]
				then
				
			     # change to the preset values
				FF_CROP_HEIGHT=`eval echo "$FF_CROP_HEIGHT"`
				echo -e "${cyan}Cropping H: $FF_CROP_HEIGHT ${NC}\\t(preset)"
				
				else
				
				# change to the standart values
				CUT=`echo " $HEIGHT / 8 "|bc ` 
				CROPTOP=$CUT
				CROPBOTTOM=$CUT
				FF_CROP_HEIGHT="-croptop $CROPTOP -cropbottom $CROPBOTTOM "
				echo -e "${cyan}Cropping H: $FF_CROP_HEIGHT${NC}\\t(standart)"
				
				fi
				
				
				
				# Height
				
				
				
				DISTORTION=`echo $CROP_PRESET |awk -F "|" '{ print $8 }'`
				if [[ ! -z $DISTORTION ]]
				then	
				
				# change to the preset values
				echo -e "${cyan}Distortion: $DISTORTION ${NC}\\t(preset)"
				
				else
				
	               # stantart    
				DISTORTION="/1.066" # PAR 16:15 = 1.0666666
				echo -e "${cyan}Distortion: $DISTORTION${NC}\\t(standart)"				
				
				fi
				
				
	      
	      echo -e "${cyan}Padding: no${NC}"
	
	
	
	}
	
	
	 pal-dar177(){
	 # resize
	      NEW_WIDTH=`echo " $HEIGHT *  1.77 / 1"| bc ` 
	      NEW_WIDTH=`floor2 $NEW_WIDTH`
	      NEW_HEIGHT=`floor2 $HEIGHT`
	      NEW_SIZE="${NEW_WIDTH}x${NEW_HEIGHT}"
		 echo -e "${cyan}Resize: $SIZE -> $NEW_SIZE${NC}"
		 

		 
		 
				CROP_PRESET=`grep  "^${TRY}1.25|${WIDTH}x${HEIGHT}|1.77|$CROPWIDTH_AV|$CROPHEIGHT_AV|.*" ./config/CROPS `
				echo $CROP_PRESET
				
				
		 
# 				if [[  ! -z $CROP_PRESET ]]
# 				then
				
				# Width
				
				FF_CROP_WIDTH=`echo $CROP_PRESET |awk -F "|" '{ print $7 }'`
				if [[ ! -z $FF_CROP_WIDTH ]]
				then
				
				# change to the preset values
				FF_CROP_WIDTH=`eval echo "$FF_CROP_WIDTH"`
				echo -e "${cyan}Cropping W: $FF_CROP_WIDTH ${NC}\\t(preset)"				
				else
				
				# keep the cropping detected values
				FF_CROP_WIDTH="-cropleft $CROPLEFT -cropright $CROPRIGHT "
				echo -e "${cyan}Cropping W: $FF_CROP_WIDTH ${NC}\\t(crop detection)"
				
				fi
				
				
				# Height
				
				FF_CROP_HEIGHT=`echo $CROP_PRESET |awk -F "|" '{ print $6 }'`
				if [[ ! -z $FF_CROP_HEIGHT ]]
				then
				
			     # change to the preset values
				FF_CROP_HEIGHT=`eval echo "$FF_CROP_HEIGHT"`
				echo -e "${cyan}Cropping H: $FF_CROP_HEIGHT ${NC}\\t(preset)"
				
				else
				
				# change to the standart values
# 				CUT=`echo " $HEIGHT / 8 "|bc ` 
				CROPTOP=0
				CROPBOTTOM=0
				FF_CROP_HEIGHT="-croptop 0 -cropbottom 0 "
				echo -e "${cyan}Cropping H: $FF_CROP_HEIGHT${NC}\\t(standart)"
				
				fi
				
				
				
				# Height
				
				
				
				DISTORTION=`echo $CROP_PRESET |awk -F "|" '{ print $8 }'`
				if [[ ! -z $DISTORTION ]]
				then	
				
				# change to the preset values
				echo -e "${cyan}Distortion: $DISTORTION ${NC}\\t(preset)"
				
				else
				
	               # stantart    
				DISTORTION="/1.422 " 
				echo -e "${cyan}Distortion: $DISTORTION${NC}\\t(standart)"				
				
				fi
		 
	 
		 #no  padding
	      echo -e "${cyan}Padding: no${NC}"

	 
	 }
	
	
	
	
	
	
	
	
	
	
	      


		DETECTED_FORMAT=""
		
		
		
		
	      # pal DAR 1.25
		 
		 
		 
		 
	      if [[ ( $RATIO  > 1.23 && $RATIO < 1.27 ) && (-z $DAR || $DAR  == 1.25 ) ]]
	      then
# 		 mv $INPUT /home/fredo/tr-encoder/pal/p/${OUTPUT}.org
#  		 continue
		 
		 DETECTED_FORMAT="1.25"
		 echo -e "\\n${RED}Format: $DETECTED_FORMAT ( pal reencoded !)${NC}"

	      # resize
	      NEW_WIDTH=`floor2 $WIDTH`
	      NEW_HEIGHT=`echo "$WIDTH / 1.777"| bc ` 
	      NEW_HEIGHT=`floor2 $NEW_HEIGHT`
	      NEW_SIZE="${NEW_WIDTH}x${NEW_HEIGHT}"
	      
	      # get a new cropdetection 
	      cropdetection $CROP_FRAMES_L

	      # cut the top and the button
	      CUT=`echo " $HEIGHT  / 8 "|bc ` 



	      # check crop to cut or not the bottom and the top
		 
		 
				# small black border or none (4/3 or DAR 4/3)
				
				if [[  $CROPTOP -lt `echo $HEIGHT / 16 |bc`    &&  $CROPBOTTOM  -lt `echo $HEIGHT / 16 |bc` ]]
				then
				
				echo -e "\\nSmall black border less than `echo $HEIGHT / 16 |bc`" 
				echo    "1/  pal DAR 1.77" 
				echo    "2/  pal DAR 1.33 (if the  crop detection didn't work)"
				

				
				# remove very small black border on the top and bottom (optional)
				
				if [[ $CROPHEIGHT_AV  -lt `echo "$HEIGHT * 0.3 * 2 / 2" |bc` ]]
				then
				FF_CROP_HEIGHT="-croptop $CROPTOP -cropbottom $CROPBOTTOM "
				echo -e "${cyan}Cropping H:\\t$FF_CROP_HEIGHT${NC}"
				else
				CROPTOP=0
				CROPBOTTOM=0
				FF_CROP_HEIGHT="" 
				echo -e "${cyan}Cropping H:\\t no${NC}"
				fi
				
				# remove very small black border on the left and right (optional)
							   
				if [[ $CROPWIDTH_AV  -lt `echo "$WIDTH * 0.03 / 1" |bc` ]]
				then
				FF_CROP_WIDTH="-cropleft $CROPLEFT -cropright $CROPRIGHT "
				echo -e "${cyan}Cropping W:$FF_CROP_WIDTH${NC}"
				else
				CROPLEFT=0
				CROPRIGHT=0
				FF_CROP_WIDTH="" 
				echo -e "${cyan}Cropping W:\\t no${NC}"
				fi
				

				
				
				# distortion 
				DISTORTION="/1.422 "
				echo -e "${cyan}Distortion: $DISTORTION${NC}"				
		 
				# Padding: no
				echo -e "${cyan}Padding: no${NC}"
				
				
				
				
				# medium black boder < 64 88 >

				
				elif [[ $CROPHEIGHT_AV -ge `echo "$HEIGHT * 0.111 / 1" |bc` && $CROPHEIGHT_AV  -le `echo "$HEIGHT * 0.155 / 1"|bc`   ]]
				then
				
				echo -e "\\nMedium black border less than `echo "$HEIGHT * 0.155 / 1"|bc` AND more than `echo "$HEIGHT * 0.111 / 1"|bc` "

				echo    "1/ pal DAR 1.33 with a image 1.77 "
				echo    "2/ pal DAR 1.77 with a image 2.35 "
				
				
				CHOICE=0
				read -t 5 CHOICE
				echo $CHOICE
				
				case $CHOICE in
				1)pal-dar133;;
				2)pal-dar177;;
				*)pal-dar133;;
				esac
				
# 				# remove very small black border on the left and right (optional)
# 							   
# 				if [[ $CROPWIDTH_AV  -lt `echo "$WIDTH * 0.03 / 1" |bc` ]]
# 				then
# 				FF_CROP_WIDTH="-cropleft $CROPLEFT -cropright $CROPRIGHT "
# 				echo -e "${cyan}Cropping W:\\t$FF_CROP_WIDTH${NC}"
# 				else
# 				CROPLEFT=0
# 				CROPRIGHT=0
# 				FF_CROP_WIDTH="" 
# 				echo -e "${cyan}Cropping W:\\t no${NC}"
# 				fi
# 				
# 				
# 				# cut the heigt standart = 72
# 				
# 				CROPTOP=0
# 				CROPBOTTOM=0
# 				FF_CROP_HEIGHT="-croptop $CROPTOP -cropbottom $CROPBOTTOM "
# 
# 				echo -e "${cyan}Cropping H:\\t$FF_CROP_HEIGHT${NC}"
# 				
# 				# distortion 
# 				DISTORTION="/1.422 "
# 				echo -e "${cyan}Distortion: $DISTORTION${NC}"
# 				
# 				# calculate the ratio afer cropping
# 				
# 				RATIO_AFTER_CROPPING=`echo "scale=3;(($WIDTH - $CROPLEFT - $CROPRIGHT)/($HEIGHT - $CROPTOP - $CROPBOTTOM))*${DISTORTION#/}"|bc`
# 				echo $RATIO_AFTER_CROPPING
# 			
# 		 
# 				# Padding: no
# 				echo -e "${cyan}Padding: no${NC}"
				
				
				
				
				
				
				# large black border cinemascope = 136 | 16/9=  |pal DAR 1.77 = 80 -> dont cut just strech the image
				else
				
				echo -e "\\nLarge Black border more than `echo "$HEIGHT * 0.155 / 1"|bc` "
				echo    "1/  pal DAR 1.33"
				echo    "2/  pal DAR 1.77"				
				
				CHOICE=0
				read -t 5 CHOICE
				echo $CHOICE
				
				case $CHOICE in
				1)pal-dar133;;
				2)pal-dar177;;
				*)pal-dar133;;
				esac
		
				
				
# 				# remove very small black border on the left and right (optional)
# 							   
# 				if [[ $CROPWIDTH_AV  -lt `echo "$WIDTH * 0.03 / 1" |bc` ]]
# 				then
# 				FF_CROP_WIDTH="-cropleft $CROPLEFT -cropright $CROPRIGHT "
# 				echo -e "${cyan}Cropping W:\\t$FF_CROP_WIDTH${NC}"
# 				else
# 				CROPLEFT=0
# 				CROPRIGHT=0
# 				FF_CROP_WIDTH="" 
# 				echo -e "${cyan}Cropping W:\\t no${NC}"
# 				fi
# 				
# 				
# 				# cut the heigt standart = 72
# 				
# 				CROPTOP=$CUT
# 				CROPBOTTOM=$CUT
# 				FF_CROP_HEIGHT="-croptop $CUT -cropbottom $CUT "
# 
# 				echo -e "${cyan}Cropping h:\\t$FF_CROP_HEIGHT${NC}"
# 				
# 				
# 				
# 				# distortion 
# 				DISTORTION="/1.066 "
# 				echo -e "${cyan}Distortion: $DISTORTION${NC}"	
# 				
# 				# calculate the ratio afer cropping
# 				
# 				RATIO_AFTER_CROPPING=`echo "scale=3;($WIDTH - $CROPLEFT -$CROPRIGHT)/($HEIGHT - $CROPTOP -$CROPBOTTOM)*${DISTORTION#/}"|bc`
# 				echo $RATIO_AFTER_CROPPING
# 		 
# 				# Padding: no
# 				echo -e "${cyan}Padding: no${NC}"
				fi
				
				
				


	      fi






	      # PAL DAR 1.33
		 
	      if [[ $RATIO == 1.25 && $DAR == 1.33 ]]
	      then
	      # get a  cropdetection 
	      cropdetection $CROP_FRAMES_L
		 
		 DETECTED_FORMAT="PAL DAR 1.33"
		 echo -e "\\n${pink}Format: $DETECTED_FORMAT${NC}"
		
		 pal-dar133
	      fi





	      # 1.25 DAR 1.77
		 
	      if [[ $RATIO == 1.25 && $DAR == 1.77 ]]
	      then
	 
		 # get a  cropdetection
	      cropdetection $CROP_FRAMES_S
		 
		 DETECTED_FORMAT="PAL DAR 1.77"
		 echo -e "\\n${pink}Format: $DETECTED_FORMAT${NC}"

		 pal-dar177	      
	      fi
		 
		 
		 
		 
		 
		 
	      # 1.25 DAR 2.21
		 
		 
		 
		 
		 
	      if [[ $RATIO == 1.25 && $DAR == 2.21 ]]
	      then

		 DETECTED_FORMAT="PAL DAR 2.21"
		 echo -e "\\n${pink}Format: $DETECTED_FORMAT${NC}"
		 
	      # resize
	      NEW_WIDTH=`echo " $HEIGHT * ( $DAR * 100 ) / 100"| bc ` 
	      NEW_WIDTH=`round16 $NEW_WIDTH`
	      NEW_HEIGHT=`floor2 $HEIGHT`
	      NEW_SIZE="${NEW_WIDTH}x${NEW_HEIGHT}"
	      NEW_HEIGHT=`echo "$NEW_WIDTH / 16 * 9" |bc`
	      NEW_HEIGHT=`round2 $NEW_HEIGHT`

	      # padding
	      PAD=`echo "($NEW_HEIGHT - $HEIGHT) / 2"|bc`
	      PAD=`round2 $PAD`
	      FF_PAD=" -padtop $PAD -padbottom $PAD "
	      
	      # the resize need to be change to the original size of the video
	      NEW_HEIGHT=$HEIGHT
	      
	      # Cropping: no
	      CROPLEFT=0              
	      CROPRIGHT=0
	      FF_CROP_WIDTH=""
	      
	      CROPTOP=0
	      CROPBOTTOM=0
	      FF_CROP_HEIGHT=""
	      
	      echo "
	      format: pal DAR 2.21
	      padding: $FF_PAD
	      Cropping: no
	      resize $SIZE ($RATIO) -> ${NEW_WIDTH}x[${HEIGHT} + $PAD + $PAD] $NEW_SIZE] -> (`echo "scale=2;${NEW_WIDTH}/${NEW_HEIGHT}"|bc`)
	      "
	      		 echo -e "${NC}"
	      fi
	      
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
	      # 4/3
	      if [[ ( $RATIO  > 1.30 && $RATIO < 1.36 ) && (-z $DAR || $DAR == 1.33 ) ]]
	      then
		 DETECTED_FORMAT="4/3"
		 echo -e "\\n${cyan}Format: $DETECTED_FORMAT${NC}"
	 
	      # resize
	      NEW_WIDTH=`floor2 $WIDTH`
	      NEW_HEIGHT=`echo "$WIDTH / 1.777"| bc ` 
	      NEW_HEIGHT=`floor2 $NEW_HEIGHT`
	      NEW_SIZE="${NEW_WIDTH}x${NEW_HEIGHT}"
		 echo -e "${cyan}Resize: $SIZE -> $NEW_SIZE${NC}"
		 
 
	      # Cutting the top and the bottom 
		 
		 CUT=`echo "scale=3;( $HEIGHT - $NEW_HEIGHT ) / 2"|bc ` 
 	      CUT=`floor2 $CUT` 
		 CROPTOP=$CUT
	      CROPBOTTOM=$CUT
	      FF_CROP_HEIGHT="-croptop $CUT -cropbottom $CUT "
		 echo -e "${cyan}Cutting: $FF_CROP_HEIGHT${NC}"

	      fi
		 
		 

		 # 4/3 DAR 16/9
		 if [[ ( $RATIO  > 1.30 && $RATIO < 1.36 ) && $DAR == 1.77  ]]
		 then
		 DETECTED_FORMAT="4/3 DAR 16/9"
		 echo -e "\\n${cyan}Format: $DETECTED_FORMAT${NC}"
	 
	      # resize
	      NEW_WIDTH=`floor2 $WIDTH`
	      NEW_HEIGHT=`echo "$WIDTH / 1.777"| bc ` 
	      NEW_HEIGHT=`floor2 $NEW_HEIGHT`
	      NEW_SIZE="${NEW_WIDTH}x${NEW_HEIGHT}"
		 echo "${cyan}Resize $SIZE -> $NEW_SIZE${NC}"
		 
	      # Cropping: no
		 
	      echo -e "${cyan}Cropping: no${NC}"		 
	      CROPLEFT=0              
	      CROPRIGHT=0
	      FF_CROP_WIDTH=""
	      CROPTOP=0
	      CROPBOTTOM=0
	      FF_CROP_HEIGHT=""
		 
	      echo -e "${cyan}Padding: no${NC}"
		
	      
	      fi
		 
		 
	      
	      
	      # 1.77
	      if [[ $RATIO > 1.60 && $RATIO < 1.99 ]] 
	      then
		 DETECTED_FORMAT="16/9"
		 echo -e "\\n${cyan}Format:$DETECTED_FORMAT ${NC}"

		  
	      # round 2
	      NEW_WIDTH=`round2 $WIDTH`
	      NEW_HEIGHT=`round2 $HEIGHT`
	      NEW_SIZE="${NEW_WIDTH}x${NEW_HEIGHT}"
		 echo -e "${cyan}Round: $SIZE -> $NEW_SIZE ${NC}"
		 
		 
		 
				# cropping
		 
		 
				# normal (no detection)
				if [[ $CROPDETECTION  == 1 ]]
				then
				
				# Cropping H: no
				echo -e "${cyan}Cropping W: no${NC}"
				CROPLEFT=0              
				CROPRIGHT=0
				FF_CROP_WIDTH=""
				
				# Cropping H: no
				echo -e "${cyan}Cropping H: no${NC}"
				CROPTOP=0
				CROPBOTTOM=0
				FF_CROP_HEIGHT=""
				
				else 
				
						# make a crop detection 
						cropdetection $CROP_FRAMES_S
						
						# detection H (level detection 2)

						if [[ $CROPDETECTION  -gt 1 && $CROPHEIGHT_AV  -lt `echo "$HEIGHT * 0.03 * 2 / 2" |bc` ]]
						then
						FF_CROP_HEIGHT="-croptop $CROPTOP -cropbottom $CROPBOTTOM "
						echo -e "${cyan}Cropping H:$FF_CROP_HEIGHT${NC}"
						else
						CROPTOP=0
						CROPBOTTOM=0
						FF_CROP_HEIGHT="" 
						echo -e "${cyan}Cropping H: no${NC}"
						fi

		  
				
						# detection W (level detection 2 and 3)
						   
						if [[  $CROPDETECTION  -gt 2 && $CROPWIDTH_AV  -lt `echo "$WIDTH * 0.03 * 2 / 2" |bc` ]]
						then
						FF_CROP_WIDTH="-cropleft $CROPLEFT -cropright $CROPRIGHT "
						echo -e "${cyan}Cropping W:$FF_CROP_WIDTH${NC}"
						else
						CROPLEFT=0
						CROPRIGHT=0
						FF_CROP_WIDTH="" 
						echo -e "${cyan}Cropping W: no${NC}"
						fi

							
			   fi

				
				
		# Padding: no
		echo -e "${cyan}Padding: no${NC}"

		fi				
				


	      # 2.35
	      if [[ $RATIO >  1.99 && $RATIO < 2.51 ]] 
	      then
		 DETECTED_FORMAT="2.35"
		 echo -e "\\n${cyan}Format: $DETECTED_FORMAT${NC}"
	      
	      # resize
		 
	      NEW_WIDTH=`round2 $WIDTH`
	      NEW_HEIGHT=`echo  "scale=3;$WIDTH / 1.777" |bc`
	      NEW_HEIGHT=`round2 $NEW_HEIGHT`
	      NEW_SIZE="${NEW_WIDTH}x${NEW_HEIGHT}"
		 echo -e "${cyan}Round: $SIZE -> $NEW_SIZE${NC}"
	      
	      # padding
		 
		 PAD=`echo "scale=3;($NEW_HEIGHT - $HEIGHT) / 2"|bc`
	      PAD=`round2 $PAD`
	      FF_PAD=" -padtop $PAD -padbottom $PAD "
		 echo -e "${cyan}Padding: $FF_PAD${NC}"
		  
		 # the padding create a distortion
		 
# 		 DISTORTION=`echo "scale=3; ($PAD * 2 )/ $HEIGHT 	 " | bc`
# 		 DISTORTION=" * 1$DISTORTION"
# 		 echo -e "${cyan}Distortion: $DISTORTION${NC}"
# 		 DISTORTION="* 1"
		 
# 	      # the resize need to be change to the original size of the video
# 	      #NEW_HEIGHT=$HEIGHT

	      # Cropping: no
	      echo -e "${cyan}Cropping: no${NC}"		 
	      CROPLEFT=0              
	      CROPRIGHT=0
	      FF_CROP_WIDTH=""
	      CROPTOP=0
	      CROPBOTTOM=0
	      FF_CROP_HEIGHT=""
	      

	      echo -e "${cyan}resize $SIZE ($RATIO) -> $NEW_SIZE [ ${HEIGHT} + $PAD + $PAD ] -> (`echo "scale=2;${NEW_WIDTH}/ ( ${HEIGHT} + $PAD + $PAD )"|bc`)${NC}"
	      
	      fi
	      
	      
	      

	    
		if [[ -z $DETECTED_FORMAT ]] 
		then
		ERROR="ERROR: format ratio not detected $1 !"
		echo -e "\\n${RED}${ERROR}${NC}\\n"
		echo $ERROR >> ${DIRECTORY}/${OUTPUT}.err
# 		
# 				if [[ -d $1 ]]
# 				then
# 				continue
# 				else
# 				exit
# 				fi 	    
		fi
	    
	    
	    ### create the logo
	    
	    
	    
	    LOGO_RESIZED=${DIRECTORY}/${SUBDIR}/${OUTPUT}.png  
	    LOGO="/home/fredo/watermark.png"
	    
	    echo -e "\\n${cyan}# Logo informations${NC}\\n"

	    # get the logo size
	    LOGO_W=$(identify -format %w $LOGO )
	    LOGO_H=$(identify -format %h $LOGO ) 
	    
	    # find the new size for the logo exemple 10% of the new size 
	    
	    LOGO_RESIZED_W=$(echo "$NEW_WIDTH * 10 / 100 "|bc)
	    LOGO_RATIO=$(echo "scale=2;$LOGO_W / $LOGO_RESIZED_W" |bc) 
	    LOGO_RESIZED_H=$(echo "$LOGO_H / $LOGO_RATIO "|bc)
	    echo "Resize the logo to 10%, base on the new With ($NEW_WIDTH): $NEW_WIDTH ${LOGO_W}x${LOGO_H} -> ${LOGO_RESIZED_W}x${LOGO_RESIZED_H}" 
	  
	    # if the video is anamorphe -> the logo need a distortion to fit
	    
	    if [[ ! -z $DISTORTION  ]]
	    then
	    LOGO_RESIZED_W=$(echo "$LOGO_RESIZED_W  $DISTORTION "|bc)
	    echo "Distortion $DISTORTION :${LOGO_W}x${LOGO_H} -> ${LOGO_RESIZED_W}x${LOGO_RESIZED_H}" 
	    fi
	    
	    # create the resized logo
	    
	    convert $LOGO -resize ${LOGO_RESIZED_W}x${LOGO_RESIZED_H}\! -depth 8 $LOGO_RESIZED 
	    
	    # get the exact size of the resized logo (imagemagick do not respect the exactly thr -resize parameter)
	    LOGO_RESIZED_W=$(identify -format %w $LOGO_RESIZED )
	    LOGO_RESIZED_H=$(identify -format %h $LOGO_RESIZED )

	    echo "Resize ${LOGO_W}x${LOGO_H} -> ${LOGO_RESIZED_W}x${LOGO_RESIZED_H}" 

	    
	        
	    
	    
	    
	    
	    
	    
	    
	    
	    
	    
	    ### find the position of the logo
	    
	    
	    
	    
	    
		# if padding -> new_size = old size + padding
		
		if [[ $PAD -ne 0 ]]
		then
		echo "padding"
		# padding: the position of the logo  is base on the original size video (the logo c'ant be on the paddind area)
		LOGO_X=$(echo "(($WIDTH * 10) / 100) "|bc)
		LOGO_Y=$(echo "scale=3;(($HEIGHT * (30 - ($HEIGHT/ $PAD) )) / 100)  "|bc)
		LOGO_Y=${LOGO_Y%.???}
		else
		echo "croping left $CROPLEFT | top $CROPTOP"
		# no padding 
		LOGO_X=$(echo "(($NEW_WIDTH * 10) / 100) + $CROPLEFT"|bc)
		LOGO_Y=$(echo "(($NEW_HEIGHT * 30) / 100) + $CROPTOP"|bc)

		fi
		echo  x = $LOGO_X Y = $LOGO_Y
	    
	    

	    # if the video is anamorphe -> the position need a ajustment base on the distortion
	    if [[ ! -z $DISTORTION  ]]
	    then
	    LOGO_X=$(echo "$LOGO_X  $DISTORTION "|bc)
	    fi
	    
	    VHOOK=" -vhook \"/usr/local/lib/vhook/pip.so -f  ${DIRECTORY}/${SUBDIR}/${OUTPUT}.png -x $LOGO_X -y $LOGO_Y  -w $LOGO_RESIZED_W -h $LOGO_RESIZED_H  -m 1  -t 000000 -s $(echo "$SS  * $FPS "|bc) -e $(echo "($SS + 15) * $FPS "|bc) \" "
		  
	   #echo $VHOOK
	      
	   FF_WIDTH=320
	   FF_HEIGHT=180
	   
	   if [[ $PAD != 0 ]]
	   then
	   FF_HEIGHT=`echo "$FF_WIDTH / $RATIO"|bc`
	   FF_HEIGHT=`round2 $FF_HEIGHT `
	   PAD=`echo "scale=3;(($FF_WIDTH / 1.777 ) - ($FF_WIDTH / $RATIO )) / 2"|bc`
	   PAD=`round2 $PAD`
	   FF_PAD=" -padtop $PAD -padbottom $PAD "
	   fi   
	      
	      

	      
	      
	  ### transcode the video
		COMMAND=""
		COMMAND_DISPLAY=""
		
	  	case "$OUTPUT_FORMAT" in
		jpeg)	  

		COMMAND="ffmpeg $DEINTERLACE -i ${INPUT} -sameq $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT} -r 24   $VHOOK -an -ss $(echo "$SS + 10 "|bc)  -vframes 1 -y ${DIRECTORY}/${OUTPUT}.jpg;"
	     #COMMAND="${COMMAND}display  ${DIRECTORY}/${OUTPUT}.jpg & "
		;;
		montage)	
		
		FF_FPS=`scale=2;echo  "9\${DURATION_S}"|bc`
		FF_FPS="0.0$FF_FPS"
		COMMAND="ffmpeg $DEINTERLACE -i ${INPUT} -sameq $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT} -r $FF_FPS  $VHOOK -an -ss $(echo "$SS + 2 "|bc)  -vframes 9 -y ${DIRECTORY}/${OUTPUT}_%d.jpg;"
		COMMAND="${COMMAND}montage  ${DIRECTORY}/${OUTPUT}_[0-9].jpg -geometry 160x90+1+1 ${DIRECTORY}/${OUTPUT}_montage.png;"
	     COMMAND_DISPLAY="display  ${DIRECTORY}/${OUTPUT}_montage.png & "
		
		;;
		sample)
		# transform to pcm
		COMMAND="mplayer -ao pcm:file=${DIRECTORY}/$SUBDIR/${OUTPUT}.wav -vc null -vo dummy   ${INPUT} > /dev/null;"
		# resample 8bit to 16 (sox)
		COMMAND="${COMMAND}resample_audio;"
				COMMAND="${COMMAND}resample_video;"
		# make a sample audio
		COMMAND="${COMMAND}ffmpeg  -i ${DIRECTORY}/$SUBDIR/${OUTPUT}.wav -ss  $(echo "$SS  + 10 "|bc) -t 20 -r 24 -ar 44100 -ab 128000 -ac 2  -y ${DIRECTORY}/${SUBDIR}/${OUTPUT}.mp3;"
		# make a sample video
		COMMAND="${COMMAND}ffmpeg -an $DEINTERLACE -i ${INPUT} -sameq $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT} -r 24  $VHOOK  -ss $(echo "$SS  + 10 "|bc) -t 20   -y ${DIRECTORY}/${SUBDIR}/${OUTPUT}.flv;"
		# remux
		COMMAND="${COMMAND}ffmpeg  -i ${DIRECTORY}/$SUBDIR/${OUTPUT}.flv -i ${DIRECTORY}/$SUBDIR/${OUTPUT}.mp3 -acodec copy -vcodec copy  -y ${DIRECTORY}/${SUBDIR}/${OUTPUT}_1.flv;"
		COMMAND_DISPLAY="${DIRECTORY}/${SUBDIR}/${OUTPUT}_1.flv"
		;;
		
		normal) 
		
		COMMAND="ffmpeg $DEINTERLACE -i ${INPUT}  $FF_CROP_WIDTH $FF_CROP_HEIGHT $FF_PAD -s ${FF_WIDTH}x${FF_HEIGHT} -r 24  -b 700000 -aspect 1.77  $VHOOK  -ss $SS  -ar 48000 -ab 128000 -ac 2 -y ${DIRECTORY}/${SUBDIR}/${OUTPUT}.mp4"
		
		;;
		esac

	      
	      echo $COMMAND >> ${DIRECTORY}/${SUBDIR}/${OUTPUT}.txt
	      #COMMAND="ffmpeg -i ${INPUT} -sameq $FF_PAD -s ${NEW_WIDTH}x${NEW_HEIGHT} -an -ss 10 -t 10 -y ${OUTPUT}.mp4"
	      echo -e "\\n$COMMAND\\n" 

	      if [[ $DEBUG -eq 1 ]]
	      then
	      [[ $OVERWRITE != 1 ]] && eval $COMMAND 
	      else
	      [[ $OVERWRITE != 1 ]] && eval $COMMAND > /tmp/mencoder.log 2>&1
	      fi
		 
		 # Display

		  if [[ $DISPLAY == 1 ]]
		  then
		  echo "$COMMAND_DISPLAY"
		  fi
		 
		 
		 # promt for removing the file
		 
		 REMOVE_FILE_CONFIRM="n"
		 echo "Do you whant to remove this video? [y/N]"

		 read -t 30 REMOVE_FILE_CONFIRM

		  if [[ $REMOVE_FILE_CONFIRM = 'y' ]] || [[ $REMOVE_FILE_CONFIRM = 'Y' ]]
		  then
		  rm ${DIRECTORY}/${OUTPUT}.${EXTENTION}
		  echo "The video ${DIRECTORY}/${OUTPUT}.${EXTENTION} is remove"
		  fi
		 
		 
    
    }
  
  
  #############################  



# $1 is a file
if [[ -f "${1}" ]] ; then

encode $1 


# $1 is a folder
else

    DIRECTORY=$1

    
    for VIDEO  in `find ${DIRECTORY}  -name "*.${EXTENTION}"`
    do

    SUBDIR=`basename "$VIDEO"`
    SUBDIR=${SUBDIR%%.${EXTENTION}}


      if [[ ! -d ${DIRECTORY}/${SUBDIR} || $OVERWRITE  !=  0 ]]
      then
      encode $VIDEO 
      fi
    done
fi
exit 0

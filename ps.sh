#!/bin/bash

echo -e "PID\tTTY\tSTAT\tTIME\tCOMMAND"

ps=`ls -1d /proc/*/ | grep -e '[0-9]\{1,\}' | sort -t'/' -n -k3`

for dir in ${ps}
do

	if [ -d ${dir} ]; then
		pid=`cat ${dir}stat | awk '{print $1}'`
		statbsd=`cat ${dir}stat | awk '{print $3}'`
		sessionid=`cat ${dir}stat | awk '{print $6}'`

		ttynr=`cat ${dir}stat | awk '{print $7}'`
		ttyname="?"
		if [[ ${ttynr} > 0 ]]; then
			ttyname="?"
			if [[ ${ttynr} < 65535 ]]; then
				major=$(( ($ttynr & 0xff00) >> 8 ))
				minor=$(( $ttynr & 0xff ))
				if [ -f /sys/dev/char/${major}:${minor}/uevent ]; then
					ttyname=`cat /sys/dev/char/${major}:${minor}/uevent | grep 'DEVNAME' | sed 's/DEVNAME=//'`
				else
					#Костыли
					ttyname="`cat /proc/devices | grep ${major} | awk '{print $2}'`/${minor}"
				fi
			fi
		fi

		nicestat=`cat ${dir}stat | awk '{print $19}'`
		if [[ ${nicestat} == -20 ]]; then
			# high priority
			statbsd="${statbsd}<"
		elif [[ ${nicestat} == 19 ]]; then
			# low priority
			statbsd="${statbsd}N"
		fi

		#has pages locked into memory
		vmlck=`cat ${dir}status | grep VmLck | awk '{print $2}'`
		if [[ ${vmlck} > 0 ]]; then
			statbsd="${statbsd}L"
		fi

		if [[ ${sessionid} == ${pid} ]]; then
			statbsd="${statbsd}s"
		fi

		pthreads=`cat ${dir}stat | awk '{print $20}'`
		if [[ ${pthreads} > 1 ]]; then
			statbsd="${statbsd}l"
		fi

		#Foreground process
		foreground=`cat ${dir}stat | awk '{print $8}'`
		if [[ ${foreground} == ${pid} ]]; then
			statbsd="${statbsd}+"
		fi

		if [ -f ${dir}cmdline ]; then
			command=`tail -n 1 ${dir}cmdline | tr -d '\0'`
		else
			command=""
		fi

		if [[ ${#command} == 0 ]]; then
			command=`cat ${dir}stat | awk '{print $2}' | sed 's/(/\[/; s/)/\]/'`
		fi

		# TIME
		usermodetime=`cat ${dir}stat | awk '{print $14}'`
		kernelmodetime=`cat ${dir}stat | awk '{print $15}'`
		bsdutiltime=$(( (${usermodetime} + ${kernelmodetime})/100 ))
		bsdutiltimeminutes=$(( ${bsdutiltime} / 60 ))
		bsdutiltimeseconds=$(( ${bsdutiltime} % 60 ))

		echo -e "${pid}\t${ttyname}\t${statbsd}\t${bsdutiltimeminutes}:${bsdutiltimeseconds}\t${command}"
	fi

done

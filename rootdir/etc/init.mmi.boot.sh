#!/system/bin/sh

function advance_system_time()
{
	min_utc=$1
	current_utc=`date +%s`

	# Is current date less then minumun acceptable date
	if [ $current_utc -lt $min_utc ]
	then
		day_s=$(( 24 * 60 * 60 ))
		# Average duration of month in seconds
		month_s=$(( $day_s * 30 + $day_s * 4375 / 10000 ))
		year_s=$(( $month_s * 12 ))

		# Convert UTC time to format accepted by date
		year=$(( $min_utc / $year_s + 1970 ))
		yr=$(( $min_utc % $year_s ))
		month=$(( $yr / $month_s + 1))
		mr=$(( $yr % $month_s ))
		if [ $month -le 9 ]
		then
			month="0$month"
		fi
		day=$(( $mr / $day_s + 1))
		if [ $day -le 9 ]
		then
			day="0$day"
		fi

		echo "set system time to $year$month$day.0"
		date -s "$year$month$day.0"
	fi
}

# Advance system time to SW build date as early as possible
# in the script to avoid race condition with time daemon
build_date_utc=`getprop ro.build.date.utc`
if [ ! -z $build_date_utc ]; then
	advance_system_time $build_date_utc
fi

# We take this from cpuinfo because hex "letters" are lowercase there
set -A cinfo `cat /proc/cpuinfo | /system/bin/grep Revision`
hw=${cinfo[2]#?}

# Now "cook" the value so it can be matched against devtree names
m2=${hw%?}
minor2=${hw#$m2}
m1=${m2%?}
minor1=${m2#$m1}
if [ "$minor2" == "0" ]; then
	minor2=""
	if [ "$minor1" == "0" ]; then
		minor1=""
	fi
fi
setprop ro.hw.revision p${hw%??}$minor1$minor2
unset hw cinfo m1 m2 minor1 minor2

# Let kernel know our image version/variant/crm_version
image_version="10:"
image_version+=`getprop ro.build.id`
image_version+=":"
image_version+=`getprop ro.build.version.incremental`
image_variant=`getprop ro.product.name`
image_variant+="-"
image_variant+=`getprop ro.build.type`
oem_version=`getprop ro.build.version.codename`
echo 10 > /sys/devices/soc0/select_image
echo $image_version > /sys/devices/soc0/image_version
echo $image_variant > /sys/devices/soc0/image_variant
echo $oem_version > /sys/devices/soc0/image_crm_version

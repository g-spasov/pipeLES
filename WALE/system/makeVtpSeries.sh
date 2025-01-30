frequency=$1
frequency=$(printf '%.6f' $frequency)

for dummy in $(ls *0001*); do
	string=$(echo $dummy | tr "_" "\n")
	name=$(echo $string | awk '{print $1}')

	echo "{" > $name.vtp.series
  	echo "  \"file-series-version\" : \"1.0\"," >> $name.vtp.series
  	echo "  \"files\" : [" >> $name.vtp.series
	
	timeValue=0.0

	for file in ${name}_*; do
		timeValue=$(echo print "$timeValue+$frequency" | python2)
		echo "    { \"name\" : \"$file\", \"time\" : $timeValue }," >> $name.vtp.series
	done

	echo "  ]" >> $name.vtp.series  
	echo "}" >> $name.vtp.series
done

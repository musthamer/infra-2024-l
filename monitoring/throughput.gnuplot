set datafile separator ','
set terminal png size 1200,700
set output 'throughput.png'
set title 'Request Throughput Over Time'
set xlabel 'Unix Time'
set ylabel 'Response Time (s)'
set key outside
set xdata time
set timefmt '%s'
set format x '%H:%M:%S'

plot 'requests.csv' using 1:4 with lines lc rgb '#9467bd' title 'ships endpoint response time'

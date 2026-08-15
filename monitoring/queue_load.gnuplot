set datafile separator ','
set terminal png size 1200,700
set output 'queue_load.png'
set title 'Queue Size vs Processing Latency'
set xlabel 'Submitted Jobs'
set ylabel 'Average Completion Time (s)'
set key outside

plot 'queue_load.csv' using 1:7 with linespoints pt 7 lc rgb '#2ca02c' title 'avg completion latency'

set datafile separator ','
set terminal png size 1200,700
set output 'login_load.png'
set title 'Concurrent Users vs Response Time'
set xlabel 'Concurrency'
set ylabel 'Average Response Time (s)'
set key outside

stats 'login_load.csv' using 1:4 name 'A' nooutput

plot 'login_load.csv' using 1:4 with points pt 7 lc rgb '#1f77b4' title 'requests', \
     '' using 1:4 smooth unique with lines lc rgb '#ff7f0e' title 'avg trend'

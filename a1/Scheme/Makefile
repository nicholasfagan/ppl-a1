N=476117
solutions/$(N).sol:
	time ./rush_hour_solve.ss $(N) | tee solutions/$(N).sol
test: solutions/$(N).sol
	../Python/rush_hour_check.py solutions/$(N).sol


N=476117
solutions/$(N).sol:
	time swipl -qt main rush_hour_solve.pl $(N) | tee solutions/$(N).sol
test: solutions/$(N).sol
	../Python/rush_hour_check.py solutions/$(N).sol

